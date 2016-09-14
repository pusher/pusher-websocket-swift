//
//  PusherConnectionDelegate.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 13/09/2016.
//
//

import Foundation

@objc public protocol PusherConnectionDelegate: class {
    @objc optional func connectionStateDidChange(from old: ConnectionState, to new: ConnectionState)
    @objc optional func debugLog(message: String)
    @objc optional func subscriptionDidSucceed(channelName: String)
    @objc optional func subscriptionDidFail(channelName: String, response: URLResponse?, data: String?, error: NSError?)
}
