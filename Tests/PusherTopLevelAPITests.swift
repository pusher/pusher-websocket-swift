//
//  PusherTopLevelAPITests.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 07/04/2016.
//
//

import Nimble
import Quick
import PusherSwift

class PusherTopLevelApiSpec: QuickSpec {
    override func spec() {
        var key: String!
        var pusher: Pusher!
        var socket: MockWebSocket!

        beforeEach({
            key = "testKey123"
            let options = PusherClientOptions(
                autoReconnect: false
            )
            pusher = Pusher(key: key, options: options)
            socket = MockWebSocket()
            socket.delegate = pusher.connection
            pusher.connection.socket = socket
        })

        describe("creating the connection") {
            it("calls connect on the socket") {
                pusher.connect()
                expect(socket.stubber.calls[0].name).to(equal("connect"))
            }

            it("connected is set to true when connection connects") {
                pusher.connect()
                expect(pusher.connection.connectionState).to(equal(ConnectionState.connected))
            }
        }

        describe("closing the connection") {
            it("calls disconnect on the socket") {
                pusher.connect()
                pusher.disconnect()
                expect(socket.stubber.calls[1].name).to(equal("disconnect"))
            }

            it("connected is set to false when connection is disconnected") {
                pusher.connect()
                expect(pusher.connection.connectionState).to(equal(ConnectionState.connected))
                pusher.disconnect()
                expect(pusher.connection.connectionState).to(equal(ConnectionState.disconnected))
            }

            it("sets the subscribed property of channels to false") {
                pusher.connect()
                let chan = pusher.subscribe("test-channel")
                expect(chan.subscribed).to(beTruthy())
                pusher.disconnect()
                expect(chan.subscribed).to(beFalsy())
            }
        }

        describe("subscribing to channels") {
            describe("after connection has been made") {
                beforeEach({
                    pusher.connect()
                })

                it("sends subscribe to Pusher over the Websocket") {
                    _ = pusher.subscribe("test-channel")
                    expect(socket.stubber.calls.last?.name).to(equal("writeString"))
                    let parsedSubscribeArgs = convertStringToDictionary(socket.stubber.calls.last?.args!.first as! String)
                    let expectedDict = ["data": ["channel": "test-channel"], "event": "pusher:subscribe"] as [String : Any]
                    let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject : AnyObject])
                    expect(parsedEqualsExpected).to(beTrue())
                }

                it("subscribes to a public channel") {
                    let _ = pusher.subscribe("test-channel")
                    let testChannel = pusher.connection.channels.channels["test-channel"]
                    expect(testChannel?.subscribed).to(beTruthy())
                }

                it("subscription succeeded event sent to global channel") {
                    let callback = { (data: Any?) -> Void in
                        if let data = data as? [String : Any], let eName = data["event"] as? String, eName == "pusher:subscription_succeeded" {
                            socket.appendToCallbackCheckString("globalCallbackCalled")
                        }
                    }
                    let _ = pusher.bind(callback)
                    expect(socket.callbackCheckString).to(equal(""))
                    let _ = pusher.subscribe("test-channel")
                    expect(socket.callbackCheckString).to(equal("globalCallbackCalled"))
                }

                it("subscription succeeded event sent to private channel") {
                    let callback = { (data: Any?) -> Void in
                        if let data = data as? [String : Any], let eName = data["event"] as? String, eName == "pusher:subscription_succeeded" {
                            socket.appendToCallbackCheckString("channelCallbackCalled")
                        }
                    }
                    let _ = pusher.bind(callback)
                    expect(socket.callbackCheckString).to(equal(""))
                    let chan = pusher.subscribe("test-channel")
                    let _ = chan.bind(eventName: "pusher:subscription_succeeded", callback: callback)
                    expect(socket.callbackCheckString).to(equal("channelCallbackCalled"))
                }

                it("sets up the channel correctly") {
                    let chan = pusher.subscribe("test-channel")
                    expect(chan.name).to(equal("test-channel"))
                    expect(chan.eventHandlers).to(beEmpty())
                }

                describe("that require authentication") {
                    beforeEach({
                        let options = PusherClientOptions(
                            authMethod: AuthMethod.`internal`(secret: "secret")
                        )
                        pusher = Pusher(key: "key", options: options)
                        socket.delegate = pusher.connection
                        pusher.connection.socket = socket
                        pusher.connect()
                    })

                    it("subscribes to a private channel") {
                        let _ = pusher.subscribe("private-channel")
                        let privateChannel = pusher.connection.channels.channels["private-channel"]
                        expect(privateChannel?.subscribed).to(beTruthy())
                    }

                    it("subscribes to a presence channel") {
                        let _ = pusher.subscribe("presence-channel")
                        let presenceChannel = pusher.connection.channels.channels["presence-channel"]
                        expect(presenceChannel?.subscribed).to(beTruthy())
                    }

                    it("sets up the channel correctly") {
                        let chan = pusher.subscribe("private-channel")
                        expect(chan.name).to(equal("private-channel"))
                        expect(chan.eventHandlers).to(beEmpty())
                    }
                }
            }

