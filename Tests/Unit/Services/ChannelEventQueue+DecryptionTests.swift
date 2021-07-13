@testable import PusherSwift
import XCTest

// swiftlint:disable unused_closure_parameter

class ChannelEventQueueDecryptionTests: XCTestCase {

    private var eventQueue: ChannelEventQueue!
    private var channels: PusherChannels!
    private var eventFactory: EventFactory!
    // swiftlint:disable:next weak_delegate
    private var eventQueueDelegate: InlineMockEventQueueDelegate!
    private var mockConnection: PusherConnection!

    override func setUp() {
        super.setUp()
        channels = PusherChannels()
        eventFactory = ChannelEventFactory()
        eventQueue = ChannelEventQueue(eventFactory: eventFactory, channels: channels)
        eventQueueDelegate = InlineMockEventQueueDelegate()
        eventQueue.delegate = eventQueueDelegate
        mockConnection = MockPusherConnection()
    }

    private func createAndSubscribe(_ channelName: String) -> PusherChannel {
        let channel = channels.add(name: channelName, connection: mockConnection)
        channel.subscribed = true
        return channel
    }

    func testEncryptedChannelShouldCallDidReceiveEventWithDecryptedMessage() {
        let channel = createAndSubscribe(TestObjects.Event.encryptedChannelName)

        let decryptionKey = TestObjects.Event.Data.validDecryptionKey

        let jsonDict = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                                  channel: TestObjects.Event.encryptedChannelName,
                                                  data: TestObjects.Event.Data.encryptedJSONTwo)
            .toJsonDict()

        channel.decryptionKey = decryptionKey

        let ex = expectation(description: "should call didReceiveEvent")

        eventQueueDelegate.didReceiveEvent = { eventQueue, event, channelName in
            XCTAssertEqual(event.data, TestObjects.Event.Data.decryptedJSONTwo.removing(.whitespacesAndNewlines))
            XCTAssertEqual(channelName, TestObjects.Event.encryptedChannelName)
            ex.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }

    func testEncryptedChannelShouldCallDidFailToDecryptEventWithNonEncryptedEvent() {
        let channel = createAndSubscribe(TestObjects.Event.encryptedChannelName)
        let decryptionKey = TestObjects.Event.Data.validDecryptionKey

        let jsonDict = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                                  channel: TestObjects.Event.encryptedChannelName,
                                                  data: TestObjects.Event.Data.decryptedJSONOne)
                           .toJsonDict()

        channel.decryptionKey = decryptionKey

        let ex = expectation(description: "should call didFailToDecryptEvent")

        eventQueueDelegate.didFailToDecryptEvent = { eventQueue, payload, channelName in
            let equal = NSDictionary(dictionary: jsonDict).isEqual(to: payload)
            XCTAssertTrue(equal)
            XCTAssertEqual(channelName, TestObjects.Event.encryptedChannelName)
            ex.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }

    func testShouldReloadDecryptionKeyAndDecryptSuccessfully() {
        let channel = createAndSubscribe(TestObjects.Event.encryptedChannelName)

        let wrongDecryptionKey = TestObjects.Event.Data.badDecryptionKey
        let correctDecryptionKey = TestObjects.Event.Data.validDecryptionKey

        let jsonDict = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                                  channel: TestObjects.Event.encryptedChannelName,
                                                  data: TestObjects.Event.Data.encryptedJSONTwo)
            .toJsonDict()

        channel.decryptionKey = wrongDecryptionKey

        let reloadEx = expectation(description: "should attempt to reload key")
        let receivedEv = expectation(description: "should call didReceiveEvent")

        eventQueueDelegate.reloadDecryptionKeySync = { eventQueue, channelToReload in
            XCTAssertEqual(channel, channelToReload)
            channelToReload.decryptionKey = correctDecryptionKey
            reloadEx.fulfill()
        }

        eventQueueDelegate.didReceiveEvent = { eventQueue, event, channelName in
            XCTAssertEqual(event.data, TestObjects.Event.Data.decryptedJSONTwo.removing(.whitespacesAndNewlines))
            XCTAssertEqual(channelName, TestObjects.Event.encryptedChannelName)
            receivedEv.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }

    func testShouldReloadDecryptionKeyOnceAndFailIfSecondKeyIsBad() {
        let channel = createAndSubscribe(TestObjects.Event.encryptedChannelName)

        let wrongDecryptionKey0 = TestObjects.Event.Data.badDecryptionKey
        let wrongDecryptionKey1 = "11111111111111111111111111111111111111111111"

        let jsonDict = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                                  channel: TestObjects.Event.encryptedChannelName,
                                                  data: TestObjects.Event.Data.encryptedJSONTwo)
            .toJsonDict()

        channel.decryptionKey = wrongDecryptionKey0

        let reloadEx = expectation(description: "should attempt to reload key")
        let failedEv = expectation(description: "should fail to decrypt message")

