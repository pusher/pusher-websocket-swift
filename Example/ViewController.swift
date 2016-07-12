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
    var pusher: Pusher! = nil

    @IBAction func connectButton(sender: AnyObject) {
        pusher.connect()
    }

    @IBAction func disconnectButton(sender: AnyObject) {
        pusher.disconnect()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Only use your secret here for testing or if you're sure that there's
        // no security risk
        let pusherClientOptions = PusherClientOptions(authMethod: .Internal(secret: "YOUR_APP_SECRET"))
        pusher = Pusher(key: "YOUR_APP_KEY", options: pusherClientOptions)

        // remove the debugLogger from the client options if you want to remove the
        // debug logging, or just change the function below
        let debugLogger = { (text: String) in debugPrint(text) }
        pusher.connection.debugLogger = debugLogger

        pusher.connection.stateChangeDelegate = self

        pusher.connect()

        pusher.bind({ (message: AnyObject?) in
            if let message = message as? [String: AnyObject], eventName = message["event"] as? String where eventName == "pusher:error" {
                if let data = message["data"] as? [String: AnyObject], errorMessage = data["message"] as? String {
                    print("Error message: \(errorMessage)")
                }
            }
        })

        let onMemberAdded = { (member: PresenceChannelMember) in
            print(member)
        }

        let chan = pusher.subscribe("presence-channel", onMemberAdded: onMemberAdded)

        chan.bind("test-event", callback: { (data: AnyObject?) -> Void in
            print(data)
            self.pusher.subscribe("presence-channel", onMemberAdded: onMemberAdded)

            if let data = data as? [String : AnyObject] {
                if let testVal = data["test"] as? String {
                    print(testVal)
                }
            }
        })

        // triggers a client event
        chan.trigger("client-test", data: ["test": "some value"])
    }

    func connectionChange(old: ConnectionState, new: ConnectionState) {
        // print the old and new connection states
        print("old: \(old) -> new: \(new)")
    }
}

