import XCTest

#if WITH_ENCRYPTION
    @testable import PusherSwiftWithEncryption
#else
    @testable import PusherSwift
#endif

class HandlingIncomingEventsTests: XCTestCase {
    var key: String!
    var pusher: Pusher!
    var socket: MockWebSocket!
    var eventFactory = PusherConcreteEventFactory()

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

        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "stupid data"
        }
        """.toJsonDict()
        let pusherEvent = try? eventFactory.makeEvent(fromJSON: jsonDict)

        pusher.connection.handleEvent(event: pusherEvent!)
        XCTAssertEqual(socket.callbackCheckString, "testingIWasCalled")
    }

    func testCallbacksOnRelevantChannelsShouldBeCalled() {
        let callback = { (data: Any?) -> Void in self.socket.appendToCallbackCheckString("channelCallbackCalled") }
        let chan = pusher.subscribe("my-channel")
        let _ = chan.bind(eventName: "test-event", callback: callback)

        XCTAssertEqual(socket.callbackCheckString, "")
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "stupid data"
        }
        """.toJsonDict()
        let pusherEvent = try? eventFactory.makeEvent(fromJSON: jsonDict)
        pusher.connection.handleEvent(event: pusherEvent!)
        XCTAssertEqual(socket.callbackCheckString, "channelCallbackCalled")
    }

    func testCallbacksOnRelevantChannelsAndGlobalChannelShouldBeCalled() {
        let callback = { (data: Any?) -> Void in self.socket.appendToCallbackCheckString("globalCallbackCalled") }
        let _ = pusher.bind(callback)
        let chan = pusher.subscribe("my-channel")
        let callbackForChannel = { (data: Any?) -> Void in self.socket.appendToCallbackCheckString("channelCallbackCalled") }
        let _ = chan.bind(eventName: "test-event", callback: callbackForChannel)

        XCTAssertEqual(socket.callbackCheckString, "")
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "stupid data"
        }
        """.toJsonDict()
        let pusherEvent = try? eventFactory.makeEvent(fromJSON: jsonDict)
        pusher.connection.handleEvent(event: pusherEvent!)
        XCTAssertEqual(socket.callbackCheckString, "globalCallbackCalledchannelCallbackCalled")
    }

    func testGlobalCallbackReturnsEventData() {
        let callback = { (data: Any?) -> Void in self.socket.storeDataObjectGivenToCallback(data!) }
        let _ = pusher.subscribe("my-channel")
        let _ = pusher.bind(callback)

        XCTAssertNil(socket.objectGivenToCallback)
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\"test\":\"test string\",\"and\":\"another\"}"
        }
        """.toJsonDict()
        let pusherEvent = try? eventFactory.makeEvent(fromJSON: jsonDict)
        pusher.connection.handleEvent(event: pusherEvent!)
        XCTAssertEqual(socket.objectGivenToCallback as! [String: String], ["event": "test-event", "channel": "my-channel", "data": "{\"test\":\"test string\",\"and\":\"another\"}"])
    }

    /*
     The library has specific code for handling events without a channel name. But there is also specific code for handling
     `pusher:error`s and `connection_established` errors and those are the only events that don't have a channel name. Therefore
     it doesn't seem like that path will be used. However under Channels protocol, such an event is valid. That path can remain
     for now and the following test tests that functionality.
     */
    func testGlobalCallbackReturnsEventDataWithoutChannelName() {
        let callback = { (data: Any?) -> Void in self.socket.storeDataObjectGivenToCallback(data!) }
        let _ = pusher.subscribe("my-channel")
        let _ = pusher.bind(callback)

        XCTAssertNil(socket.objectGivenToCallback)
        let jsonDict = """
        {
            "event": "test-event",
            "data": "{\"test\":\"test string\",\"and\":\"another\"}"
        }
        """.toJsonDict()
        let pusherEvent = try? eventFactory.makeEvent(fromJSON: jsonDict)
        pusher.connection.handleEvent(event: pusherEvent!)
        XCTAssertEqual(socket.objectGivenToCallback as! [String: String], ["event": "test-event", "data": "{\"test\":\"test string\",\"and\":\"another\"}"])
    }

    func testGlobalCallbackReturnsErrorData() {
        let callback = { (data: Any?) -> Void in self.socket.storeDataObjectGivenToCallback(data!) }
        let _ = pusher.bind(callback)

        XCTAssertNil(socket.objectGivenToCallback)
        let jsonDict = """
        {
            "event": "pusher:error",
            "channel": "my-channel",
            "data": ["code": "<null>", "message": "Existing subscription to channel my-channel"]
        }
        """.toJsonDict()
        let pusherEvent = try? eventFactory.makeEvent(fromJSON: jsonDict)
        pusher.connection.handleEvent(event: pusherEvent!)

        guard let event = socket.objectGivenToCallback as? [String: AnyObject] else {
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
    }

    func testReturningAJSONObjectToCallbacksIfTheStringCanBeParsed() {
        let callback = { (data: Any?) -> Void in self.socket.storeDataObjectGivenToCallback(data!) }
        let chan = pusher.subscribe("my-channel")
        let _ = chan.bind(eventName: "test-event", callback: callback)

        XCTAssertNil(socket.objectGivenToCallback)

        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\"test\":\"test string\",\"and\":\"another\"}"
        }
        """.toJsonDict()
        let pusherEvent = try? eventFactory.makeEvent(fromJSON: jsonDict)
        pusher.connection.handleEvent(event: pusherEvent!)
        XCTAssertEqual(socket.objectGivenToCallback as! [String: String], ["test": "test string", "and": "another"])
    }

    func testReturningAJSONStringToCallbacksIfTheStringCannotBeParsed() {
        let callback = { (data: Any?) -> Void in self.socket.storeDataObjectGivenToCallback(data!) }
        let chan = pusher.subscribe("my-channel")
        let _ = chan.bind(eventName: "test-event", callback: callback)

        XCTAssertNil(socket.objectGivenToCallback)
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "test"
        }
        """.toJsonDict()
        let pusherEvent = try? eventFactory.makeEvent(fromJSON: jsonDict)
        pusher.connection.handleEvent(event: pusherEvent!)
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
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\"test\":\"test string\",\"and\":\"another\"}"
        }
        """.toJsonDict()
        let pusherEvent = try? eventFactory.makeEvent(fromJSON: jsonDict)
        pusher.connection.handleEvent(event: pusherEvent!)
        XCTAssertEqual(socket.objectGivenToCallback as? String, "{\"test\":\"test string\",\"and\":\"another\"}")
    }

    func testReceivingAnErrorWhereTheDataPartOfTheMessageIsNotDoubleEncodedViaDataCallback() {
        let _ = pusher.bind({ (message: Any?) in
            if let message = message as? [String: AnyObject], let eventName = message["event"] as? String, eventName == "pusher:error" {
                if let data = message["data"] as? [String: AnyObject], let errorMessage = data["message"] as? String {
                    self.socket.appendToCallbackCheckString(errorMessage)
                }
            }
        })
        // pretend that we tried to subscribe to my-channel twice and got this error
        // back from Pusher

        let payload = "{\"event\":\"pusher:error\", \"data\":{\"message\":\"Existing subscription to channel my-channel\"}}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        XCTAssertEqual(socket.callbackCheckString, "Existing subscription to channel my-channel")
    }

    func testEventObjectReturnedToChannelCallback() {
        let callback = { (event: PusherEvent) -> Void in self.socket.storeEventGivenToCallback(event) }
        let chan = pusher.subscribe("my-channel")
        let _ = chan.bind(eventName: "test-event", eventCallback: callback)

        XCTAssertNil(socket.eventGivenToCallback)
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\"test\":\"test string\",\"and\":\"another\"}"
        }
        """.toJsonDict()
        let pusherEvent = try? eventFactory.makeEvent(fromJSON: jsonDict)
        pusher.connection.handleEvent(event: pusherEvent!)

        guard let event = socket.eventGivenToCallback else {
            return XCTFail("Event not received.")
        }

        XCTAssertEqual(event.eventName, "test-event")
        XCTAssertEqual(event.channelName!, "my-channel")
        XCTAssertEqual(event.data!, "{\"test\":\"test string\",\"and\":\"another\"}")

        XCTAssertNil(event.userId)

        XCTAssertEqual(event.property(withKey: "event") as! String, "test-event")
        XCTAssertEqual(event.property(withKey: "channel") as! String, "my-channel")
        XCTAssertEqual(event.property(withKey: "data") as! String, "{\"test\":\"test string\",\"and\":\"another\"}")

        XCTAssertNil(event.property(withKey: "random-key"))
    }

    func testEventObjectReturnedToGlobalCallback() {
        let callback = { (event: PusherEvent) -> Void in self.socket.storeEventGivenToCallback(event) }
        let _ = pusher.subscribe("my-channel")
        let _ = pusher.bind(eventCallback: callback)

        XCTAssertNil(socket.eventGivenToCallback)
         let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\"test\":\"test string\",\"and\":\"another\"}"
        }
        """.toJsonDict()
        let pusherEvent = try? eventFactory.makeEvent(fromJSON: jsonDict)
        pusher.connection.handleEvent(event: pusherEvent!)

        guard let event = socket.eventGivenToCallback else {
            return XCTFail("Event not received.")
        }

        XCTAssertEqual(event.eventName, "test-event")
        XCTAssertEqual(event.channelName!, "my-channel")
        XCTAssertEqual(event.data!, "{\"test\":\"test string\",\"and\":\"another\"}")

        XCTAssertNil(event.userId)

        XCTAssertEqual(event.property(withKey: "event") as! String, "test-event")
        XCTAssertEqual(event.property(withKey: "channel") as! String, "my-channel")
        XCTAssertEqual(event.property(withKey: "data") as! String, "{\"test\":\"test string\",\"and\":\"another\"}")

        XCTAssertNil(event.property(withKey: "random-key"))
    }
}
