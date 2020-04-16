import XCTest

#if WITH_ENCRYPTION
    @testable import PusherSwiftWithEncryption
#else
    @testable import PusherSwift
#endif


class PusherEventQueueDecryptionTests: XCTestCase {

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

    func testEncryptedChannelShouldCallDidReceiveEventWithoutAttemptingDecryption() {
      let dataPayload = """
        {
            "nonce": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm",
            "ciphertext": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
        }
        """.removing(.whitespacesAndNewlines)

        let jsonDict = """
        {
            "event": "user-event",
            "channel": "private-encrypted-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()

        let ex = expectation(description: "should call didReceiveEvent")
        eventQueueDelegate.didReceiveEvent = { (eventQueue, event, channelName) in
            let equal = NSDictionary(dictionary: jsonDict).isEqual(to: event.raw)
            XCTAssertTrue(equal)
            XCTAssertEqual("private-encrypted-channel", channelName)
            ex.fulfill()
        }

        eventQueue.report(json: jsonDict, forChannelName: "private-encrypted-channel")
        wait(for: [ex], timeout: 0.5)
    }

    func testNoChannelShouldCallDidReceiveEventWithoutAttemptingDecryption() {
      let dataPayload = """
        {
            "nonce": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm",
            "ciphertext": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
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
        eventQueue.report(json: jsonDict, forChannelName: nil)
        wait(for: [ex], timeout: 0.5)
    }
}
