//
//  NativePusher.swift
//  PusherSwift
//
//  Created by James Fisher on 09/06/2016.
//
//

import Foundation

#if os(iOS) || os(OSX)

/**
    An interface to Pusher's native push notification service.
    The service is a pub-sub system for push notifications.
    Notifications are published to "interests".
    Clients (such as this app instance) subscribe to those interests.

    A per-app instance NativePusher is available via an instance of Pusher.
*/
@objcMembers
@objc open class NativePusher: NSObject {
    private static let PLATFORM_TYPE = "apns"
    private let CLIENT_API_V1_ENDPOINT = "https://nativepushclient-cluster1.pusher.com/client_api/v1"
    private let LIBRARY_NAME_AND_VERSION = "pusher-websocket-swift " + VERSION

    public var URLSession = Foundation.URLSession.shared
    private var failedRequestAttempts: Int = 0
    private let maxFailedRequestAttempts: Int = 6

    internal weak var delegate: PusherDelegate? = nil

    internal var requestQueue = TaskQueue()

    /**
        Identifies a Pusher app, which should have push notifications enabled
        and a certificate added for the push notifications to work
    */
    private var pusherAppKey: String? = nil

    /**
        The id issued to this app instance by Pusher, which is received upon
        registrations. It's used to identify a client when subscribe /
        unsubscribe requests are made
    */
    internal var clientId: String? = nil

    /**
        Normal clients should access the instance via Pusher.nativePusher()
    */
    internal override init() {}

    /**
        Sets the pusherAppKey property and then attempts to flush
        the outbox of any pending requests

        - parameter pusherAppKey: The Pusher app key
    */
    open func setPusherAppKey(pusherAppKey: String) {
        self.pusherAppKey = pusherAppKey

        if self.clientId != nil {
            requestQueue.run()
        }
    }

