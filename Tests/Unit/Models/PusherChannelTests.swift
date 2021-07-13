import XCTest

@testable import PusherSwift

class PusherChannelTests: XCTestCase {
    private var chan: PusherChannel!

    override func setUp() {
        super.setUp()

        chan = PusherChannel(name: TestObjects.Event.testChannelName, connection: MockPusherConnection())
    }

    func testANewChannelGetsCreatedWithTheCorrectNameAndNoCallbacks() {
        let chan = PusherChannel(name: TestObjects.Event.testChannelName, connection: MockPusherConnection())
        XCTAssertEqual(chan.name, TestObjects.Event.testChannelName, "the channel name should be \(TestObjects.Event.testChannelName)")
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no callbacks")
    }

    func testBindingACallbackToAChannelForAGivenEventName() {
        let chan = PusherChannel(name: TestObjects.Event.testChannelName, connection: MockPusherConnection())
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no callbacks")
        chan.bind(eventName: TestObjects.Event.testEventName) { _ in }
        XCTAssertEqual(chan.eventHandlers[TestObjects.Event.testEventName]?.count, 1, "the channel should have one callback")
    }

    func testUnbindingAnEventCallbackForAGivenEventNameAndCallbackId() {
        let chan = PusherChannel(name: TestObjects.Event.testChannelName, connection: MockPusherConnection())
        XCTAssertNil(chan.eventHandlers[TestObjects.Event.testEventName], "the channel should have no callbacks for event \"\(TestObjects.Event.testEventName)\"")
        let idOne = chan.bind(eventName: TestObjects.Event.testEventName) { _ in }
        chan.bind(eventName: TestObjects.Event.testEventName) { _ in }
        XCTAssertEqual(chan.eventHandlers[TestObjects.Event.testEventName]?.count, 2, "the channel should have two callbacks for event \"\(TestObjects.Event.testEventName)\"")
        chan.unbind(eventName: TestObjects.Event.testEventName, callbackId: idOne)
        XCTAssertEqual(chan.eventHandlers[TestObjects.Event.testEventName]?.count, 1, "the channel should have one callback for event \"\(TestObjects.Event.testEventName)\"")
    }

    func testUnbindingAllCallbacksForAGivenEventName() {
        let chan = PusherChannel(name: TestObjects.Event.testChannelName, connection: MockPusherConnection())
        XCTAssertNil(chan.eventHandlers[TestObjects.Event.testEventName], "the channel should have no callbacks for event \"\(TestObjects.Event.testEventName)\"")
        chan.bind(eventName: TestObjects.Event.testEventName) { _ in }
        chan.bind(eventName: TestObjects.Event.testEventName) { _ in }
        XCTAssertEqual(chan.eventHandlers[TestObjects.Event.testEventName]?.count, 2, "the channel should have two callbacks for event \"\(TestObjects.Event.testEventName)\"")
        chan.unbindAll(forEventName: TestObjects.Event.testEventName)
        XCTAssertEqual(chan.eventHandlers[TestObjects.Event.testEventName]?.count, 0, "the channel should have no callbacks for event \"\(TestObjects.Event.testEventName)\"")
    }

    func testUnbindingAllCallbacksForAGivenChannel() {
        let chan = PusherChannel(name: TestObjects.Event.testChannelName, connection: MockPusherConnection())
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no callbacks")
        chan.bind(eventName: TestObjects.Event.testEventName) { _ in }
        chan.bind(eventName: TestObjects.Event.testEventName) { _ in }
        chan.bind(eventName: "test-event-3") { _ in }
        XCTAssertEqual(chan.eventHandlers.count, 2, "the channel should have two event names with callbacks")
        chan.unbindAll()
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no callbacks")
    }

    func testCanSetDecryptionKey() {
        let decryptionKey = TestObjects.Event.Data.validDecryptionKey
        let chan = PusherChannel(name: TestObjects.Event.encryptedChannelName, connection: MockPusherConnection())
        chan.decryptionKey = decryptionKey
        XCTAssertEqual(chan.decryptionKey, decryptionKey)
    }
}
