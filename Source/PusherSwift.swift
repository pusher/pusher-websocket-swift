//
//  PusherSwift.swift
//
//  Created by Hamilton Chapman on 19/02/2015.
//
//

import Foundation

let PROTOCOL = 7
let VERSION = "1.0.0"
let CLIENT_NAME = "pusher-websocket-swift"

public class Pusher {
    public let connection: PusherConnection
    private let key: String

    /**
        Initializes the Pusher client with an app key and any appropriate options.

        - parameter key:     The Pusher app key
        - parameter options: An optional collection of options

        - returns: A new Pusher client instance
    */
    public init(key: String, options: PusherClientOptions = PusherClientOptions()) {
        self.key = key
        let urlString = constructUrl(key, options: options)
        let ws = WebSocket(url: NSURL(string: urlString)!)
        connection = PusherConnection(key: key, socket: ws, url: urlString, options: options)
        connection.createGlobalChannel()
    }

    /**
        Subscribes the client to a new channel

        - parameter channelName:     The name of the channel to subscribe to
        - parameter onMemberAdded:   A function that will be called with information about the
                                     member who has just joined the presence channel
        - parameter onMemberRemoved: A function that will be called with information about the
                                     member who has just left the presence channel

        - returns: A new PusherChannel instance
     */
    public func subscribe(
        channelName: String,
        onMemberAdded: ((PresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((PresenceChannelMember) -> ())? = nil) -> PusherChannel {
            return self.connection.subscribe(channelName, onMemberAdded: onMemberAdded, onMemberRemoved: onMemberRemoved)
    }

    /**
        Unsubscribes the client from a given channel

        - parameter channelName: The name of the channel to unsubscribe from
    */
    public func unsubscribe(channelName: String) {
        self.connection.unsubscribe(channelName)
    }

    /**
        Binds the client's global channel to all events

        - parameter callback: The function to call when a new event is received

        - returns: A unique string that can be used to unbind the callback from the client
    */
    public func bind(callback: (AnyObject?) -> Void) -> String {
        return self.connection.addCallbackToGlobalChannel(callback)
    }

    /**
        Unbinds the client from its global channel

        - parameter callbackId: The unique callbackId string used to identify which callback to unbind
    */
    public func unbind(callbackId: String) {
        self.connection.removeCallbackFromGlobalChannel(callbackId)
    }

    /**
        Unbinds the client from all global callbacks
    */
    public func unbindAll() {
        self.connection.removeAllCallbacksFromGlobalChannel()
    }

    /**
        Disconnects the client's connection
    */
    public func disconnect() {
        self.connection.disconnect()
    }

    /**
        Initiates a connection attempt using the client's existing connection details
    */
    public func connect() {
        self.connection.connect()
    }

    /**
        Registers the application with Pusher for native notifications
    */
    public func registerForPushNotifications(deviceToken : NSData)  {
        PusherPushNotificationRegistration.register(deviceToken)
    }

    /**
     Registers an interest with Pusher's Push Notification Service
     */
    public func registerPushNotificationInterest(name: String) {
        PusherPushNotificationRegistration.sharedInstance.addInterest(key, name: name)
    }

}

internal class PusherPushNotificationRegistration {
    private static let sharedInstance = PusherPushNotificationRegistration()

    private static let PLATFORM_TYPE = "apns"
    private static let URLSession = NSURLSession.sharedSession()
    private static let CLIENT_API_ENDPOINT = "https://nativepushclient-cluster1.pusher.com/client_api/v1"


    private static func register(deviceToken : NSData) {
        let request = NSMutableURLRequest(URL: NSURL(string: CLIENT_API_ENDPOINT + "/clients")!)
        request.HTTPMethod = "POST"
        let deviceTokenString = deviceTokenToString(deviceToken)

        let params: [String: AnyObject] = [
            "platform_type": PusherPushNotificationRegistration.PLATFORM_TYPE,
            "token": deviceTokenString
        ]

        try! request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: [])

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.dataTaskWithRequest(request, completionHandler: { data, response, error in
            if let httpResponse = response as? NSHTTPURLResponse where (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                print(httpResponse.statusCode)
                if let json = try!NSJSONSerialization.JSONObjectWithData(data!, options: []) as? Dictionary<String, AnyObject>
                {
                    if let clientId = json["id"] {
                        self.sharedInstance.activate(clientId as! String)
                        print(self.sharedInstance)
                    }
                } else {
                    // TODO: handle error
                }
            } else {
                // TODO: handle error
            }
        })

        task.resume()
    }


    private var clientId: String?
    private var pendingInterests: Set<Interest>

    private init() {
        clientId = nil
        pendingInterests = []
    }

    internal func addInterest(appKey: String, name: String) {
        let interest = Interest(name: name, appKey: appKey)
        if (isActive()) {
            registerInterestWithClientId(interest)
        } else {
            pendingInterests.insert(interest)
        }
    }

    private func activate(clientId : String) {
        self.clientId = clientId
        flushPendingInterests()
    }

    private func flushPendingInterests() {
        for interest in pendingInterests {
            registerInterestWithClientId(interest)
        }
    }

    private func registerInterestWithClientId(interest: Interest) {
        interest.register(clientId!) {
            self.pendingInterests.remove(interest)
        }
    }

    private func isActive() -> Bool {
        return clientId == nil ? false : true
    }


}

internal struct Interest : Hashable, Equatable {
    private static let URLSession = NSURLSession.sharedSession()

    let name: String
    let appKey: String

    var hashValue: Int {
        get {
            return "\(name)-\(appKey)".hash
        }
    }

    private func register(clientId: String, callback: (Void)->(Void)) {
        let url = "\(PusherPushNotificationRegistration.CLIENT_API_ENDPOINT)/clients/\(clientId)/interests/\(name)"
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = "POST"

        let params: [String: AnyObject] = [
            "app_key": appKey,
            ]

        try! request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = Interest.URLSession.dataTaskWithRequest(request, completionHandler: { data, response, error in
            guard let httpResponse = response as? NSHTTPURLResponse where (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) else {
                // TODO: handle error
                return
            }
            callback()
        })

        task.resume()
    }
}

internal func ==(lhs: Interest, rhs: Interest) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

/**
    Creates a valid URL that can be used in a connection attempt

    - parameter key:     The app key to be inserted into the URL
    - parameter options: The collection of options needed to correctly construct the URL

    - returns: The constructed URL ready to use in a connection attempt
*/
func constructUrl(key: String, options: PusherClientOptions) -> String {
    var url = ""

    if options.encrypted {
        url = "wss://\(options.host):\(options.port)/app/\(key)"
    } else {
        url = "ws://\(options.host):\(options.port)/app/\(key)"
    }
    return "\(url)?client=\(CLIENT_NAME)&version=\(VERSION)&protocol=\(PROTOCOL)"
}

/**
    Makes device token presentable to server
*/
internal func deviceTokenToString(deviceToken: NSData) -> String {
    let characterSet: NSCharacterSet = NSCharacterSet( charactersInString: "<>" )

    let deviceTokenString: String = ( deviceToken.description as NSString )
        .stringByTrimmingCharactersInSet( characterSet )
        .stringByReplacingOccurrencesOfString( " ", withString: "" ) as String
    return deviceTokenString
}
