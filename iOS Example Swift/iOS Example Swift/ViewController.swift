//
//  ViewController.swift
//  iOS Example
//
//  Created by Hamilton Chapman on 24/02/2015.
//  Copyright (c) 2015 Pusher. All rights reserved.
//

import UIKit
import PusherSwift

class ViewController: UIViewController, PusherDelegate {
    var pusher: Pusher! = nil

    @IBAction func connectButton(_ sender: AnyObject) {
        pusher.connect()
    }

    @IBAction func disconnectButton(_ sender: AnyObject) {
        pusher.disconnect()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Only use your secret here for testing or if you're sure that there's
        // no security risk
        let pusherClientOptions = PusherClientOptions(authMethod: .inline(secret: "daef58559fdd0aba8b63"))
        pusher = Pusher(key: "568d5a3851502158a022", options: pusherClientOptions)

        pusher.delegate = self

        pusher.connect()

        let _ = pusher.bind({ (message: Any?) in
            if let message = message as? [String: AnyObject], let eventName = message["event"] as? String, eventName == "pusher:error" {
                if let data = message["data"] as? [String: AnyObject], let errorMessage = data["message"] as? String {
                    print("Error message: \(errorMessage)")
                }
            }
        })

        let onMemberAdded = { (member: PusherPresenceChannelMember) in
            print(member)
        }

        let chan = pusher.subscribe("presence-channel", onMemberAdded: onMemberAdded)

        let _ = chan.bind(eventName: "test-event", callback: { data in
            print(data)
            let _ = self.pusher.subscribe("presence-channel", onMemberAdded: onMemberAdded)

            if let data = data as? [String : AnyObject] {
                if let testVal = data["test"] as? String {
                    print(testVal)
                }
            }
        })

        // triggers a client event
        chan.trigger(eventName: "client-test", data: ["test": "some value"])
    }

    // PusherDelegate methods

    func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        // print the old and new connection states
        print("old: \(old.stringValue()) -> new: \(new.stringValue())")
    }

    func subscribedToChannel(name: String) {
        print("Subscribed to \(name)")
    }

    func debugLog(message: String) {
        print(message)
    }
}

