//
//  PusherIncomingEventHandlingTests.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 07/04/2016.
//
//

import PusherSwift
import XCTest

class HandlingIncomingEventsTests: XCTestCase {
    var key: String!
    var pusher: Pusher!
    var socket: MockWebSocket!

  override func setUp() {
      super.setUp()

      key = "testKey123"
      pusher = Pusher(key: key)
      socket = MockWebSocket()
      socket.delegate = pusher.connection
      pusher.connection.socket = socket
  }

    func testCallbacksOnGlobalChannelShouldBeCalled() {
        let callback = { (data: Any?) -> Void in self.socket.appendToCallbackCheckString("testingIWasCalled") }
        let _ = pusher.bind(callback)

        XCTAssertEqual(socket.callbackCheckString, "")
        pusher.connection.handleEvent(eventName: "test-event", jsonObject: ["event": "test-event" as AnyObject, "channel": "my-channel" as AnyObject, "data": "stupid data" as AnyObject])
        XCTAssertEqual(socket.callbackCheckString, "testingIWasCalled")
    }

    func testCallbacksOnRelevantChannelsShouldBeCalled() {
        let callback = { (data: Any?) -> Void in self.socket.appendToCallbackCheckString("channelCallbackCalled") }
        let chan = pusher.subscribe("my-channel")
        let _ = chan.bind(eventName: "test-event", callback: callback)

        XCTAssertEqual(socket.callbackCheckString, "")
        pusher.connection.handleEvent(eventName: "test-event", jsonObject: ["event": "test-event" as AnyObject, "channel": "my-channel" as AnyObject, "data": "stupid data" as AnyObject])
        XCTAssertEqual(socket.callbackCheckString, "channelCallbackCalled")
    }

    func testCallbacksOnRelevantChannelsAndGlobalChannelShouldBeCalled() {
        let callback = { (data: Any?) -> Void in self.socket.appendToCallbackCheckString("globalCallbackCalled") }
        let _ = pusher.bind(callback)
        let chan = pusher.subscribe("my-channel")
        let callbackForChannel = { (data: Any?) -> Void in self.socket.appendToCallbackCheckString("channelCallbackCalled") }
        let _ = chan.bind(eventName: "test-event", callback: callbackForChannel)

        XCTAssertEqual(socket.callbackCheckString, "")
        pusher.connection.handleEvent(eventName: "test-event", jsonObject: ["event": "test-event" as AnyObject, "channel": "my-channel" as AnyObject, "data": "stupid data" as AnyObject])
        XCTAssertEqual(socket.callbackCheckString, "globalCallbackCalledchannelCallbackCalled")
    }

    func testReturningAJSONObjectToCallbacksIfTheStringCanBeParsed() {
        let callback = { (data: Any?) -> Void in self.socket.storeDataObjectGivenToCallback(data!) }
        let chan = pusher.subscribe("my-channel")
        let _ = chan.bind(eventName: "test-event", callback: callback)

        XCTAssertNil(socket.objectGivenToCallback)
        pusher.connection.handleEvent(eventName: "test-event", jsonObject: ["event": "test-event" as AnyObject, "channel": "my-channel" as AnyObject, "data": "{\"test\":\"test string\",\"and\":\"another\"}" as AnyObject])
        XCTAssertEqual(socket.objectGivenToCallback as! [String : String], ["test": "test string", "and": "another"])
    }

    func testReturningAJSONStringToCallbacksIfTheStringCannotBeParsed() {
        let callback = { (data: Any?) -> Void in self.socket.storeDataObjectGivenToCallback(data!) }
        let chan = pusher.subscribe("my-channel")
        let _ = chan.bind(eventName: "test-event", callback: callback)

        XCTAssertNil(socket.objectGivenToCallback)
        pusher.connection.handleEvent(eventName: "test-event", jsonObject: ["event": "test-event" as AnyObject, "channel": "my-channel" as AnyObject, "data": "test" as AnyObject])
        XCTAssertEqual(socket.objectGivenToCallback as? String, "test")
    }

    func testReturningAJSONStringToCallbacksIfTheStringCanBeParsedButAttemptToReturnJSONObjectIsFalse() {
        let options = PusherClientOptions(attemptToReturnJSONObject: false)
        pusher = Pusher(key: key, options: options)
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        let callback = { (data: Any?) -> Void in self.socket.storeDataObjectGivenToCallback(data!) }
        let chan = pusher.subscribe("my-channel")
        let _ = chan.bind(eventName: "test-event", callback: callback)

        XCTAssertNil(socket.objectGivenToCallback)
        pusher.connection.handleEvent(eventName: "test-event", jsonObject: ["event": "test-event" as AnyObject, "channel": "my-channel" as AnyObject, "data": "{\"test\":\"test string\",\"and\":\"another\"}" as AnyObject])
        XCTAssertEqual(socket.objectGivenToCallback as? String, "{\"test\":\"test string\",\"and\":\"another\"}")
    }

    func testReceivingAnErrorWhereTheDataPartOfTheMessageIsNotDoubleEncoded() {
        let _ = pusher.bind({ (message: Any?) in
            if let message = message as? [String: AnyObject], let eventName = message["event"] as? String , eventName == "pusher:error" {
                if let data = message["data"] as? [String: AnyObject], let errorMessage = data["message"] as? String {
                    self.socket.appendToCallbackCheckString(errorMessage)
                }
            }
        })

        // pretend that we tried to subscribe to my-channel twice and got this error
        // back from Pusher
        pusher.connection.handleEvent(eventName: "pusher:error", jsonObject: ["event": "pusher:error" as AnyObject, "data": ["code": "<null>", "message": "Existing subscription to channel my-channel"] as AnyObject])

        XCTAssertNil(socket.objectGivenToCallback)
        pusher.connection.handleEvent(eventName: "test-event", jsonObject: ["event": "test-event" as AnyObject, "channel": "my-channel" as AnyObject, "data": "test" as AnyObject])
        XCTAssertEqual(socket.callbackCheckString, "Existing subscription to channel my-channel")
    }

    func testPassingIncomingMessagesToTheDebugLoggerIfOneIsSet() {
        let debugLogger = { (text: String) in
            if text.range(of: "websocketDidReceiveMessage") != nil {
                self.socket.appendToCallbackCheckString(text)
            }
        }
        pusher = Pusher(key: key)
        pusher.connection.debugLogger = debugLogger
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        pusher.connect()

        XCTAssertEqual(socket.callbackCheckString, "[PUSHER DEBUG] websocketDidReceiveMessage {\"event\":\"pusher:connection_established\",\"data\":\"{\\\"socket_id\\\":\\\"45481.3166671\\\",\\\"activity_timeout\\\":120}\"}")
    }
}

