//
//  PusherDelegate.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 19/09/2016.
//
//

@objc public protocol PusherDelegate: class {
    @objc optional func debugLog(message: String)

    @objc optional func registeredForPushNotifications(clientId: String)
    @objc optional func failedToRegisterForPushNotifications(response: URLResponse, responseBody: String?)
    @objc optional func subscribedToInterest(name: String)
    @objc optional func subscribedToInterests(interests: Array<String>)
    @objc optional func unsubscribedFromInterest(name: String)

    @objc optional func changedConnectionState(from old: ConnectionState, to new: ConnectionState)
    @objc optional func subscribedToChannel(name: String)
    @objc optional func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?)
}
