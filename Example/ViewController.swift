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
//        let pusher = Pusher(key: "afa4d38348f89ba9c398", options: ["secret": "MY SECRET"])
        let pusher = Pusher(key: "afa4d38348f89ba9c398", options: ["authEndpoint": "http://localhost:9292/pusher/auth"])
        pusher.connect()
        let chan = pusher.subscribe("presence-test-channel")
        

        chan.bind("test-event", callback: { (data: AnyObject?) -> Void in
            println(data)
            if let data = data as? Dictionary<String, AnyObject> {
                if let testVal = data["test"] as? String, testArray = data["test_array"] as? [Int] {
                    println(testVal)
                    println(testArray)
                }
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

