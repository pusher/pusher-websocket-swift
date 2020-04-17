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

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }

    func testShouldReloadDecryptionKeyAndDecryptSuccessfully() {

        let wrongDecryptionKey = "00000000000000000000000000000000000000000000"
        let correctDecryptionKey = "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs="

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

        keyProvider.setDecryptionKey(wrongDecryptionKey, forChannelName: "private-encrypted-channel")

        let reloadEx = expectation(description: "should attempt to reload key")
        let receivedEv = expectation(description: "should call didReceiveEvent")

        eventQueueDelegate.reloadDecryptionKeySync = { (eventQueue, channelName) in
            XCTAssertEqual("private-encrypted-channel", channelName)
            self.keyProvider.setDecryptionKey(correctDecryptionKey, forChannelName: channelName)
            reloadEx.fulfill()
        }

        eventQueueDelegate.didReceiveEvent = { (eventQueue, event, channelName) in
            XCTAssertEqual(event.data, expectedDecryptedPayload)
            XCTAssertEqual("private-encrypted-channel", channelName)
            receivedEv.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }

    func testShouldReloadDecryptionKeyOnceAndFailIfSecondKeyIsBad() {
        let wrongDecryptionKey0 = "00000000000000000000000000000000000000000000"
        let wrongDecryptionKey1 = "11111111111111111111111111111111111111111111"

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

        keyProvider.setDecryptionKey(wrongDecryptionKey0, forChannelName: "private-encrypted-channel")

        let reloadEx = expectation(description: "should attempt to reload key")
        let failedEv = expectation(description: "should fail to decrypt message")

        eventQueueDelegate.reloadDecryptionKeySync = { (eventQueue, channelName) in
            XCTAssertEqual("private-encrypted-channel", channelName)
            self.keyProvider.setDecryptionKey(wrongDecryptionKey1, forChannelName: channelName)
            reloadEx.fulfill()
        }

        eventQueueDelegate.didFailToDecryptEvent = { (event, payload, channelName) in
            let equal = NSDictionary(dictionary: jsonDict).isEqual(to: payload)
            XCTAssertTrue(equal)
            XCTAssertEqual("private-encrypted-channel", channelName)
            failedEv.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }

    func testShouldMoveOnAfterFailingToDecryptAMessage() {
        let wrongDecryptionKey = "00000000000000000000000000000000000000000000"

        // Decryption key for "decryptableData" but not "undecryptableData"
        let correctDecryptionKey = "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs="

        let undecryptableData = """
        {
          "nonce": "7w2hU5r5VMj3PGXXepgP6E/KgPob5o6t",
          "ciphertext": "FX0lJZu33f0dWPb89816ngn0l9NfJC5mFny6EQF6z25K+Ly5LFS9hP7XAC6s5pUoZqGXzC03FA=="
        }
        """.removing(.whitespacesAndNewlines)

        let decryptableData = """
        {
          "nonce": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm",
          "ciphertext": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
        }
        """.removing(.whitespacesAndNewlines)

        let generateEvent = { (payload: String) in
            return """
            {
              "event": "user-event",
              "channel": "private-encrypted-channel",
              "data": \(payload.escaped)
            }
            """.toJsonDict()
        }

        let undecryptableEvent = generateEvent(undecryptableData)
        let decryptableEvent = generateEvent(decryptableData)

        let expectedDecryptedPayload = """
        {
          "name": "freddy",
          "message": "hello"
        }
        """.removing(.whitespacesAndNewlines)

        keyProvider.setDecryptionKey(wrongDecryptionKey, forChannelName: "private-encrypted-channel")

        let reloadEx = expectation(description: "should attempt to reload key")
        let failedEx = expectation(description: "should fail to decrypt message")
        let successEx = expectation(description: "should succeed in decrypting message")

        eventQueueDelegate.reloadDecryptionKeySync = { (eventQueue, channelName) in
            XCTAssertEqual("private-encrypted-channel", channelName)
            self.keyProvider.setDecryptionKey(correctDecryptionKey, forChannelName: channelName)
            reloadEx.fulfill()
        }

        eventQueueDelegate.didFailToDecryptEvent = { (event, payload, channelName) in
            let equal = NSDictionary(dictionary: undecryptableEvent).isEqual(to: payload)
            XCTAssertTrue(equal)
            XCTAssertEqual("private-encrypted-channel", channelName)
            failedEx.fulfill()
        }

        eventQueueDelegate.didReceiveEvent = { (eventQueue, event, channelName) in
            XCTAssertEqual(expectedDecryptedPayload, event.data)
            XCTAssertEqual("private-encrypted-channel", channelName)
            successEx.fulfill()
        }

        eventQueue.enqueue(json: undecryptableEvent)
        eventQueue.enqueue(json: decryptableEvent)

        waitForExpectations(timeout: 0.5)
    }

    func testFailingToDecryptOnOneChannelShouldNotAffectAnother() {
        let decryptableChannel = "private-encrypted-decryptable"
        let undecryptableChannel = "private-encrypted-undecryptable"

        let wrongDecryptionKey = "00000000000000000000000000000000000000000000"

        // Decryption key for "decryptableData" but not "undecryptableData"
        let correctDecryptionKey = "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs="

        let undecryptableData = """
        {
          "nonce": "7w2hU5r5VMj3PGXXepgP6E/KgPob5o6t",
          "ciphertext": "FX0lJZu33f0dWPb89816ngn0l9NfJC5mFny6EQF6z25K+Ly5LFS9hP7XAC6s5pUoZqGXzC03FA=="
        }
        """.removing(.whitespacesAndNewlines)

        let decryptableData = """
        {
          "nonce": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm",
          "ciphertext": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
        }
        """.removing(.whitespacesAndNewlines)

        let generateEvent = { (channel: String, payload: String) in
            return """
            {
              "event": "user-event",
              "channel": "\(channel)",
              "data": \(payload.escaped)
            }
            """.toJsonDict()
        }

        let undecryptableEvent = generateEvent(undecryptableChannel, undecryptableData)
        let decryptableEvent = generateEvent(decryptableChannel, decryptableData)

        let expectedDecryptedPayload = """
        {
          "name": "freddy",
          "message": "hello"
        }
        """.removing(.whitespacesAndNewlines)

        keyProvider.setDecryptionKey(correctDecryptionKey, forChannelName: decryptableChannel)
        keyProvider.setDecryptionKey(wrongDecryptionKey, forChannelName: undecryptableChannel)

        let reloadEx = expectation(description: "should attempt to reload key")
        let failedEx = expectation(description: "should fail to decrypt message")
        let successEx = expectation(description: "should succeed in decrypting message")

        eventQueueDelegate.reloadDecryptionKeySync = { (eventQueue, channelName) in
            XCTAssertEqual(undecryptableChannel, channelName)
            self.keyProvider.setDecryptionKey(wrongDecryptionKey, forChannelName: undecryptableChannel)
            reloadEx.fulfill()
        }

        eventQueueDelegate.didFailToDecryptEvent = { (event, payload, channelName) in
            let equal = NSDictionary(dictionary: undecryptableEvent).isEqual(to: payload)
            XCTAssertTrue(equal)
            XCTAssertEqual(undecryptableChannel, channelName)
            failedEx.fulfill()
        }

        eventQueueDelegate.didReceiveEvent = { (eventQueue, event, channelName) in
            XCTAssertEqual(expectedDecryptedPayload, event.data)
            XCTAssertEqual(decryptableChannel, channelName)
            successEx.fulfill()
        }

        eventQueue.enqueue(json: undecryptableEvent)
        eventQueue.enqueue(json: decryptableEvent)

        waitForExpectations(timeout: 0.5)
    }

    
}
