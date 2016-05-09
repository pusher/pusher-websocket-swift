//
//  ViewController.swift
//  iOS Example
//
//  Created by Hamilton Chapman on 24/02/2015.
//  Copyright (c) 2015 Pusher. All rights reserved.
//

import UIKit
import PusherSwift

class ViewController: UIViewController, ConnectionStateChangeDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Only use your secret here for testing or if you're sure that there's
        // no security risk
        let pusher = Pusher(key: "YOUR_APP_KEY", options: ["secret": "YOUR_APP_SECRET"])

        pusher.connection.stateChangeDelegate = self
        pusher.connect()

        let onMemberAdded = { (member: PresenceChannelMember) in
            print(member)
        }
        let chan = pusher.subscribe("presence-channel", onMemberAdded: onMemberAdded)

        chan.bind("test-event", callback: { (data: AnyObject?) -> Void in
            print(data)
            if let data = data as? Dictionary<String, AnyObject> {
                if let testVal = data["test"] as? String {
                    print(testVal)
                }
            }
        })

        chan.trigger("client-test", data: ["test": "some value"])
    }

    func connectionChange(old: ConnectionState, new: ConnectionState) {
        print("old: \(old) -> new: \(new)")
    }
}

