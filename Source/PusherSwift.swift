//
//  PusherSwift.swift
//
//  Created by Hamilton Chapman on 19/02/2015.
//
//

import Foundation
import Starscream
import ReachabilitySwift

public typealias PusherEventJSON = Dictionary<String, AnyObject>
public typealias PusherUserInfoObject = Dictionary<String, AnyObject>
public typealias PusherUserData = PresenceChannelMember

let PROTOCOL = 7
let VERSION = "0.3.0"
let CLIENT_NAME = "pusher-websocket-swift"

public class Pusher {
    public let connection: PusherConnection

    public init(key: String, options: Dictionary<String, Any>? = nil) {
        let pusherClientOptions = PusherClientOptions(options: options)
        let urlString = constructUrl(key, options: pusherClientOptions)
        let ws = WebSocket(url: NSURL(string: urlString)!)
        connection = PusherConnection(key: key, socket: ws, url: urlString, options: pusherClientOptions)
        connection.createGlobalChannel()
    }

    public func subscribe(channelName: String) -> PusherChannel {
        return self.connection.subscribe(channelName)
    }
    
    public func unsubscribe(channelName: String) {
        self.connection.unsubscribe(channelName)
    }

    public func bind(callback: (AnyObject?) -> Void) -> String {
        return self.connection.addCallbackToGlobalChannel(callback)
    }

    public func unbind(callbackId: String) {
        self.connection.removeCallbackFromGlobalChannel(callbackId)
    }

    public func unbindAll() {
        self.connection.removeAllCallbacksFromGlobalChannel()
    }

    public func disconnect() {
        self.connection.disconnect()
    }

    public func connect() {
        self.connection.connect()
    }
}

public enum AuthMethod {
    case Endpoint
    case Internal
    case NoMethod
}

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

internal func isPresenceChannel(channelName: String) -> Bool {
    return (channelName.componentsSeparatedByString("-")[0] == "presence") ? true : false
}

internal func isPrivateChannel(channelName: String) -> Bool {
    return (channelName.componentsSeparatedByString("-")[0] == "private") ? true : false
}
