//
//  PusherIncomingEventHandlingTests.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 07/04/2016.
//
//

import Quick
import Nimble
import PusherSwift

class HandlingIncomingEventsSpec: QuickSpec {
    override func spec() {
        describe("receiving an event") {
            var key: String!
            var pusher: Pusher!
            var socket: MockWebSocket!

            beforeEach({
                key = "testKey123"
                pusher = Pusher(key: key)
                socket = MockWebSocket()
                socket.delegate = pusher.connection
                pusher.connection.socket = socket
            })

            it("should call any callbacks setup on the globalChannel") {
                let callback = { (data: AnyObject?) -> Void in socket.appendToCallbackCheckString("testingIWasCalled") }
                pusher.bind(callback)
                expect(socket.callbackCheckString).to(equal(""))
                pusher.connection.handleEvent("test-event", jsonObject: ["event": "test-event", "channel": "my-channel", "data": "stupid data"])
                expect(socket.callbackCheckString).to(equal("testingIWasCalled"))
            }

            it("should call the relevant callback(s) setup on the relevant channel(s)") {
                let callback = { (data: AnyObject?) -> Void in socket.appendToCallbackCheckString("channelCallbackCalled") }
                let chan = pusher.subscribe("my-channel")
                chan.bind("test-event", callback: callback)
                expect(socket.callbackCheckString).to(equal(""))
                pusher.connection.handleEvent("test-event", jsonObject: ["event": "test-event", "channel": "my-channel", "data": "stupid data"])
                expect(socket.callbackCheckString).to(equal("channelCallbackCalled"))
            }

            it("should call the relevant callback(s) setup on the relevant channel(s) and on the globalChannel") {
                let callback = { (data: AnyObject?) -> Void in socket.appendToCallbackCheckString("globalCallbackCalled") }
                pusher.bind(callback)
                let chan = pusher.subscribe("my-channel")
                let callbackForChannel = { (data: AnyObject?) -> Void in socket.appendToCallbackCheckString("channelCallbackCalled") }
                chan.bind("test-event", callback: callbackForChannel)
                expect(socket.callbackCheckString).to(equal(""))
                pusher.connection.handleEvent("test-event", jsonObject: ["event": "test-event", "channel": "my-channel", "data": "stupid data"])
                expect(socket.callbackCheckString).to(equal("globalCallbackCalledchannelCallbackCalled"))
            }

            it("should return a JSON object to the callbacks if the string can be parsed and the user wanted to get a JSON object") {
                let callback = { (data: AnyObject?) -> Void in socket.storeDataObjectGivenToCallback(data!) }
                let chan = pusher.subscribe("my-channel")
                chan.bind("test-event", callback: callback)
                expect(socket.objectGivenToCallback).to(beNil())
                pusher.connection.handleEvent("test-event", jsonObject: ["event": "test-event", "channel": "my-channel", "data": "{\"test\":\"test string\",\"and\":\"another\"}"])
                expect(socket.objectGivenToCallback as? Dictionary<String, String>).to(equal(["test": "test string", "and": "another"]))
            }

            it("should return a JSON string to the callbacks if the string cannot be parsed and the user wanted to get a JSON object") {
                let callback = { (data: AnyObject?) -> Void in socket.storeDataObjectGivenToCallback(data!) }
                let chan = pusher.subscribe("my-channel")
                chan.bind("test-event", callback: callback)
                expect(socket.objectGivenToCallback).to(beNil())
                pusher.connection.handleEvent("test-event", jsonObject: ["event": "test-event", "channel": "my-channel", "data": "test"])
                expect(socket.objectGivenToCallback as? String).to(equal("test"))
            }

            it("should return a JSON string to the callbacks if the string can be parsed but the user doesn't want to get a JSON object") {
                pusher = Pusher(key: key, options: ["attemptToReturnJSONObject": "false"])
                socket.delegate = pusher.connection
                pusher.connection.socket = socket
                let callback = { (data: AnyObject?) -> Void in socket.storeDataObjectGivenToCallback(data!) }
                let chan = pusher.subscribe("my-channel")
                chan.bind("test-event", callback: callback)
                expect(socket.objectGivenToCallback).to(beNil())
                pusher.connection.handleEvent("test-event", jsonObject: ["event": "test-event", "channel": "my-channel", "data": "{\"test\":\"test string\",\"and\":\"another\"}"])
                expect(socket.objectGivenToCallback as? String).to(equal("{\"test\":\"test string\",\"and\":\"another\"}"))
            }
        }
    }
}

