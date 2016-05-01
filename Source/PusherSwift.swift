//
//  PusherSwift.swift
//
//  Created by Hamilton Chapman on 19/02/2015.
//
//

import Foundation

public typealias PusherEventJSON = Dictionary<String, AnyObject>
public typealias PusherUserInfoObject = Dictionary<String, AnyObject>
public typealias PusherUserData = PresenceChannelMember

let PROTOCOL = 7
let VERSION = "0.3.0"
let CLIENT_NAME = "pusher-websocket-swift"

public class Pusher {
    public let connection: PusherConnection

    /**
        Initializes the Pusher client with an app key and any appropriate options.

        - parameter key:     The Pusher app key
        - parameter options: An optional collection of options

        - returns: A new Pusher client instance
    */
    public init(key: String, options: Dictionary<String, Any>? = nil) {
        let pusherClientOptions = PusherClientOptions(options: options)
        let urlString = constructUrl(key, options: pusherClientOptions)
        let ws = WebSocket(url: NSURL(string: urlString)!)
        connection = PusherConnection(key: key, socket: ws, url: urlString, options: pusherClientOptions)
        connection.createGlobalChannel()
    }

    /**
        Subscribes the client to a new channel

        - parameter channelName: The name of the channel to subscribe to

        - returns: A new PusherChannel instance
     */
    public func subscribe(channelName: String) -> PusherChannel {
        return self.connection.subscribe(channelName)
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
}

public enum AuthMethod {
    case Endpoint
    case Internal
    case NoMethod
}

/**
    Creates a valid URL that can be used in a connection attempt

    - parameter key:     The app key to be inserted into the URL
    - parameter options: The collection of options needed to correctly construct the URL

    - returns: The constructed URL ready to use in a connection attempt
*/
func constructUrl(key: String, options: PusherClientOptions) -> String {
    var url = ""

    if let encrypted = options.encrypted where !encrypted {
        let defaultPort = (options.port ?? 80)
        url = "ws://\(options.host!):\(defaultPort)/app/\(key)"
    } else {
        let defaultPort = (options.port ?? 443)
        url = "wss://\(options.host!):\(defaultPort)/app/\(key)"
    }
    return "\(url)?client=\(CLIENT_NAME)&version=\(VERSION)&protocol=\(PROTOCOL)"
}

/**
    Determines whether or not a given channel name is a valid name for a presence channel

    - parameter channelName: The name of the channel to check
*/
internal func isPresenceChannel(channelName: String) -> Bool {
    return (channelName.componentsSeparatedByString("-")[0] == "presence") ? true : false
}

/**
    Determines whether or not a given channel name is a valid name for a private channel

    - parameter channelName: The name of the channel to check
*/
internal func isPrivateChannel(channelName: String) -> Bool {
    return (channelName.componentsSeparatedByString("-")[0] == "private") ? true : false
}
