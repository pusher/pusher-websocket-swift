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
    public let pushNotificationRegistration: PushNotificationRegistration? = nil

    /**
        Initializes the Pusher client with an app key and any appropriate options.

        - parameter key:     The Pusher app key
        - parameter options: An optional collection of options

        - returns: A new Pusher client instance
    */
    public init(key: String, options: PusherClientOptions = PusherClientOptions()) {
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
    public func registerForPushNotifications(deviceToken : NSData, withInterests : [String] = [], callback : (PushNotificationRegistration, ErrorType?) -> Void)  {
        if (self.pushNotificationRegistration != nil) {
            callback(self.pushNotificationRegistration!, nil)
            return
        }

        PushNotificationRegistration.register(deviceToken)
    }
}

public struct PushNotificationRegistration {
    let id: Int64
    private static let platformType = "apns"
    private static let URLSession = NSURLSession.sharedSession();

    private static func register(deviceToken : NSData, withInterests : [String] = []) {
        let endpoint = "https://yolo.ngrok.io/client_api/v1/apps/3/clients"
        var request = NSMutableURLRequest(URL: NSURL(string: endpoint)!)
        request.HTTPMethod = "POST"

        let characterSet: NSCharacterSet = NSCharacterSet( charactersInString: "<>" )

        let deviceTokenString: String = ( deviceToken.description as NSString )
            .stringByTrimmingCharactersInSet( characterSet )
            .stringByReplacingOccurrencesOfString( " ", withString: "" ) as String


        let params: [String: AnyObject] = [
            "platform_type": platformType,
            "token": deviceTokenString,
            "interests": withInterests
        ]


        do {
            try request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: [])
        } catch _ {
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.dataTaskWithRequest(request)
        task.resume()
    }
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
