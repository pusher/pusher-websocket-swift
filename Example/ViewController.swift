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
        let chan = pusher.subscribe("test-channel")


        chan.bind("test-event", callback: { (data: AnyObject?) -> Void in
            print(data)
            if let data = data as? Dictionary<String, AnyObject> {
                if let testVal = data["test"] as? String {
                    print(testVal)
                }
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func connectionChange(old: ConnectionState, new: ConnectionState) {
        print("old: \(old) -> new: \(new)")
    }
}

