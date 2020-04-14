import XCTest

#if WITH_ENCRYPTION
    @testable import PusherSwiftWithEncryption
#else
    @testable import PusherSwift
#endif

class PusherConcreteEventFactoryTests: XCTestCase {

    var eventFactory: PusherConcreteEventFactory!

    override func setUp() {
        eventFactory = PusherConcreteEventFactory()
    }

    func testChannelNameIsExtracted() {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}"
        }
        """.toJsonDict();

        let event = try! eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.channelName!, "my-channel")
        XCTAssertEqual(event.property(withKey: "channel") as! String, "my-channel")
    }

    func testEventNameIsExtracted() {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}"
        }
        """.toJsonDict();

        let event = try! eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.eventName, "test-event")
        XCTAssertEqual(event.property(withKey: "event") as! String, "test-event")
    }

    func testDataIsExtracted() {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}"
        }
        """.toJsonDict();

        let event = try! eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.data!, "{\"test\":\"test string\",\"and\":\"another\"}")
        XCTAssertEqual(event.property(withKey: "data") as! String, "{\"test\":\"test string\",\"and\":\"another\"}")
    }

    func testUserIdIsExtracted() {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}",
            "user_id":"user123"
        }
        """.toJsonDict();

        let event = try! eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.userId!, "user123")
        XCTAssertEqual(event.property(withKey: "user_id") as! String, "user123")
    }

    func testDoubleEncodedJsonDataIsParsed() {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}"
        }
        """.toJsonDict();

        let event = try! eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.data!, "{\"test\":\"test string\",\"and\":\"another\"}")
        XCTAssertEqual(event.dataToJSONObject() as! [String: String], ["test": "test string", "and": "another"] as [String: String])
    }

    func testDoubleEncodedArrayDataIsParsed() {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "[\\"test\\",\\\"and\\"]"
        }
        """.toJsonDict();

        let event = try! eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.data!, "[\"test\",\"and\"]")
        XCTAssertEqual(event.dataToJSONObject() as! [String], ["test", "and"] as [String])
    }

    func testIfDataStringCannotBeParsed() {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "test"
        }
        """.toJsonDict();

        let event = try! eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.data!, "test")
        XCTAssertNil(event.dataToJSONObject())
        XCTAssertEqual(event.property(withKey: "data") as! String, "test")
    }

    func testStringPropertyIsExtracted() {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}",
            "my_property": "string123"
        }
        """.toJsonDict();
        let event = try! eventFactory.makeEvent(fromJSON: jsonDict)
        XCTAssertEqual(event.property(withKey: "my_property") as! String, "string123")
    }

    func testIntegerPropertyIsExtracted() {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}",
            "my_integer": 1234567
        }
        """.toJsonDict();
        let event = try! eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.property(withKey: "my_integer") as! Int, 1234567)
    }

    func testBooleanPropertyIsExtracted() {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}",
            "my_boolean": true
        }
        """.toJsonDict();
        let event = try! eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.property(withKey: "my_boolean") as! Bool, true)
    }

    func testArrayPropertyIsExtracted() {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}",
            "my_array": [1, 2, 3]
        }
        """.toJsonDict();
        let event = try! eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.property(withKey: "my_array") as! [Int], [1, 2, 3])
    }

    func testObjectPropertyIsExtracted() {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}",
            "my_object": {"key": "value"}
        }
        """.toJsonDict();

        let event = try! eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.property(withKey: "my_object") as! [String: String], ["key": "value"])
    }

    func testNullPropertyIsExtracted() {
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": "{\\"test\\":\\"test string\\",\\"and\\":\\"another\\"}",
            "my_null": null
        }
        """.toJsonDict();

        let event = try! eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertTrue(event.property(withKey: "my_null") is NSNull)
    }

}
