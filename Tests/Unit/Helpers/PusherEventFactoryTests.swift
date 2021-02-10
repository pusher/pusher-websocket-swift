import XCTest

@testable import PusherSwift

class PusherEventFactoryTests: XCTestCase {

    private var eventFactory: PusherEventFactory!

    override func setUp() {
        eventFactory = PusherEventFactory()
    }

    func testChannelNameIsExtracted() throws {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}"
        }
        """.toJsonDict()

        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.channelName!, "my-channel")
        XCTAssertEqual(event.property(withKey: "channel") as! String, "my-channel")
    }

    func testEventNameIsExtracted() throws {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}"
        }
        """.toJsonDict()

        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.eventName, "test-event")
        XCTAssertEqual(event.property(withKey: "event") as! String, "test-event")
    }

    func testDataIsExtracted() throws {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}"
        }
        """.toJsonDict()

        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.data!, "{\"test\":\"test string\",\"and\":\"another\"}")
        XCTAssertEqual(event.property(withKey: "data") as! String, "{\"test\":\"test string\",\"and\":\"another\"}")
    }

    func testUserIdIsExtracted() throws {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}",
            "user_id":"user123"
        }
        """.toJsonDict()

        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.userId!, "user123")
        XCTAssertEqual(event.property(withKey: "user_id") as! String, "user123")
    }

    func testDoubleEncodedJsonDataIsParsed() throws {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}"
        }
        """.toJsonDict()

        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.data!, "{\"test\":\"test string\",\"and\":\"another\"}")
        XCTAssertEqual(event.dataToJSONObject() as! [String: String], ["test": "test string", "and": "another"] as [String: String])
    }

    func testDoubleEncodedArrayDataIsParsed() throws {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "[\\"test\\",\\\"and\\"]"
        }
        """.toJsonDict()

        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.data!, "[\"test\",\"and\"]")
        XCTAssertEqual(event.dataToJSONObject() as! [String], ["test", "and"] as [String])
    }

    func testIfDataStringCannotBeParsed() throws {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "test"
        }
        """.toJsonDict()

        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.data!, "test")
        XCTAssertNil(event.dataToJSONObject())
        XCTAssertEqual(event.property(withKey: "data") as! String, "test")
    }

    func testStringPropertyIsExtracted() throws {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}",
            "my_property": "string123"
        }
        """.toJsonDict()
        let event = try eventFactory.makeEvent(fromJSON: jsonDict)
        XCTAssertEqual(event.property(withKey: "my_property") as! String, "string123")
    }

    func testIntegerPropertyIsExtracted() throws {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}",
            "my_integer": 1234567
        }
        """.toJsonDict()
        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.property(withKey: "my_integer") as! Int, 1234567)
    }

    func testBooleanPropertyIsExtracted() throws {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}",
            "my_boolean": true
        }
        """.toJsonDict()
        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.property(withKey: "my_boolean") as! Bool, true)
    }

    func testArrayPropertyIsExtracted() throws {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}",
            "my_array": [1, 2, 3]
        }
        """.toJsonDict()
        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.property(withKey: "my_array") as! [Int], [1, 2, 3])
    }

    func testObjectPropertyIsExtracted() throws {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}",
            "my_object": {"key": "value"}
        }
        """.toJsonDict()

        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.property(withKey: "my_object") as! [String: String], ["key": "value"])
    }

    func testNullPropertyIsExtracted() throws {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}",
            "my_null": null
        }
        """.toJsonDict()

        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertTrue(event.property(withKey: "my_null") is NSNull)
    }

    func testInvalidMessageThrowsException() {
        let jsonDict = """
        {
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}"
        }
        """.toJsonDict()

        XCTAssertThrowsError(try eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: nil)) { error in
            XCTAssertEqual(error as? EventError, EventError.invalidFormat)
        }
    }
}
