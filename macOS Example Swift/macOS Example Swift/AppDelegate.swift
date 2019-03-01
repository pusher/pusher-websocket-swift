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
class AppDelegate: NSObject, NSApplicationDelegate {

    let pusher = Pusher(key: "YOUR_APP_KEY")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