        eventQueueDelegate.reloadDecryptionKeySync = { eventQueue, channelToReload in
            XCTAssertEqual(channel, channelToReload)
            channelToReload.decryptionKey = wrongDecryptionKey1
            reloadEx.fulfill()
        }

        eventQueueDelegate.didFailToDecryptEvent = { event, payload, channelName in
            let equal = NSDictionary(dictionary: jsonDict).isEqual(to: payload)
            XCTAssertTrue(equal)
            XCTAssertEqual(channelName, TestObjects.Event.encryptedChannelName)
            failedEv.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }

    func testShouldMoveOnAfterFailingToDecryptAMessage() {
        let channel = createAndSubscribe(TestObjects.Event.encryptedChannelName)

        let wrongDecryptionKey = TestObjects.Event.Data.badDecryptionKey

        // Decryption key for "decryptableData" but not "undecryptableData"
        let correctDecryptionKey = TestObjects.Event.Data.validDecryptionKey

        let undecryptableEvent = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                                            channel: TestObjects.Event.encryptedChannelName,
                                                            data: TestObjects.Event.Data.undecryptableJSON)
                                     .toJsonDict()
        let decryptableEvent = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                                          channel: TestObjects.Event.encryptedChannelName,
                                                          data: TestObjects.Event.Data.encryptedJSONTwo)
                                   .toJsonDict()

        channel.decryptionKey = wrongDecryptionKey

        let reloadEx = expectation(description: "should attempt to reload key")
        let failedEx = expectation(description: "should fail to decrypt message")
        let successEx = expectation(description: "should succeed in decrypting message")

        eventQueueDelegate.reloadDecryptionKeySync = { eventQueue, channelToReload in
            XCTAssertEqual(channel, channelToReload)
            channelToReload.decryptionKey = correctDecryptionKey
            reloadEx.fulfill()
        }

        eventQueueDelegate.didFailToDecryptEvent = { event, payload, channelName in
            let equal = NSDictionary(dictionary: undecryptableEvent).isEqual(to: payload)
            XCTAssertTrue(equal)
            XCTAssertEqual(channelName, TestObjects.Event.encryptedChannelName)
            failedEx.fulfill()
        }

        eventQueueDelegate.didReceiveEvent = { eventQueue, event, channelName in
            XCTAssertEqual(event.data, TestObjects.Event.Data.decryptedJSONTwo.removing(.whitespacesAndNewlines))
            XCTAssertEqual(channelName, TestObjects.Event.encryptedChannelName)
            successEx.fulfill()
        }

        eventQueue.enqueue(json: undecryptableEvent)
        eventQueue.enqueue(json: decryptableEvent)

        waitForExpectations(timeout: 0.5)
    }

    func testFailingToDecryptOnOneChannelShouldNotAffectAnother() {
        let decryptableChannel = createAndSubscribe("private-encrypted-decryptable")
        let undecryptableChannel = createAndSubscribe("private-encrypted-undecryptable")

        let wrongDecryptionKey = TestObjects.Event.Data.badDecryptionKey

        // Decryption key for "decryptableData" but not "undecryptableData"
        let correctDecryptionKey = TestObjects.Event.Data.validDecryptionKey

        let undecryptableEvent = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                                            channel: undecryptableChannel.name,
                                                            data: TestObjects.Event.Data.undecryptableJSON)
                                     .toJsonDict()
        let decryptableEvent = TestObjects.Event.withJSON(name: TestObjects.Event.userEventName,
                                                          channel: decryptableChannel.name,
                                                          data: TestObjects.Event.Data.encryptedJSONTwo)
                                   .toJsonDict()

        decryptableChannel.decryptionKey = correctDecryptionKey
        undecryptableChannel.decryptionKey = wrongDecryptionKey

        let reloadEx = expectation(description: "should attempt to reload key")
        let failedEx = expectation(description: "should fail to decrypt message")
        let successEx = expectation(description: "should succeed in decrypting message")

        eventQueueDelegate.reloadDecryptionKeySync = { eventQueue, channelToReload in
            XCTAssertEqual(undecryptableChannel, channelToReload)
            channelToReload.decryptionKey = wrongDecryptionKey
            reloadEx.fulfill()
        }

        eventQueueDelegate.didFailToDecryptEvent = { event, payload, channelName in
            let equal = NSDictionary(dictionary: undecryptableEvent).isEqual(to: payload)
            XCTAssertTrue(equal)
            XCTAssertEqual(undecryptableChannel.name, channelName)
            failedEx.fulfill()
        }

        eventQueueDelegate.didReceiveEvent = { eventQueue, event, channelName in
            XCTAssertEqual(event.data, TestObjects.Event.Data.decryptedJSONTwo.removing(.whitespacesAndNewlines))
            XCTAssertEqual(decryptableChannel.name, channelName)
            successEx.fulfill()
        }

        eventQueue.enqueue(json: undecryptableEvent)
        eventQueue.enqueue(json: decryptableEvent)

        waitForExpectations(timeout: 0.5)
    }
}
