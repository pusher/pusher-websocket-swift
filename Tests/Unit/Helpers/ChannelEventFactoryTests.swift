import XCTest

@testable import PusherSwift

class ChannelEventFactoryTests: XCTestCase {

    private var eventFactory: ChannelEventFactory!

    override func setUp() {
        eventFactory = ChannelEventFactory()
    }

    func testChannelNameIsExtracted() throws {
        let event = try eventFactory.makeEvent(fromJSON: TestObjects.Event.withJSON().toJsonDict())

        XCTAssertEqual(event.channelName!, TestObjects.Event.testChannelName)
        XCTAssertEqual(event.property(withKey: Constants.JSONKeys.channel) as! String, TestObjects.Event.testChannelName)
    }

    func testEventNameIsExtracted() throws {
        let event = try eventFactory.makeEvent(fromJSON: TestObjects.Event.withJSON().toJsonDict())

        XCTAssertEqual(event.eventName, TestObjects.Event.testEventName)
        XCTAssertEqual(event.property(withKey: Constants.JSONKeys.event) as! String, TestObjects.Event.testEventName)
    }

    func testDataIsExtracted() throws {
        let event = try eventFactory.makeEvent(fromJSON: TestObjects.Event.withJSON().toJsonDict())

        XCTAssertEqual(event.data!, TestObjects.Event.Data.unencryptedJSON.removing(.whitespacesAndNewlines))
        XCTAssertEqual(event.property(withKey: Constants.JSONKeys.data) as! String, TestObjects.Event.Data.unencryptedJSON.removing(.whitespacesAndNewlines))
    }

    func testUserIdIsExtracted() throws {
        let userIDValue = "user123"
        let event = try eventFactory.makeEvent(fromJSON: TestObjects.Event.withJSON(customKeyValuePair: (Constants.JSONKeys.userId, userIDValue)).toJsonDict())

        XCTAssertEqual(event.userId!, userIDValue)
        XCTAssertEqual(event.property(withKey: Constants.JSONKeys.userId) as! String, userIDValue)
    }

    func testDoubleEncodedJsonDataIsParsed() throws {
        let event = try eventFactory.makeEvent(fromJSON: TestObjects.Event.withJSON().toJsonDict())

        XCTAssertEqual(event.data!, TestObjects.Event.Data.unencryptedJSON.removing(.whitespacesAndNewlines))
        XCTAssertEqual(event.dataToJSONObject() as! [String: String], TestObjects.Event.Data.unencryptedJSON.toJsonDict() as! [String: String])
    }

    func testDoubleEncodedArrayDataIsParsed() throws {
        let jsonDict = TestObjects.Event.withJSON(data: "[\"test\",\"and\"]").toJsonDict()

        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.data!, "[\"test\",\"and\"]")
        XCTAssertEqual(event.dataToJSONObject() as! [String], ["test", "and"] as [String])
    }

    func testIfDataStringCannotBeParsed() throws {
        let jsonDict = TestObjects.Event.withJSON(data: "test").toJsonDict()

        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.data!, "test")
        XCTAssertNil(event.dataToJSONObject())
        XCTAssertEqual(event.property(withKey: Constants.JSONKeys.data) as! String, "test")
    }

    func testStringPropertyIsExtracted() throws {
        let propertyKey = "my_property"
        let propertyValue = "string123"
        let jsonDict = TestObjects.Event.withJSON(customKeyValuePair: (propertyKey, propertyValue)).toJsonDict()
        let event = try eventFactory.makeEvent(fromJSON: jsonDict)
        XCTAssertEqual(event.property(withKey: propertyKey) as! String, propertyValue)
    }

    func testIntegerPropertyIsExtracted() throws {
        let propertyKey = "my_integer"
        let propertyValue = 1234567
        let jsonDict = TestObjects.Event.withJSON(customKeyValuePair: (propertyKey, propertyValue)).toJsonDict()
        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.property(withKey: propertyKey) as! Int, propertyValue)
    }

    func testBooleanPropertyIsExtracted() throws {
        let propertyKey = "my_boolean"
        let propertyValue = true
        let jsonDict = TestObjects.Event.withJSON(customKeyValuePair: (propertyKey, propertyValue)).toJsonDict()
        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.property(withKey: propertyKey) as! Bool, propertyValue)
    }

    func testArrayPropertyIsExtracted() throws {
        let propertyKey = "my_array"
        let propertyValue = [1, 2, 3]
        let jsonDict = TestObjects.Event.withJSON(customKeyValuePair: (propertyKey, propertyValue)).toJsonDict()
        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.property(withKey: propertyKey) as! [Int], propertyValue)
    }

    func testObjectPropertyIsExtracted() throws {
        let propertyKey = "my_object"
        let propertyValue = ["key": "value"]
        let jsonDict = TestObjects.Event.withJSON(customKeyValuePair: (propertyKey, propertyValue)).toJsonDict()

        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertEqual(event.property(withKey: propertyKey) as! [String: String], propertyValue)
    }

    func testNullPropertyIsExtracted() throws {
        let propertyKey = "my_null"
        let propertyValue = NSNull()
        let jsonDict = TestObjects.Event.withJSON(customKeyValuePair: (propertyKey, propertyValue)).toJsonDict()

        let event = try eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertTrue(event.property(withKey: propertyKey) is NSNull)
    }

    func testInvalidMessageThrowsException() {
        let jsonDict = TestObjects.Event.withoutEventNameJSON.toJsonDict()

        XCTAssertThrowsError(try eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: nil)) { error in
            XCTAssertEqual(error as? EventError, EventError.invalidFormat)
        }
    }
}
