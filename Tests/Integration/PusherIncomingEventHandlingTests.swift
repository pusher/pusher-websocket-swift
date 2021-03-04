import XCTest

@testable import PusherSwift

// swiftlint:disable unused_closure_parameter

class HandlingIncomingEventsTests: XCTestCase {
    private var key: String!
    private var pusher: Pusher!
    private var socket: MockWebSocket!

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
        pusher.bind { event in
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
        chan.bind(eventName: "test-event") { event in
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

        pusher.bind { event in
            globalEx.fulfill()
        }
        let chan = pusher.subscribe("my-channel")
        chan.bind(eventName: "test-event") { event in
            channelEx.fulfill()
        }

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
        _ = pusher.subscribe("my-channel")
        pusher.bind { event in
            XCTAssertEqual(event.channelName, "my-channel")
            XCTAssertEqual(event.eventName, "test-event")
            XCTAssertEqual(event.dataToJSONObject() as! [String: String], ["test": "test string", "and": "another"])
            ex.fulfill()
        }

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
        _ = pusher.subscribe("my-channel")
        pusher.bind { event in
            XCTAssertNil(event.channelName)
            XCTAssertEqual(event.eventName, "test-event")
            XCTAssertEqual(event.dataToJSONObject() as! [String: String], ["test": "test string", "and": "another"])
            ex.fulfill()
        }

        let jsonDict = """
        {
            "event": "test-event",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}"
        }
        """.removing(.newlines)
        pusher.connection.webSocketDidReceiveMessage(connection: socket, string: jsonDict)

        waitForExpectations(timeout: 0.5)
    }

    func testReturningAJSONObjectToCallbacksIfTheStringCanBeParsed() {
        let ex = expectation(description: "Callback should be called")

        let chan = pusher.subscribe("my-channel")
        chan.bind(eventName: "test-event") { event in
            event.dataToJSONObject() as! [String: String]
            XCTAssertEqual(event.dataToJSONObject() as! [String: String], ["test": "test string", "and": "another"])
            ex.fulfill()
        }

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

        let chan = pusher.subscribe("my-channel")
        chan.bind(eventName: "test-event") { event in
            XCTAssertEqual(event.data, "test")
            ex.fulfill()
        }

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
        let chan = pusher.subscribe("my-channel")
        chan.bind(eventName: "test-event") { event in
            XCTAssertEqual(event.data, "{\"test\":\"test string\",\"and\":\"another\"}")
            ex.fulfill()
        }

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

    func testEventObjectReturnedToChannelCallback() {
        let ex = expectation(description: "Callback should be called")

        let chan = pusher.subscribe("my-channel")
        chan.bind(eventName: "test-event") { event in
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

        _ = pusher.subscribe("my-channel")
        pusher.bind { event in
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
