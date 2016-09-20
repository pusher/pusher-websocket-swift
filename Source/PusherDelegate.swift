//
//  PusherDelegate.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 19/09/2016.
//
//

@objc public protocol PusherDelegate: class {
    @objc optional func didRegisterForPushNotifications(clientId: String)
    @objc optional func didSubscribeToInterest(named name: String)
    @objc optional func didUnsubscribeFromInterest(named name: String)
}
