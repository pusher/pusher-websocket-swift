import XCTest

@testable import PusherSwift

// swiftlint:disable unused_closure_parameter

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
        let ex = expectation(description: "Callback should be called")
        _ = pusher.subscribe(channelName: "my-channel")
        _ = pusher.bind { (_: Any?) -> Void in
            ex.fulfill()
        }

        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "stupid data"
        }
        """.removing(.newlines)
        pusher.connection.webSocketDidReceiveMessage(connection: socket, string: jsonDict)

        waitForExpectations(timeout: 0.5)
    }

    func testCallbacksOnRelevantChannelsShouldBeCalled() {
        let ex = expectation(description: "Callback should be called")
        let chan = pusher.subscribe("my-channel")
        _ = chan.bind(eventName: "test-event") { (_: Any?) -> Void in
            ex.fulfill()
        }

        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "stupid data"
        }
        """.removing(.newlines)
        pusher.connection.webSocketDidReceiveMessage(connection: socket, string: jsonDict)

        waitForExpectations(timeout: 0.5)
    }

    func testCallbacksOnRelevantChannelsAndGlobalChannelShouldBeCalled() {
        let globalEx = expectation(description: "Global callback should be called")
        let channelEx = expectation(description: "Channel callback should be called")

        let callback = { (data: Any?) -> Void in globalEx.fulfill() }
        _ = pusher.bind(callback)
        let chan = pusher.subscribe("my-channel")
        let callbackForChannel = { (data: Any?) -> Void in channelEx.fulfill() }
        _ = chan.bind(eventName: "test-event", callback: callbackForChannel)

        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "stupid data"
        }
        """.removing(.whitespacesAndNewlines)
        pusher.connection.webSocketDidReceiveMessage(connection: socket, string: jsonDict)

        waitForExpectations(timeout: 0.5)
    }

    func testGlobalCallbackReturnsEventData() {
        let ex = expectation(description: "Callback should be called")
        let callback = { (data: Any?) -> Void in
            XCTAssertEqual(data as! [String: String], ["event": "test-event", "channel": "my-channel", "data": "{\"test\":\"test string\",\"and\":\"another\"}"])
            ex.fulfill()
        }
        _ = pusher.subscribe("my-channel")
        _ = pusher.bind(callback)

        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}"
        }
        """.removing(.newlines)
        pusher.connection.webSocketDidReceiveMessage(connection: socket, string: jsonDict)

        waitForExpectations(timeout: 0.5)
    }

    /*
     The library has specific code for handling events without a channel name. But there is also specific code for handling
     `pusher:error`s and `connection_established` errors and those are the only events that don't have a channel name. Therefore
     it doesn't seem like that path will be used. However under Channels protocol, such an event is valid. That path can remain
     for now and the following test tests that functionality.
     */
    func testGlobalCallbackReturnsEventDataWithoutChannelName() {
        let ex = expectation(description: "Callback should be called")
        let callback = { (data: Any?) -> Void in
            XCTAssertEqual(data as! [String: String], ["event": "test-event", "data": "{\"test\":\"test string\",\"and\":\"another\"}"])
            ex.fulfill()
        }
        _ = pusher.subscribe("my-channel")
        _ = pusher.bind(callback)

        let jsonDict = """
        {
            "event": "test-event",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}"
        }
        """.removing(.newlines)
        pusher.connection.webSocketDidReceiveMessage(connection: socket, string: jsonDict)

        waitForExpectations(timeout: 0.5)
    }

    func testGlobalCallbackReturnsErrorData() {
        let ex = expectation(description: "Callback should be called")

        let callback = { (eventData: Any?) -> Void in
            guard let event = eventData as? [String: AnyObject] else {
                return XCTFail("Event not received")
            }

            guard let eventName = event["event"] as? String else {
                return XCTFail("No event name in event")
            }
            XCTAssertEqual(eventName, "pusher:error")

            guard let data = event["data"] as? [String: String] else {
                return XCTFail("No data in event")
            }
            XCTAssertEqual(data, ["code": "<null>", "message": "Existing subscription to channel my-channel"] as [String: String])
            ex.fulfill()
        }
        _ = pusher.bind(callback)

        let jsonDict = """
        {
            "event": "pusher:error",
            "channel": "my-channel",
            "data": {"code": "<null>", "message": "Existing subscription to channel my-channel"}
        }
        """.removing(.newlines)
        pusher.connection.webSocketDidReceiveMessage(connection: socket, string: jsonDict)

        waitForExpectations(timeout: 0.5)
    }

    func testReturningAJSONObjectToCallbacksIfTheStringCanBeParsed() {
        let ex = expectation(description: "Callback should be called")

        let callback = { (data: Any?) -> Void in
            XCTAssertEqual(data as! [String: String], ["test": "test string", "and": "another"])
            ex.fulfill()
        }

        let chan = pusher.subscribe("my-channel")
        _ = chan.bind(eventName: "test-event", callback: callback)

        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}"
        }
        """.removing(.newlines)
        pusher.connection.webSocketDidReceiveMessage(connection: socket, string: jsonDict)

        waitForExpectations(timeout: 0.5)
    }

    func testReturningAJSONStringToCallbacksIfTheStringCannotBeParsed() {
        let ex = expectation(description: "Callback should be called")

        let callback = { (data: Any?) -> Void in
            XCTAssertEqual(data as? String, "test")
            ex.fulfill()
        }

        let chan = pusher.subscribe("my-channel")
        _ = chan.bind(eventName: "test-event", callback: callback)

        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "test"
        }
        """.removing(.newlines)
        pusher.connection.webSocketDidReceiveMessage(connection: socket, string: jsonDict)

        waitForExpectations(timeout: 0.5)
    }

    func testReturningAJSONStringToCallbacksIfTheStringCanBeParsedButAttemptToReturnJSONObjectIsFalse() {
        let ex = expectation(description: "Callback should be called")

        let options = PusherClientOptions(attemptToReturnJSONObject: false)
        pusher = Pusher(key: key, options: options)
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        let callback = { (data: Any?) -> Void in
            XCTAssertEqual(data as? String, "{\"test\":\"test string\",\"and\":\"another\"}")
            ex.fulfill()
        }
        let chan = pusher.subscribe("my-channel")
        _ = chan.bind(eventName: "test-event", callback: callback)

        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}"
        }
        """.removing(.newlines)
        pusher.connection.webSocketDidReceiveMessage(connection: socket, string: jsonDict)

        waitForExpectations(timeout: 0.5)
    }

    func testReceivingAnErrorWhereTheDataPartOfTheMessageIsNotDoubleEncodedViaDataCallback() {
        let ex = expectation(description: "Callback should be called")

        _ = pusher.bind({ (message: Any?) in
            guard let message = message as? [String: AnyObject],
               let eventName = message["event"] as? String,
               eventName == "pusher:error",
               let data = message["data"] as? [String: AnyObject],
               let errorMessage = data["message"] as? String else {
                return
            }

            XCTAssertEqual(errorMessage, "Existing subscription to channel my-channel")
            ex.fulfill()
        })
        // pretend that we tried to subscribe to my-channel twice and got this error
        // back from Pusher
        let payload = "{\"event\":\"pusher:error\", \"data\":{\"message\":\"Existing subscription to channel my-channel\"}}"
        pusher.connection.webSocketDidReceiveMessage(connection: socket, string: payload)

        waitForExpectations(timeout: 0.5)
    }

    func testEventObjectReturnedToChannelCallback() {
        let ex = expectation(description: "Callback should be called")

        let callback = { (event: PusherEvent) -> Void in
            XCTAssertEqual(event.eventName, "test-event")
            XCTAssertEqual(event.channelName!, "my-channel")
            XCTAssertEqual(event.data!, "{\"test\":\"test string\",\"and\":\"another\"}")

            XCTAssertNil(event.userId)

            XCTAssertEqual(event.property(withKey: "event") as! String, "test-event")
            XCTAssertEqual(event.property(withKey: "channel") as! String, "my-channel")
            XCTAssertEqual(event.property(withKey: "data") as! String, "{\"test\":\"test string\",\"and\":\"another\"}")

            XCTAssertNil(event.property(withKey: "random-key"))

            ex.fulfill()
        }
        let chan = pusher.subscribe("my-channel")
        _ = chan.bind(eventName: "test-event", eventCallback: callback)

        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}"
        }
        """.removing(.newlines)
        pusher.connection.webSocketDidReceiveMessage(connection: socket, string: jsonDict)

        waitForExpectations(timeout: 0.5)
    }

    func testEventObjectReturnedToGlobalCallback() {
        let ex = expectation(description: "Callback should be called")

        let callback = { (event: PusherEvent) -> Void in
            XCTAssertEqual(event.eventName, "test-event")
            XCTAssertEqual(event.channelName!, "my-channel")
            XCTAssertEqual(event.data!, "{\"test\":\"test string\",\"and\":\"another\"}")

            XCTAssertNil(event.userId)

            XCTAssertEqual(event.property(withKey: "event") as! String, "test-event")
            XCTAssertEqual(event.property(withKey: "channel") as! String, "my-channel")
            XCTAssertEqual(event.property(withKey: "data") as! String, "{\"test\":\"test string\",\"and\":\"another\"}")

            XCTAssertNil(event.property(withKey: "random-key"))

            ex.fulfill()
        }
        _ = pusher.subscribe("my-channel")
        _ = pusher.bind(eventCallback: callback)

        XCTAssertNil(socket.eventGivenToCallback)
         let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}"
        }
        """.removing(.newlines)
        pusher.connection.webSocketDidReceiveMessage(connection: socket, string: jsonDict)

        waitForExpectations(timeout: 0.5)
    }
}
