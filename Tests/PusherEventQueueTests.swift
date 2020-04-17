import XCTest

#if WITH_ENCRYPTION
    @testable import PusherSwiftWithEncryption
#else
    @testable import PusherSwift
#endif

class InlineMockEventQueueDelegate: PusherEventQueueDelegate {
    var didReceiveEvent: ((PusherEventQueue, PusherEvent, String?) -> Void)?
    var didFailToDecryptEvent: ((PusherEventQueue, PusherEventPayload, String) -> Void)?
    var reloadDecryptionKeySync: ((PusherEventQueue, String) -> Void)?
    var didReceiveInvalidEvent: ((PusherEventQueue, PusherEventPayload) -> Void)?

    func eventQueue(_ eventQueue: PusherEventQueue, didReceiveInvalidEventWithPayload payload: PusherEventPayload){
        self.didReceiveInvalidEvent?(eventQueue, payload)
    }

    func eventQueue(_ eventQueue: PusherEventQueue, didReceiveEvent event: PusherEvent, forChannelName channelName: String?) {
        self.didReceiveEvent?(eventQueue, event, channelName)
    }

    func eventQueue(_ eventQueue: PusherEventQueue, didFailToDecryptEventWithPayload payload: PusherEventPayload, forChannelName channelName: String) {
        self.didFailToDecryptEvent?(eventQueue, payload, channelName)
    }

    func eventQueue(_ eventQueue: PusherEventQueue, reloadDecryptionKeySyncForChannelName channelName: String) {
        self.reloadDecryptionKeySync?(eventQueue, channelName)
    }
}

class PusherEventQueueTests: XCTestCase {

    var eventQueue: PusherEventQueue!
    var keyProvider: PusherKeyProvider!
    var eventFactory: PusherEventFactory!
    var eventQueueDelegate: InlineMockEventQueueDelegate!

    override func setUp() {
        super.setUp()
        keyProvider = PusherConcreteKeyProvider()
        eventFactory = PusherConcreteEventFactory()
        eventQueue = PusherConcreteEventQueue(eventFactory: eventFactory, keyProvider: keyProvider)
        eventQueueDelegate = InlineMockEventQueueDelegate()
        eventQueue.delegate = eventQueueDelegate
    }

    func testNonEncryptedChannelShouldCallDidReceiveEvent() {
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
            XCTAssertEqual("my-channel", channelName)
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
