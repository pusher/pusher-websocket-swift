@testable import PusherSwift
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
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.") }

        XCTAssertEqual(event.channelName!, "my-channel")
        XCTAssertEqual(event.property(withKey: "channel") as! String, "my-channel")
    }

    func testEventNameIsExtracted() {
        let payload = "{\"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.") }

        XCTAssertEqual(event.eventName, "test-event")
        XCTAssertEqual(event.property(withKey: "event") as! String, "test-event")
    }

    func testDataIsExtracted() {
        let payload = "{\"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.") }

        XCTAssertEqual(event.data!, "{\"test\":\"test string\",\"and\":\"another\"}")
        XCTAssertEqual(event.property(withKey: "data") as! String, "{\"test\":\"test string\",\"and\":\"another\"}")
    }

    func testUserIdIsExtracted() {
        let payload = "{\"user_id\":\"user123\", \"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.") }

        XCTAssertEqual(event.userId!, "user123")
        XCTAssertEqual(event.property(withKey: "user_id") as! String, "user123")
    }

    func testDoubleEncodedJsonDataIsParsed() {
        let payload = "{\"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.") }

        XCTAssertEqual(event.data!, "{\"test\":\"test string\",\"and\":\"another\"}")
        XCTAssertEqual(event.dataToJSONObject() as! [String: String], ["test": "test string", "and": "another"] as [String: String])
    }

    func testDoubleEncodedArrayDataIsParsed() {
        let payload = "{\"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"[\\\"test\\\",\\\"and\\\"]\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.") }

        XCTAssertEqual(event.data!, "[\"test\",\"and\"]")
        XCTAssertEqual(event.dataToJSONObject() as! [String], ["test", "and"] as [String])
    }

    func testIfDataStringCannotBeParsed() {
        let payload = "{\"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"test\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.") }

        XCTAssertEqual(event.data!, "test")
        XCTAssertNil(event.dataToJSONObject())
        XCTAssertEqual(event.property(withKey: "data") as! String, "test")
    }

    func testStringPropertyIsExtracted() {
        let payload = "{\"my_property\":\"string123\", \"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.") }

        XCTAssertEqual(event.property(withKey: "my_property") as! String, "string123")
    }

    func testIntegerPropertyIsExtracted() {
        let payload = "{\"my_integer\":1234567, \"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.") }

        XCTAssertEqual(event.property(withKey: "my_integer") as! Int, 1234567)
    }

    func testBooleanPropertyIsExtracted() {
        let payload = "{\"my_boolean\":true, \"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.") }

        XCTAssertEqual(event.property(withKey: "my_boolean") as! Bool, true)
    }

    func testArrayPropertyIsExtracted() {
        let payload = "{\"my_array\":[1,2,3], \"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.") }

        XCTAssertEqual(event.property(withKey: "my_array") as! [Int], [1, 2, 3])
    }

    func testObjectPropertyIsExtracted() {
        let payload = "{\"my_object\":{\"key\":\"value\"}, \"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.") }

        XCTAssertEqual(event.property(withKey: "my_object") as! [String: String], ["key": "value"])
    }

    func testNullPropertyIsExtracted() {
        let payload = "{\"my_null\":null, \"event\":\"test-event\", \"channel\":\"my-channel\", \"data\":\"{\\\"test\\\":\\\"test string\\\",\\\"and\\\":\\\"another\\\"}\"}";
        pusher.connection.websocketDidReceiveMessage(socket: socket, text: payload)
        guard let event = socket.eventGivenToCallback else { return XCTFail("Event not received.") }

        XCTAssertTrue(event.property(withKey: "my_null") is NSNull)
    }

    // MARK: Encryption related tests
    
    func test_init_unencryptedChannelAndUnencryptedPayload_returnsWithUnalteredPayload() {
        
        let dataPayload = """
        {
            "test": "test string",
            "and": "another"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()
        
        let sut = PusherEvent(jsonObject: jsonDict, keyProvider: DummyPusherKeyProvider())
        
        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "test-event")
            XCTAssertEqual(sut.channelName, "my-channel")
            XCTAssertEqual(sut.data, dataPayload)
        }
        
    }
    
    func test_init_unencryptedChannelAndEncryptedPayload_returnsWithUnalteredPayload() {
        
        let dataPayload = """
        {
            "nonce": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm",
            "ciphertext": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()
        
        let sut = PusherEvent(jsonObject: jsonDict, keyProvider: DummyPusherKeyProvider())
        
        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "test-event")
            XCTAssertEqual(sut.channelName, "my-channel")
            XCTAssertEqual(sut.data, dataPayload)
        }
        
    }
    
    func test_init_encryptedChannelAndPusherEventAndUnencryptedPayload_returnsWithUnalteredPayload() {
        
        let dataPayload = """
        {
            "test": "test string",
            "and": "another"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "pusher:event",
            "channel": "private-encrypted-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()
        
        let sut = PusherEvent(jsonObject: jsonDict, keyProvider: DummyPusherKeyProvider())
        
        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "pusher:event")
            XCTAssertEqual(sut.channelName, "private-encrypted-channel")
            XCTAssertEqual(sut.data, dataPayload)
        }
    }
    
    
    func test_init_encryptedChannelAndPusherEventAndEncryptedPayload_returnsWithUnalteredPayload() {
        
        let dataPayload = """
        {
            "nonce": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm",
            "ciphertext": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "pusher:event",
            "channel": "private-encrypted-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()
        
        let sut = PusherEvent(jsonObject: jsonDict, keyProvider: DummyPusherKeyProvider())
        
        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "pusher:event")
            XCTAssertEqual(sut.channelName, "private-encrypted-channel")
            XCTAssertEqual(sut.data, dataPayload)
        }
    }
    
    func test_init_encryptedChannelAndUserEventAndUnencryptedPayload_returnsWithNilPayload() {
        
        let dataPayload = """
        {
            "test": "test string",
            "and": "another"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "user-event",
            "channel": "private-encrypted-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()
        
        let sut = PusherEvent(jsonObject: jsonDict, keyProvider: DummyPusherKeyProvider())
        
        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "user-event")
            XCTAssertEqual(sut.channelName, "private-encrypted-channel")
            XCTAssertEqual(sut.data, nil)
        }
    }
    
    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadAndValidKey_returnsWithDecryptedPayload() {
        
        let keyProvider = PusherKeyProvider(decryptionKey: "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs=")
        
        let dataPayload = """
        {
            "nonce": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm",
            "ciphertext": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "user-event",
            "channel": "private-encrypted-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()
        
        let sut = PusherEvent(jsonObject: jsonDict, keyProvider: keyProvider)
        
        let expectedDecryptedPayload = """
        {
            "name": "freddy",
            "message": "hello"
        }
        """.removing(.whitespacesAndNewlines)
        
        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "user-event")
            XCTAssertEqual(sut.channelName, "private-encrypted-channel")
            XCTAssertEqual(sut.data, expectedDecryptedPayload)
        }
    }
    
    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadButBadKey_returnsWithNilPayload() {
        
        let keyProvider = PusherKeyProvider(decryptionKey: "00000000000000000000000000000000000000000000")
        
        let dataPayload = """
        {
            "nonce": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm",
            "ciphertext": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "user-event",
            "channel": "private-encrypted-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()
        
        let sut = PusherEvent(jsonObject: jsonDict, keyProvider: keyProvider)
        
        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "user-event")
            XCTAssertEqual(sut.channelName, "private-encrypted-channel")
            XCTAssertEqual(sut.data, nil)
        }
    }
    
    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadButBadNonce_returnsWithNilPayload() {
        
        let keyProvider = PusherKeyProvider(decryptionKey: "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs=")
        
        let dataPayload = """
        {
            "nonce": "00000000000000000000000000000000",
            "ciphertext": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "user-event",
            "channel": "private-encrypted-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()
        
        let sut = PusherEvent(jsonObject: jsonDict, keyProvider: keyProvider)
        
        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "user-event")
            XCTAssertEqual(sut.channelName, "private-encrypted-channel")
            XCTAssertEqual(sut.data, nil)
        }
    }
    
    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadButBadCiphertext_returnsWithNilPayload() {
        
        let keyProvider = PusherKeyProvider(decryptionKey: "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs=")
        
        let dataPayload = """
        {
            "nonce": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm",
            "ciphertext": "00000000000000000000000000000000000000000000000000000000000000000000"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "user-event",
            "channel": "private-encrypted-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()
        
        let sut = PusherEvent(jsonObject: jsonDict, keyProvider: keyProvider)
        
        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "user-event")
            XCTAssertEqual(sut.channelName, "private-encrypted-channel")
            XCTAssertEqual(sut.data, nil)
        }
    }
    
}
