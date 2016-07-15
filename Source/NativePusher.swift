//
//  NativePusher.swift
//  PusherSwift
//
//  Created by James Fisher on 09/06/2016.
//
//

/**
    An interface to Pusher's native push notification service.
    The service is a pub-sub system for push notifications.
    Notifications are published to "interests".
    Clients (such as this app instance) subscribe to those interests.

    A per-app singleton of NativePusher is available via an instance of Pusher.
    Use the Pusher.nativePusher() method to get access to it.
*/
public class NativePusher {
    static let sharedInstance = NativePusher()

    private static let PLATFORM_TYPE = "apns"
    private let CLIENT_API_V1_ENDPOINT = "https://nativepushclient-cluster1.pusher.com/client_api/v1"

    private let URLSession = NSURLSession.sharedSession()
    private var failedNativeServiceRequests: Int = 0
    private let maxFailedRequestAttempts: Int = 6

    /**
        Identifies a Pusher app.
        This app should have push notifications enabled.
    */
    private var pusherAppKey: String? = nil

    /**
        Sets the pusherAppKey property and then attempts to flush
        the outbox of any pending requests

        - parameter pusherAppKey: The Pusher app key
    */
    public func setPusherAppKey(pusherAppKey: String) {
        self.pusherAppKey = pusherAppKey
        tryFlushOutbox()
    }

    /**
        The id issued to this app instance by Pusher.
        We get it upon registration.
        We use it to identify ourselves when subscribing/unsubscribing.
    */
    private var clientId: String? = nil

    /**
        Queued actions to perform when the client is registered.
    */
    private var outbox: [(String, SubscriptionChange)] = []

    /**
        Normal clients should access the shared instance via Pusher.nativePusher().
    */
    private init() {}

    /**
        Makes device token presentable to server

        - parameter deviceToken: the deviceToken received when registering
                                 to receive push notifications, as NSData

        - returns: the deviceToken formatted as a String
    */
    private func deviceTokenToString(deviceToken: NSData) -> String {
        let characterSet: NSCharacterSet = NSCharacterSet(charactersInString: "<>")

        let deviceTokenString: String = (deviceToken.description as NSString)
            .stringByTrimmingCharactersInSet(characterSet)
            .stringByReplacingOccurrencesOfString(" ", withString: "") as String
        return deviceTokenString
    }

    /**
        Registers this app instance with Pusher for push notifications.
        This must be done before we can subscribe to interests.
        Registration happens asynchronously; any errors are reported by print statements.

        - parameter deviceToken: the deviceToken received when registering
                                 to receive push notifications, as NSData
    */
    public func register(deviceToken: NSData) {
        let request = NSMutableURLRequest(URL: NSURL(string: CLIENT_API_V1_ENDPOINT + "/clients")!)
        request.HTTPMethod = "POST"
        let deviceTokenString = deviceTokenToString(deviceToken)

        let params: [String : AnyObject] = [
            "app_key": pusherAppKey!,
            "platform_type": NativePusher.PLATFORM_TYPE,
            "token": deviceTokenString
        ]

        try! request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.dataTaskWithRequest(request, completionHandler: { data, response, error in
            if let httpResponse = response as? NSHTTPURLResponse
                    where (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
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
                        if let json = try!NSJSONSerialization.JSONObjectWithData(data!, options: [])
                                      as? [String: AnyObject] {
                            if let clientIdJson = json["id"] {
                                if let clientId = clientIdJson as? String {
                                    self.clientId = clientId
                                    self.tryFlushOutbox()
                                } else {
                                    print("Value at \"id\" key in JSON response was not a string: " + String(json))
                                }
                            } else {
                                print("No \"id\" key in JSON response: " + String(json))
                            }
                        } else {
                            print("Could not parse body as JSON object:" + String(data))
                        }
            } else {
                print("Bad HTTP response: " + String(response))
            }
        })

        task.resume()
    }

    /**
        Subscribe to an interest with Pusher's Push Notification Service

        - parameter interestName: the name of the interest you want to subscribe to
    */
    public func subscribe(interestName: String) {
        outbox.append(interestName, SubscriptionChange.Subscribe)
        tryFlushOutbox()
    }

    /**
        Unsubscribe from an interest with Pusher's Push Notification Service

        - parameter interestName: the name of the interest you want to unsubscribe
                                  from
    */
    public func unsubscribe(interestName: String) {
        outbox.append(interestName, SubscriptionChange.Unsubscribe)
        tryFlushOutbox()
    }

    /**
        Attempts to flush the outbox by making the appropriate requests to either
        subscribe to or unsubscribe from an interest
    */
    private func tryFlushOutbox() {
        switch (self.pusherAppKey, self.clientId) {
        case (.Some(let pusherAppKey), .Some(let clientId)):
            if (0 < outbox.count) {
                let (interest, change) = outbox.removeAtIndex(0)
                modifySubscription(pusherAppKey, clientId: clientId, interest: interest, change: change) {
                    self.tryFlushOutbox()
                }
            }
        case _: break
        }
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
    private func modifySubscription(pusherAppKey: String, clientId: String, interest: String, change: SubscriptionChange, callback: (Void) -> (Void)) {
        let url = "\(CLIENT_API_V1_ENDPOINT)/clients/\(clientId)/interests/\(interest)"
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        switch (change) {
        case .Subscribe:
            request.HTTPMethod = "POST"
        case .Unsubscribe:
            request.HTTPMethod = "DELETE"
        }

        let params: [String : AnyObject] = ["app_key": pusherAppKey]

        try! request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.dataTaskWithRequest(
            request,
            completionHandler: { data, response, error in
                guard let httpResponse = response as? NSHTTPURLResponse
                    where (200 <= httpResponse.statusCode && httpResponse.statusCode < 300) ||
                    error == nil
                else {
                    self.outbox.insert((interest, change), atIndex: 0)

                    if error != nil {
                        print("Error when trying to modify subscription to interest: \(error?.localizedDescription)")
                    } else {
                        print("Bad response from server when trying to modify subscription to interest " + interest)
                    }
                    self.failedNativeServiceRequests += 1

                    if (self.failedNativeServiceRequests < self.maxFailedRequestAttempts) {
                        callback()
                    } else {
                        print("Max number of failed native service requests reached")
                    }
                    return
                }

                // Reset number of failed requests to 0 upon success
                self.failedNativeServiceRequests = 0

                callback()
            }
        )

        task.resume()
    }
}

private enum SubscriptionChange {
    case Subscribe
    case Unsubscribe
}
