@testable import PusherSwift
import XCTest

class ChannelEventFactoryDecryptionTests: XCTestCase {

    private var eventFactory: ChannelEventFactory!

    private let genericPusherEventName = "pusher:event"

    override func setUp() {
        eventFactory = ChannelEventFactory()
    }

    // MARK: Encryption related tests

    func test_init_unencryptedChannelAndUnencryptedPayload_returnsWithUnalteredPayload() {

        let jsonDict = TestObjects.Event.withJSON().toJsonDict()

        let event = try? eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertNotNil(event) { event in
            XCTAssertEqual(event.eventName, TestObjects.Event.testEventName)
            XCTAssertEqual(event.channelName, TestObjects.Event.testChannelName)
            XCTAssertEqual(event.data, TestObjects.Event.Data.unencryptedJSON.removing(.whitespacesAndNewlines))
        }
    }

    func test_init_unencryptedChannelAndEncryptedPayload_returnsWithUnalteredPayload() {

        let jsonDict = TestObjects.Event.withJSON(data: TestObjects.Event.Data.encryptedJSONTwo).toJsonDict()

        let event = try? eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertNotNil(event) { event in
            XCTAssertEqual(event.eventName, TestObjects.Event.testEventName)
            XCTAssertEqual(event.channelName, TestObjects.Event.testChannelName)
            XCTAssertEqual(event.data, TestObjects.Event.Data.encryptedJSONTwo.removing(.whitespacesAndNewlines))
        }
    }

    func test_init_encryptedChannelAndPusherEventAndUnencryptedPayload_returnsWithUnalteredPayload() {

        let jsonDict = TestObjects.Event.withJSON(name: genericPusherEventName,
                                   channel: TestObjects.Event.encryptedChannelName,
                                   data: TestObjects.Event.Data.unencryptedJSON).toJsonDict()

        let event = try? eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertNotNil(event) { event in
            XCTAssertEqual(event.eventName, genericPusherEventName)
            XCTAssertEqual(event.channelName, TestObjects.Event.encryptedChannelName)
            XCTAssertEqual(event.data, TestObjects.Event.Data.unencryptedJSON.removing(.whitespacesAndNewlines))
        }
    }

    func test_init_encryptedChannelAndPusherEventAndEncryptedPayload_returnsWithUnalteredPayload() {

        let jsonDict = TestObjects.Event.withJSON(name: genericPusherEventName,
                                                  channel: TestObjects.Event.encryptedChannelName,
                                                  data: TestObjects.Event.Data.encryptedJSONTwo).toJsonDict()

       let event = try? eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertNotNil(event) { event in
            XCTAssertEqual(event.eventName, genericPusherEventName)
            XCTAssertEqual(event.channelName, TestObjects.Event.encryptedChannelName)
            XCTAssertEqual(event.data, TestObjects.Event.Data.encryptedJSONTwo.removing(.whitespacesAndNewlines))
        }
    }

    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadWithNoDecryptionKey_throwsInvalidDecryptionKey() {

        let jsonDict = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                   channel: TestObjects.Event.encryptedChannelName,
                                   data: TestObjects.Event.Data.encryptedJSONTwo).toJsonDict()

        XCTAssertThrowsError(try eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: nil)) { error in
            XCTAssertEqual(error as? EventError, EventError.invalidDecryptionKey)
        }
    }

    func test_init_encryptedChannelAndUserEventAndUnencryptedPayloadWithNoDecryptionKey_throwsInvalidDecryptionKey() {

        let jsonDict = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                                  channel: TestObjects.Event.encryptedChannelName,
                                                  data: TestObjects.Event.Data.unencryptedJSON).toJsonDict()

        XCTAssertThrowsError(try eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: nil)) { error in
            XCTAssertEqual(error as? EventError, EventError.invalidDecryptionKey)
        }
    }

    func test_init_encryptedChannelAndUserEventAndUnencryptedPayloadWithDecryptionKey_throwsInvalidEncryptedData() {
        let decryptionKey = TestObjects.Event.Data.validDecryptionKey

        let jsonDict = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                                  channel: TestObjects.Event.encryptedChannelName,
                                                  data: TestObjects.Event.Data.unencryptedJSON)
                           .toJsonDict()

        XCTAssertThrowsError(try eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: decryptionKey)) { error in
            XCTAssertEqual(error as? EventError, EventError.invalidEncryptedData)
        }
    }

    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadMissingNonce_throwsInvalidEncryptedData() {
        let decryptionKey = TestObjects.Event.Data.validDecryptionKey

        let jsonDict = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                                  channel: TestObjects.Event.encryptedChannelName,
                                                  data: TestObjects.Event.Data.missingNonceJSON)
                           .toJsonDict()

        XCTAssertThrowsError(try eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: decryptionKey)) { error in
            XCTAssertEqual(error as? EventError, EventError.invalidEncryptedData)
        }
    }

    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadMissingCiphertext_throwsInvalidEncryptedData() {
        let decryptionKey = TestObjects.Event.Data.validDecryptionKey

        let jsonDict = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                                  channel: TestObjects.Event.encryptedChannelName,
                                                  data: TestObjects.Event.Data.missingCiphertextJSON)
            .toJsonDict()

        XCTAssertThrowsError(try eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: decryptionKey)) { error in
            XCTAssertEqual(error as? EventError, EventError.invalidEncryptedData)
        }
    }

    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadAndValidKey_returnsWithDecryptedPayload() {

        let decryptionKey = TestObjects.Event.Data.validDecryptionKey

        let jsonDict = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                                  channel: TestObjects.Event.encryptedChannelName,
                                                  data: TestObjects.Event.Data.encryptedJSONTwo).toJsonDict()

        let event = try? eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: decryptionKey)

        let expectedDecryptedPayload = TestObjects.Event.Data.decryptedJSONTwo.removing(.whitespacesAndNewlines)

        XCTAssertNotNil(event) { event in
            XCTAssertEqual(event.eventName, TestObjects.Event.userEventName)
            XCTAssertEqual(event.channelName, TestObjects.Event.encryptedChannelName)
            XCTAssertEqual(event.data, expectedDecryptedPayload)
        }
    }

    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadButBadKey_throwsInvalidDecryptionKey() {

        let decryptionKey = TestObjects.Event.Data.badDecryptionKey

        let jsonDict = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                                  channel: TestObjects.Event.encryptedChannelName,
                                                  data: TestObjects.Event.Data.encryptedJSONTwo).toJsonDict()

        XCTAssertThrowsError(try eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: decryptionKey)) { error in
            XCTAssertEqual(error as? EventError, EventError.invalidDecryptionKey)
        }
    }

    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadButBadNonce_throwsInvalidDecryptionKey() {

        let decryptionKey = TestObjects.Event.Data.validDecryptionKey

        let jsonDict = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                                  channel: TestObjects.Event.encryptedChannelName,
                                                  data: TestObjects.Event.Data.badNonceJSON).toJsonDict()

        XCTAssertThrowsError(try eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: decryptionKey)) { error in
            XCTAssertEqual(error as? EventError, EventError.invalidDecryptionKey)
        }
    }

    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadButBadCiphertext_throwsInvalidDecryptionKey() {

        let decryptionKey = TestObjects.Event.Data.validDecryptionKey

        let jsonDict = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                                  channel: TestObjects.Event.encryptedChannelName,
                                                  data: TestObjects.Event.Data.badCiphertextJSON).toJsonDict()

        XCTAssertThrowsError(try eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: decryptionKey)) { error in
            XCTAssertEqual(error as? EventError, EventError.invalidDecryptionKey)
        }
    }
}
