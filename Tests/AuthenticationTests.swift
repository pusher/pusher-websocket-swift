//
//  AuthenticationTests.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 07/04/2016.
//
//

import Quick
import Nimble
import PusherSwift

class AuthenticationSpec: QuickSpec {
    override func spec() {
        var pusher: Pusher!
        var socket: MockWebSocket!

        beforeEach({
            pusher = Pusher(key: "testKey123", options: ["authEndpoint": "http://localhost:9292/pusher/auth"])
            socket = MockWebSocket()
            socket.delegate = pusher.connection
            pusher.connection.socket = socket
        })

        describe("subscribing to a private channel") {
            it("should make a request to the authEndpoint") {
                let jsonData = "{\"auth\":\"testKey123:12345678gfder78ikjbg\"}".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
                let urlResponse = NSHTTPURLResponse(URL: NSURL(string: "\(pusher.connection.options.authEndpoint!)?channel_name=private-test-channel&socket_id=45481.3166671")!, statusCode: 200, HTTPVersion: nil, headerFields: nil)
                MockSession.mockResponse = (jsonData, urlResponse: urlResponse, error: nil)
                pusher.connection.URLSession = MockSession.sharedSession()

                let chan = pusher.subscribe("private-test-channel")
                expect(chan.subscribed).to(beFalsy())
                pusher.connect()
                expect(chan.subscribed).toEventually(beTruthy())
            }

            it("should create the auth signature internally") {
                pusher = Pusher(key: "key", options: ["secret": "secret"])
                socket.delegate = pusher.connection
                pusher.connection.socket = socket

                let chan = pusher.subscribe("private-test-channel")
                expect(chan.subscribed).to(beFalsy())
                pusher.connect()
                expect(chan.subscribed).to(beTruthy())
            }

            it("should not subscribe successfully to a private or presence channel if no auth method provided") {
                pusher = Pusher(key: "key")
                socket.delegate = pusher.connection
                pusher.connection.socket = socket

                let chan = pusher.subscribe("private-test-channel")
                expect(chan.subscribed).to(beFalsy())
                pusher.connect()
                expect(chan.subscribed).to(beFalsy())
            }
        }
    }
}
