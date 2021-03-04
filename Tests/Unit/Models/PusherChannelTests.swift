import XCTest

@testable import PusherSwift

class PusherChannelTests: XCTestCase {
    private var chan: PusherChannel!

    override func setUp() {
        super.setUp()

        chan = PusherChannel(name: "test-channel", connection: MockPusherConnection())
    }

    func testANewChannelGetsCreatedWithTheCorrectNameAndNoCallbacks() {
        let chan = PusherChannel(name: "test-channel", connection: MockPusherConnection())
        XCTAssertEqual(chan.name, "test-channel", "the channel name should be test-channel")
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no callbacks")
    }

    func testBindingACallbackToAChannelForAGivenEventName() {
        let chan = PusherChannel(name: "test-channel", connection: MockPusherConnection())
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no callbacks")
        chan.bind(eventName: "test-event") { _ in }
        XCTAssertEqual(chan.eventHandlers["test-event"]?.count, 1, "the channel should have one callback")
    }

    func testUnbindingAnEventCallbackForAGivenEventNameAndCallbackId() {
        let chan = PusherChannel(name: "test-channel", connection: MockPusherConnection())
        XCTAssertNil(chan.eventHandlers["test-event"], "the channel should have no callbacks for event \"test-event\"")
        let idOne = chan.bind(eventName: "test-event") { _ in }
        chan.bind(eventName: "test-event") { _ in }
        XCTAssertEqual(chan.eventHandlers["test-event"]?.count, 2, "the channel should have two callbacks for event \"test-event\"")
        chan.unbind(eventName: "test-event", callbackId: idOne)
        XCTAssertEqual(chan.eventHandlers["test-event"]?.count, 1, "the channel should have one callback for event \"test-event\"")
    }

    func testUnbindingAllCallbacksForAGivenEventName() {
        let chan = PusherChannel(name: "test-channel", connection: MockPusherConnection())
        XCTAssertNil(chan.eventHandlers["test-event"], "the channel should have no callbacks for event \"test-event\"")
        chan.bind(eventName: "test-event") { _ in }
        chan.bind(eventName: "test-event") { _ in }
        XCTAssertEqual(chan.eventHandlers["test-event"]?.count, 2, "the channel should have two callbacks for event \"test-event\"")
        chan.unbindAll(forEventName: "test-event")
        XCTAssertEqual(chan.eventHandlers["test-event"]?.count, 0, "the channel should have no callbacks for event \"test-event\"")
    }

    func testUnbindingAllCallbacksForAGivenChannel() {
        let chan = PusherChannel(name: "test-channel", connection: MockPusherConnection())
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no callbacks")
        chan.bind(eventName: "test-event") { _ in }
        chan.bind(eventName: "test-event") { _ in }
        chan.bind(eventName: "test-event-3") { _ in }
        XCTAssertEqual(chan.eventHandlers.count, 2, "the channel should have two event names with callbacks")
        chan.unbindAll()
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no callbacks")
    }

    func testCanSetDecryptionKey() {
        let decryptionKey = "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs="
        let chan = PusherChannel(name: "private-encrypted-test-channel", connection: MockPusherConnection())
        chan.decryptionKey = decryptionKey
        XCTAssertEqual(chan.decryptionKey, decryptionKey)
    }
}