    /**
        Makes device token presentable to server

        - parameter deviceToken: the deviceToken received when registering
                                 to receive push notifications, as Data

        - returns: the deviceToken formatted as a String
    */
    private func deviceTokenToString(deviceToken: Data) -> String {
        var deviceTokenString: String = ""
        for i in 0..<deviceToken.count {
            deviceTokenString += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
        return deviceTokenString
    }

    /**
        Registers (asynchronously) this app instance with Pusher for push notifications.
        This must be done before we can subscribe to interests.

        - parameter deviceToken: the deviceToken received when registering
                                 to receive push notifications, as Data
    */
    open func register(deviceToken: Data) {
        var request = URLRequest(url: URL(string: CLIENT_API_V1_ENDPOINT + "/clients")!)
        request.httpMethod = "POST"
        let deviceTokenString = deviceTokenToString(deviceToken: deviceToken)

        let params: [String: Any] = [
            "app_key": pusherAppKey!,
            "platform_type": NativePusher.PLATFORM_TYPE,
            "token": deviceTokenString
        ]

        try! request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(LIBRARY_NAME_AND_VERSION, forHTTPHeaderField: "X-Pusher-Library" )

        let task = URLSession.dataTask(with: request, completionHandler: { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
                   (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                        /**
                            We expect to get a JSON response in the form:

                            {
                                "id": string,
                                "pusher_app_key": string,
                                "platform_type": either "apns" or "gcm",
                                "token": string
                            }

                            Currently, we only care about the "id" value, which is our new client id.
                            We store our id so that we can use it to subscribe/unsubscribe.
                        */
                        if let json = try! JSONSerialization.jsonObject(with: data!, options: [])
                                      as? [String: AnyObject] {
                            if let clientIdJson = json["id"] {
                                if let clientId = clientIdJson as? String {
                                    self.clientId = clientId
                                    self.delegate?.registeredForPushNotifications?(clientId: clientId)
                                    self.delegate?.debugLog?(message: "Successfully registered for push notifications and got clientId: \(clientId)")
                                    self.requestQueue.run()
                                } else {
                                    self.delegate?.debugLog?(message: "Value at \"id\" key in JSON response was not a string: \(json)")
                                }
                            } else {
                                self.delegate?.debugLog?(message: "No \"id\" key in JSON response: \(json)")
                            }
                        } else {
                            self.delegate?.debugLog?(message: "Could not parse body as JSON object: \(String(describing: data))")
                        }
            } else {
                if data != nil && response != nil {
                    let responseBody = String(data: data!, encoding: .utf8)
                    self.delegate?.failedToRegisterForPushNotifications?(response: response!, responseBody: responseBody)
                    self.delegate?.debugLog?(message: "Bad HTTP response: \(response!) with body: \(String(describing: responseBody))")
                }
            }
        })

        task.resume()
    }

    /**
        Subscribe to an interest with Pusher's Push Notification Service

        - parameter interestName: the name of the interest you want to subscribe to
    */
    open func subscribe(interestName: String) {
        addSubscriptionChangeToTaskQueue(interestName: interestName, change: .subscribe)
    }

    /**
        Unsubscribe from an interest with Pusher's Push Notification Service

        - parameter interestName: the name of the interest you want to unsubscribe
                                  from
    */
    open func unsubscribe(interestName: String) {
        addSubscriptionChangeToTaskQueue(interestName: interestName, change: .unsubscribe)
    }

    /**
        Adds subscribe / unsubscribe tasts to task queue

        - parameter interestName: the name of the interest you want to interact with
        - parameter change:       specifies whether the change is to subscribe or
                                  unsubscribe

    */
    private func addSubscriptionChangeToTaskQueue(interestName: String, change: SubscriptionChange) {
        requestQueue.tasks += { _, next in
            self.modifySubscription(
                interest: interestName,
                change: change,
                successCallback: next
            )
        }

        requestQueue.run()
    }

    /**
        Makes either a POST or DELETE request for a given interest

        - parameter pusherAppKey: The app key for the Pusher app
        - parameter clientId:     The clientId returned by Pusher's server
        - parameter interest:     The name of the interest to be subscribed to /
                                  unsunscribed from
        - parameter change:       Whether to subscribe or unsubscribe
        - parameter callback:     Callback to be called upon success
    */
    private func modifySubscription(interest: String, change: SubscriptionChange, successCallback: @escaping (Any?) -> Void) {
        guard pusherAppKey != nil && clientId != nil else {
            self.delegate?.debugLog?(message: "pusherAppKey \(String(describing: pusherAppKey)) or clientId \(String(describing: clientId)) not set - waiting for both to be set")
            self.requestQueue.pauseAndResetCurrentTask()
            return
        }

        self.delegate?.debugLog?(message: "Attempt number: \(self.failedRequestAttempts + 1) of \(maxFailedRequestAttempts)")

        let url = "\(CLIENT_API_V1_ENDPOINT)/clients/\(clientId!)/interests/\(interest)"
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = change.httpMethod()

        let params: [String: Any] = ["app_key": pusherAppKey!]
        try! request.httpBody = JSONSerialization.data(withJSONObject: params, options: [])

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(LIBRARY_NAME_AND_VERSION, forHTTPHeaderField: "X-Pusher-Library")

        let task = URLSession.dataTask(
            with: request,
            completionHandler: { data, response, error in
                guard let httpResponse = response as? HTTPURLResponse,
                          (200 <= httpResponse.statusCode && httpResponse.statusCode < 300) &&
                          error == nil
                else {
                    self.failedRequestAttempts += 1

                    if error != nil {
                        self.delegate?.debugLog?(message: "Error when trying to modify subscription to interest: \(String(describing: error?.localizedDescription))")
                    } else if data != nil && response != nil {
                        let responseBody = String(data: data!, encoding: .utf8)
                        self.delegate?.debugLog?(message: "Bad response from server: \(response!) with body: \(String(describing: responseBody))")
                    } else {
                        self.delegate?.debugLog?(message: "Bad response from server when trying to modify subscription to interest: \(interest)")
                    }

                    if self.failedRequestAttempts >= self.maxFailedRequestAttempts {
                        self.delegate?.debugLog?(message: "Max number of failed native service requests reached")

                        self.requestQueue.paused = true
                    } else {
                        self.delegate?.debugLog?(message: "Retrying subscription modification request for interest: \(interest)")
                        self.requestQueue.retry(Double(self.failedRequestAttempts * self.failedRequestAttempts))
                    }

                    return
                }

                switch change {
                case .subscribe:
                    self.delegate?.subscribedToInterest?(name: interest)
                case .unsubscribe:
                    self.delegate?.unsubscribedFromInterest?(name: interest)
                }

                self.delegate?.debugLog?(message: "Success making \(change.stringValue) to \(interest)")

                self.failedRequestAttempts = 0
                successCallback(nil)
            }
        )

        task.resume()
    }
}

internal enum SubscriptionChange {
    case subscribe
    case unsubscribe

    internal func stringValue() -> String {
        switch self {
        case .subscribe:
            return "subscribe"
        case .unsubscribe:
            return "unsubscribe"
        }
    }

    internal func httpMethod() -> String {
        switch self {
        case .subscribe:
            return "POST"
        case .unsubscribe:
            return "DELETE"
        }
    }
}

#endif
