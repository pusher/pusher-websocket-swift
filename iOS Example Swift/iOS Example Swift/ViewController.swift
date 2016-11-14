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
        let pusherClientOptions = PusherClientOptions(authMethod: .inline(secret: "YOUR_APP_SECRET"))
        pusher = Pusher(key: "YOUR_APP_KEY", options: pusherClientOptions)

        // Use this if you want to try out your auth endpoint
//        let optionsWithEndpoint = PusherClientOptions(
//            authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: AuthRequestBuilder())
//        )
//        pusher = Pusher(key: "YOUR_APP_KEY", options: optionsWithEndpoint)

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

class AuthRequestBuilder: AuthRequestBuilderProtocol {
    func requestFor(socketID: String, channel: PusherChannel) -> URLRequest? {
        var request = URLRequest(url: URL(string: "http://localhost:9292/pusher/auth")!)
        request.httpMethod = "POST"
        request.httpBody = "socket_id=\(socketID)&channel_name=\(channel.name)".data(using: String.Encoding.utf8)
        return request
    }
}
