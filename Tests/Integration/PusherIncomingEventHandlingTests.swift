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
        _ = pusher.subscribe(channelName: TestObjects.Event.testChannelName)
        pusher.bind { event in
            ex.fulfill()
        }

        pusher.connection.webSocketDidReceiveMessage(connection: socket,
                                                     string: TestObjects.Event.withJSON(data: "test"))

        waitForExpectations(timeout: 0.5)
    }

    func testCallbacksOnRelevantChannelsShouldBeCalled() {
        let ex = expectation(description: "Callback should be called")
        let chan = pusher.subscribe(TestObjects.Event.testChannelName)
        chan.bind(eventName: TestObjects.Event.testEventName) { event in
            ex.fulfill()
        }

        pusher.connection.webSocketDidReceiveMessage(connection: socket,
                                                     string: TestObjects.Event.withJSON(data: "test"))

        waitForExpectations(timeout: 0.5)
    }

    func testCallbacksOnRelevantChannelsAndGlobalChannelShouldBeCalled() {
        let globalEx = expectation(description: "Global callback should be called")
        let channelEx = expectation(description: "Channel callback should be called")

        pusher.bind { event in
            globalEx.fulfill()
        }
        let chan = pusher.subscribe(TestObjects.Event.testChannelName)
        chan.bind(eventName: TestObjects.Event.testEventName) { event in
            channelEx.fulfill()
        }

        pusher.connection.webSocketDidReceiveMessage(connection: socket,
                                                     string: TestObjects.Event.withJSON(data: "test"))

        waitForExpectations(timeout: 0.5)
    }

    func testGlobalCallbackReturnsEventData() {
        let ex = expectation(description: "Callback should be called")
        _ = pusher.subscribe(TestObjects.Event.testChannelName)
        pusher.bind { event in
            XCTAssertEqual(event.channelName, TestObjects.Event.testChannelName)
            XCTAssertEqual(event.eventName, TestObjects.Event.testEventName)
            XCTAssertEqual(event.dataToJSONObject() as! [String: String], TestObjects.Event.Data.unencryptedJSON.toJsonDict() as! [String: String])
            ex.fulfill()
        }

        pusher.connection.webSocketDidReceiveMessage(connection: socket,
                                                     string: TestObjects.Event.withJSON())

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
        _ = pusher.subscribe(TestObjects.Event.testChannelName)
        pusher.bind { event in
            XCTAssertNil(event.channelName)
            XCTAssertEqual(event.eventName, TestObjects.Event.testEventName)
            XCTAssertEqual(event.dataToJSONObject() as! [String: String], TestObjects.Event.Data.unencryptedJSON.toJsonDict() as! [String: String])
            ex.fulfill()
        }

        pusher.connection.webSocketDidReceiveMessage(connection: socket,
                                                     string: TestObjects.Event.withoutChannelNameJSON)

        waitForExpectations(timeout: 0.5)
    }

    func testReturningAJSONObjectToCallbacksIfTheStringCanBeParsed() {
        let ex = expectation(description: "Callback should be called")

        let chan = pusher.subscribe(TestObjects.Event.testChannelName)
        chan.bind(eventName: TestObjects.Event.testEventName) { event in
            XCTAssertEqual(event.dataToJSONObject() as! [String: String], TestObjects.Event.Data.unencryptedJSON.toJsonDict() as! [String: String])
            ex.fulfill()
        }

        pusher.connection.webSocketDidReceiveMessage(connection: socket,
                                                     string: TestObjects.Event.withJSON())

        waitForExpectations(timeout: 0.5)
    }

    func testReturningAJSONStringToCallbacksIfTheStringCannotBeParsed() {
        let ex = expectation(description: "Callback should be called")

        let chan = pusher.subscribe(TestObjects.Event.testChannelName)
        chan.bind(eventName: TestObjects.Event.testEventName) { event in
            XCTAssertEqual(event.data, "test")
            ex.fulfill()
        }

        pusher.connection.webSocketDidReceiveMessage(connection: socket,
                                                     string: TestObjects.Event.withJSON(data: "test"))

        waitForExpectations(timeout: 0.5)
    }

    func testReturningAJSONStringToCallbacksIfTheStringCanBeParsedButAttemptToReturnJSONObjectIsFalse() {
        let ex = expectation(description: "Callback should be called")

        let options = PusherClientOptions(attemptToReturnJSONObject: false)
        pusher = Pusher(key: key, options: options)
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        let chan = pusher.subscribe(TestObjects.Event.testChannelName)
        chan.bind(eventName: TestObjects.Event.testEventName) { event in
            XCTAssertEqual(event.data, TestObjects.Event.Data.unencryptedJSON.removing(.whitespacesAndNewlines))
            ex.fulfill()
        }

        pusher.connection.webSocketDidReceiveMessage(connection: socket,
                                                     string: TestObjects.Event.withJSON())

        waitForExpectations(timeout: 0.5)
    }

    func testEventObjectReturnedToChannelCallback() {
        let ex = expectation(description: "Callback should be called")

        let chan = pusher.subscribe(TestObjects.Event.testChannelName)
        chan.bind(eventName: TestObjects.Event.testEventName) { event in
            XCTAssertEqual(event.eventName, TestObjects.Event.testEventName)
            XCTAssertEqual(event.channelName!, TestObjects.Event.testChannelName)
            XCTAssertEqual(event.data!, TestObjects.Event.Data.unencryptedJSON.removing(.whitespacesAndNewlines))

            XCTAssertNil(event.userId)

            XCTAssertEqual(event.property(withKey: Constants.JSONKeys.event) as! String, TestObjects.Event.testEventName)
            XCTAssertEqual(event.property(withKey: Constants.JSONKeys.channel) as! String, TestObjects.Event.testChannelName)
            XCTAssertEqual(event.property(withKey: Constants.JSONKeys.data) as! String, TestObjects.Event.Data.unencryptedJSON.removing(.whitespacesAndNewlines))

            XCTAssertNil(event.property(withKey: "random-key"))

            ex.fulfill()
        }

        pusher.connection.webSocketDidReceiveMessage(connection: socket,
                                                     string: TestObjects.Event.withJSON())

        waitForExpectations(timeout: 0.5)
    }

    func testEventObjectReturnedToGlobalCallback() {
        let ex = expectation(description: "Callback should be called")

        _ = pusher.subscribe(TestObjects.Event.testChannelName)
        pusher.bind { event in
            XCTAssertEqual(event.eventName, TestObjects.Event.testEventName)
            XCTAssertEqual(event.channelName!, TestObjects.Event.testChannelName)
            XCTAssertEqual(event.data!, TestObjects.Event.Data.unencryptedJSON.removing(.whitespacesAndNewlines))

            XCTAssertNil(event.userId)

            XCTAssertEqual(event.property(withKey: Constants.JSONKeys.event) as! String, TestObjects.Event.testEventName)
            XCTAssertEqual(event.property(withKey: Constants.JSONKeys.channel) as! String, TestObjects.Event.testChannelName)
            XCTAssertEqual(event.property(withKey: Constants.JSONKeys.data) as! String, TestObjects.Event.Data.unencryptedJSON.removing(.whitespacesAndNewlines))

            XCTAssertNil(event.property(withKey: "random-key"))

            ex.fulfill()
        }

        XCTAssertNil(socket.eventGivenToCallback)
        pusher.connection.webSocketDidReceiveMessage(connection: socket,
                                                     string: TestObjects.Event.withJSON())

        waitForExpectations(timeout: 0.5)
    }
}
