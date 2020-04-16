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

    func testEncryptedChannelShouldCallDidReceiveEventWithDecryptedMessage() {

        let decryptionKey = "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs="

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

        let expectedDecryptedPayload = """
        {
          "name": "freddy",
          "message": "hello"
        }
        """.removing(.whitespacesAndNewlines)

        keyProvider.setDecryptionKey(decryptionKey, forChannelName: "private-encrypted-channel")

        let ex = expectation(description: "should call didReceiveEvent")

        eventQueueDelegate.didReceiveEvent = { (eventQueue, event, channelName) in
            XCTAssertEqual(event.data, expectedDecryptedPayload)
            XCTAssertEqual("private-encrypted-channel", channelName)
            ex.fulfill()
        }

        eventQueue.report(json: jsonDict, forChannelName: "private-encrypted-channel")
        wait(for: [ex], timeout: 0.5)
    }



    // Need encrypted version too
    // Valid encrypted event without channel name - valid key
    // Valid encrypted event with channel name - valid key

    // Should call reloadDecryption for a sequence of wrong events
    // Should only call reloadDecryption once if subsequent messages can be decrypted
    // If can't decrypt message after reloading, should call didFailToDecryptEventWithPayload and move on
}
