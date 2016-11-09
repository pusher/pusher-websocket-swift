//
//  AppDelegate.swift
//  macOS Example Swift
//
//  Created by Hamilton Chapman on 09/11/2016.
//  Copyright © 2016 Pusher. All rights reserved.
//

import Cocoa
import PusherSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, PusherDelegate {

    let pusher = Pusher(key: "YOUR_APP_KEY")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSApp.registerForRemoteNotifications(matching: [NSRemoteNotificationType.alert, NSRemoteNotificationType.sound, NSRemoteNotificationType.badge]);

        self.pusher.delegate = self
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.pusher.nativePusher.register(deviceToken: deviceToken)
        self.pusher.nativePusher.subscribe(interestName: "donuts")
    }

    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
        print("Received remote notification: " + userInfo.debugDescription)
    }

    // MARK: PusherDelegate

    func subscribedToInterest(name: String) {
        print("Subscribed to interest: \(name)")
    }

    func unsubscribedFromInterest(name: String) {
        print("Unsubscribed from interest: \(name)")
    }

    func registeredForPushNotifications(clientId: String) {
        print("Registered with Pusher for push notifications with clientId: \(clientId)")
    }

    func debugLog(message: String) {
        print(message)
    }
}