            describe("before connection has been made") {
                it("subscribes to a public channel") {
                    let _ = pusher.subscribe("test-channel")
                    let testChannel = pusher.connection.channels.channels["test-channel"]
                    pusher.connect()
                    expect(testChannel?.subscribed).to(beTruthy())
                }

                it("sets up the channel correctly") {
                    let chan = pusher.subscribe("test-channel")
                    expect(chan.name).to(equal("test-channel"))
                    expect(chan.eventHandlers).to(beEmpty())
                }

                describe("that require authentication") {
                    beforeEach({
                        let options = PusherClientOptions(
                            authMethod: AuthMethod.`internal`(secret: "secret")
                        )
                        pusher = Pusher(key: "key", options: options)
                        socket.delegate = pusher.connection
                        pusher.connection.socket = socket
                    })

                    it("subscribes to a private channel") {
                        let _ = pusher.subscribe("private-channel")
                        let privateChannel = pusher.connection.channels.channels["private-channel"]
                        pusher.connect()
                        expect(privateChannel?.subscribed).to(beTruthy())
                    }

                    it("subscribes to a presence channel") {
                        let _ = pusher.subscribe("presence-channel")
                        let presenceChannel = pusher.connection.channels.channels["presence-channel"]
                        pusher.connect()
                        expect(presenceChannel?.subscribed).to(beTruthy())
                    }

                    it("sets up the channel correctly") {
                        let chan = pusher.subscribe("private-channel")
                        expect(chan.name).to(equal("private-channel"))
                        expect(chan.eventHandlers).to(beEmpty())
                    }
                }
            }
        }

        describe("unsubscribing from a channel") {
            it("removes the channel from the connection's channels property") {
                pusher.connect()
                let _ = pusher.subscribe("test-channel")
                expect(pusher.connection.channels.channels["test-channel"]).toNot(beNil())
                pusher.unsubscribe("test-channel")
                expect(pusher.connection.channels.channels["test-channel"]).to(beNil())
            }

            it("sends unsubscribe to Pusher over the Websocket") {
                pusher.connect()
                let _ = pusher.subscribe("test-channel")
                pusher.unsubscribe("test-channel")
                expect(socket.stubber.calls.last?.name).to(equal("writeString"))
                let parsedSubscribeArgs = convertStringToDictionary(socket.stubber.calls.last?.args!.first as! String)
                let expectedDict = ["data": ["channel": "test-channel"], "event": "pusher:unsubscribe"] as [String : Any]
                let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject : AnyObject])
                expect(parsedEqualsExpected).to(beTrue())
            }
        }

        describe("binding to events globally") {
            it("adds a callback to the globalChannel's list of callbacks") {
                pusher.connect()
                let callback = { (data: Any?) -> Void in print(data) }
                expect(pusher.connection.globalChannel?.globalCallbacks.count).to(equal(0))
                let _ = pusher.bind(callback)
                expect(pusher.connection.globalChannel?.globalCallbacks.count).to(equal(1))
            }
        }

        describe("unbinding a global callback") {
            it("unbinds the callback from the globalChannel's list of callbacks") {
                pusher.connect()
                let callback = { (data: Any?) -> Void in print(data) }
                let callBackId = pusher.bind(callback)
                expect(pusher.connection.globalChannel?.globalCallbacks.count).to(equal(1))
                pusher.unbind(callbackId: callBackId)
                expect(pusher.connection.globalChannel?.globalCallbacks.count).to(equal(0))
            }
        }

        describe("unbinding all global callbacks") {
            it("unbinds the callback from the globalChannel's list of callbacks") {
                pusher.connect()
                let callback = { (data: Any?) -> Void in print(data) }
                let _ = pusher.bind(callback)
                let callbackTwo = { (someData: Any?) -> Void in print(someData) }
                let _ = pusher.bind(callbackTwo)
                expect(pusher.connection.globalChannel?.globalCallbacks.count).to(equal(2))
                pusher.unbindAll()
                expect(pusher.connection.globalChannel?.globalCallbacks.count).to(equal(0))
            }
        }
    }
}

