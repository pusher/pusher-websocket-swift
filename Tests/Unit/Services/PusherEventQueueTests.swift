import XCTest

@testable import PusherSwift

// swiftlint:disable unused_closure_parameter

class InlineMockEventQueueDelegate: PusherEventQueueDelegate {
    var didReceiveEvent: ((PusherEventQueue, PusherEvent, String?) -> Void)?
    var didFailToDecryptEvent: ((PusherEventQueue, PusherEventPayload, String) -> Void)?
    var reloadDecryptionKeySync: ((PusherEventQueue, PusherChannel) -> Void)?
    var didReceiveInvalidEvent: ((PusherEventQueue, PusherEventPayload) -> Void)?

    func eventQueue(_ eventQueue: PusherEventQueue, didReceiveInvalidEventWithPayload payload: PusherEventPayload) {
        self.didReceiveInvalidEvent?(eventQueue, payload)
    }

    func eventQueue(_ eventQueue: PusherEventQueue, didReceiveEvent event: PusherEvent, forChannelName channelName: String?) {
        self.didReceiveEvent?(eventQueue, event, channelName)
    }

    func eventQueue(_ eventQueue: PusherEventQueue, didFailToDecryptEventWithPayload payload: PusherEventPayload, forChannelName channelName: String) {
        self.didFailToDecryptEvent?(eventQueue, payload, channelName)
    }

    func eventQueue(_ eventQueue: PusherEventQueue, reloadDecryptionKeySyncForChannel channel: PusherChannel) {
        self.reloadDecryptionKeySync?(eventQueue, channel)
    }
}

class PusherEventQueueTests: XCTestCase {

    var eventQueue: PusherEventQueue!
    var eventFactory: PusherEventFactory!
    // swiftlint:disable:next weak_delegate
    var eventQueueDelegate: InlineMockEventQueueDelegate!
    var channels: PusherChannels!
    var connection: PusherConnection!

    override func setUp() {
        super.setUp()
        channels = PusherChannels()
        connection = MockPusherConnection()
        eventFactory = PusherConcreteEventFactory()
        eventQueue = PusherConcreteEventQueue(eventFactory: eventFactory, channels: channels)
        eventQueueDelegate = InlineMockEventQueueDelegate()
        eventQueue.delegate = eventQueueDelegate
    }

    func createAndSubscribe(_ channelName: String) -> PusherChannel {
        let channel = channels.add(name: channelName, connection: connection)
        channel.subscribed = true
        return channel
    }

    func testNonEncryptedChannelShouldCallDidReceiveEvent() {
        let channel = createAndSubscribe("my-channel")
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

        let ex = expectation(description: "should call didReceiveEvent")
        eventQueueDelegate.didReceiveEvent = { (eventQueue, event, channelName) in
            let equal = NSDictionary(dictionary: jsonDict).isEqual(to: event.raw)
            XCTAssertTrue(equal)
            XCTAssertEqual(channel.name, channelName)
            ex.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }

    func testEventWithNoChannelShouldCallDidReceiveEvent() {
        let dataPayload = """
        {
           "test": "test string",
           "and": "another"
        }
        """.removing(.whitespacesAndNewlines)

        let jsonDict = """
        {
           "event": "pusher:new-event",
           "data": \(dataPayload.escaped)
        }
        """.toJsonDict()

        let ex = expectation(description: "should call didReceiveEvent")
        eventQueueDelegate.didReceiveEvent = { (eventQueue, event, channelName) in
            let equal = NSDictionary(dictionary: jsonDict).isEqual(to: event.raw)
            XCTAssertTrue(equal)
            XCTAssertNil(channelName)
            ex.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }

    func testInvalidEventShouldCallDidReceiveInvalidEvent() {
        let dataPayload = """
        {
           "test": "test string",
           "and": "another"
        }
        """.removing(.whitespacesAndNewlines)

        let jsonDict = """
        {
           "data": \(dataPayload.escaped)
        }
        """.toJsonDict()

        let ex = expectation(description: "should call didReceiveInvalidEvent")
        eventQueueDelegate.didReceiveInvalidEvent = { (eventQueue, payload) in
            let equal = NSDictionary(dictionary: jsonDict).isEqual(to: payload)
            XCTAssertTrue(equal)
            ex.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }
}
