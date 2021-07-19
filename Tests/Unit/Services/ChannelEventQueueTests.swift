import XCTest

@testable import PusherSwift

// swiftlint:disable unused_closure_parameter

class InlineMockEventQueueDelegate: EventQueueDelegate {
    var didReceiveEvent: ((EventQueue, PusherEvent, String?) -> Void)?
    var didFailToDecryptEvent: ((EventQueue, ChannelEventPayload, String) -> Void)?
    var reloadDecryptionKeySync: ((EventQueue, PusherChannel) -> Void)?
    var didReceiveInvalidEvent: ((EventQueue, ChannelEventPayload) -> Void)?

    func eventQueue(_ eventQueue: EventQueue, didReceiveInvalidEventWithPayload payload: ChannelEventPayload) {
        self.didReceiveInvalidEvent?(eventQueue, payload)
    }

    func eventQueue(_ eventQueue: EventQueue, didReceiveEvent event: PusherEvent, forChannelName channelName: String?) {
        self.didReceiveEvent?(eventQueue, event, channelName)
    }

    func eventQueue(_ eventQueue: EventQueue, didFailToDecryptEventWithPayload payload: ChannelEventPayload, forChannelName channelName: String) {
        self.didFailToDecryptEvent?(eventQueue, payload, channelName)
    }

    func eventQueue(_ eventQueue: EventQueue, reloadDecryptionKeySyncForChannel channel: PusherChannel) {
        self.reloadDecryptionKeySync?(eventQueue, channel)
    }
}

class ChannelEventQueueTests: XCTestCase {

    private var eventQueue: ChannelEventQueue!
    private var eventFactory: EventFactory!
    // swiftlint:disable:next weak_delegate
    private var eventQueueDelegate: InlineMockEventQueueDelegate!
    private var channels: PusherChannels!
    private var connection: PusherConnection!

    override func setUp() {
        super.setUp()
        channels = PusherChannels()
        connection = MockPusherConnection()
        eventFactory = ChannelEventFactory()
        eventQueue = ChannelEventQueue(eventFactory: eventFactory, channels: channels)
        eventQueueDelegate = InlineMockEventQueueDelegate()
        eventQueue.delegate = eventQueueDelegate
    }

    private func createAndSubscribe(_ channelName: String) -> PusherChannel {
        let channel = channels.add(name: channelName, connection: connection)
        channel.subscribed = true
        return channel
    }

    func testNonEncryptedChannelShouldCallDidReceiveEvent() {
        let channel = createAndSubscribe(TestObjects.Event.testChannelName)
        let jsonDict = TestObjects.Event.withJSON().toJsonDict()

        let ex = expectation(description: "should call didReceiveEvent")
        eventQueueDelegate.didReceiveEvent = { eventQueue, event, channelName in
            let equal = NSDictionary(dictionary: jsonDict).isEqual(to: event.raw)
            XCTAssertTrue(equal)
            XCTAssertEqual(channel.name, channelName)
            ex.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }

    func testEventWithNoChannelShouldCallDidReceiveEvent() {
        let jsonDict = TestObjects.Event.withoutChannelNameJSON.toJsonDict()

        let ex = expectation(description: "should call didReceiveEvent")
        eventQueueDelegate.didReceiveEvent = { eventQueue, event, channelName in
            let equal = NSDictionary(dictionary: jsonDict).isEqual(to: event.raw)
            XCTAssertTrue(equal)
            XCTAssertNil(channelName)
            ex.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }

    func testInvalidEventShouldCallDidReceiveInvalidEvent() {
        let jsonDict = TestObjects.Event.withoutEventOrChannelNameJSON.toJsonDict()

        let ex = expectation(description: "should call didReceiveInvalidEvent")
        eventQueueDelegate.didReceiveInvalidEvent = { eventQueue, payload in
            let equal = NSDictionary(dictionary: jsonDict).isEqual(to: payload)
            XCTAssertTrue(equal)
            ex.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }
}
