//
//  ViewController.swift
//  iOS Example
//
//  Created by Hamilton Chapman on 24/02/2015.
//  Copyright (c) 2015 Pusher. All rights reserved.
//

import UIKit
import PusherSwift

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let pusher = Pusher(key: "87572504efd5d4f1b353", options: ["secret": "ab53d405ac3c245972ee"])
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


}

