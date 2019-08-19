@testable
import PusherSwift
import XCTest

class PusherEventTests: XCTestCase {
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

        let callback = { (event: PusherEvent) -> Void in self.socket.storeEventGivenToCallback(event) }
        let chan = pusher.subscribe("my-channel")
        let _ = chan.bind(eventName: "test-event", eventCallback: callback)
    }

    func testChannelNameIsExtracted() {
        let payload = "{\"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.")}

        XCTAssertEqual(event.channelName!, "my-channel")
        XCTAssertEqual(event.getProperty(name: "channel") as! String, "my-channel")
    }

    func testEventNameIsExtracted() {
        let payload = "{\"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.")}

        XCTAssertEqual(event.eventName, "test-event")
        XCTAssertEqual(event.getProperty(name: "event") as! String, "test-event")
    }

    func testDataIsExtracted() {
        let payload = "{\"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.")}

        XCTAssertEqual(event.data!, "{\"test\":\"test string\",\"and\":\"another\"}")
        XCTAssertEqual(event.getProperty(name: "data") as! String, "{\"test\":\"test string\",\"and\":\"another\"}")
    }

    func testUserIdIsExtracted() {
        let payload = "{\"user_id\":\"user123\", \"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.")}

        XCTAssertEqual(event.userId!, "user123")
        XCTAssertEqual(event.getProperty(name: "user_id") as! String, "user123")
    }

    func testDoubleEncodedJsonDataIsParsed() {
        let payload = "{\"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.")}

        XCTAssertEqual(event.data!, "{\"test\":\"test string\",\"and\":\"another\"}")
        XCTAssertEqual(event.dataAsJSON as! [String:String], ["test":"test string", "and":"another"] as [String:String])
    }

    func testDoubleEncodedArrayDataIsParsed() {
        let payload = "{\"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"[\\\"test\\\",\\\"and\\\"]\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.")}

        XCTAssertEqual(event.data!, "[\"test\",\"and\"]")
        XCTAssertEqual(event.dataAsJSON as! [String], ["test", "and"] as [String])
    }

    func testJsonEncodedDataIsParsed() {
        let payload = "{\"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":{\"test\":\"test string\",\"and\":\"another\"}}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.")}

        XCTAssertNil(event.data)
        XCTAssertEqual(event.dataAsJSON as! [String:String], ["test":"test string", "and":"another"] as [String:String])
    }

    func testIfDataStringCannotBeParsed() {
        let payload = "{\"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"test\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.")}

        XCTAssertEqual(event.data!, "test")
        XCTAssertNil(event.dataAsJSON)
        XCTAssertEqual(event.getProperty(name: "data") as! String, "test")
    }

    func testArrayEncodedDataIsParsed() {
        let payload = "{\"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":[\"test\",\"and\"]}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.")}

        XCTAssertNil(event.data)
        XCTAssertEqual(event.dataAsJSON as! [String], ["test", "and"] as [String])
    }

    func testStringPropertyIsExtracted() {
        let payload = "{\"my_property\":\"string123\", \"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.")}

        XCTAssertEqual(event.getProperty(name: "my_property") as! String, "string123")
    }

    func testIntegerPropertyIsExtracted() {
        let payload = "{\"my_integer\":1234567, \"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.")}

        XCTAssertEqual(event.getProperty(name: "my_integer") as! Int, 1234567)
    }

    func testBooleanPropertyIsExtracted() {
        let payload = "{\"my_boolean\":true, \"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.")}

        XCTAssertEqual(event.getProperty(name: "my_boolean") as! Bool, true)
    }

    func testArrayPropertyIsExtracted() {
        let payload = "{\"my_array\":[1,2,3], \"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.")}

        XCTAssertEqual(event.getProperty(name: "my_array") as! [Int], [1,2,3])
    }

    func testObjectPropertyIsExtracted() {
        let payload = "{\"my_object\":{\"key\":\"value\"}, \"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.")}

        XCTAssertEqual(event.getProperty(name: "my_object") as! [String:String], ["key":"value"])
    }

    func testNullPropertyIsExtracted() {
        let payload = "{\"my_null\":null, \"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.")}

        XCTAssertTrue(event.getProperty(name: "my_null") is NSNull)
    }

}
