@testable import PusherSwift
import XCTest

// swiftlint:disable unused_closure_parameter

class PusherEventQueueDecryptionTests: XCTestCase {

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
        let channel = createAndSubscribe("private-encrypted-channel")

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

        channel.decryptionKey = decryptionKey

        let ex = expectation(description: "should call didReceiveEvent")

        eventQueueDelegate.didReceiveEvent = { eventQueue, event, channelName in
            XCTAssertEqual(event.data, expectedDecryptedPayload)
            XCTAssertEqual("private-encrypted-channel", channelName)
            ex.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }

    func testEncryptedChannelShouldCallDidFailToDecryptEventWithNonEncryptedEvent() {
        let channel = createAndSubscribe("private-encrypted-channel")
        let decryptionKey = "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs="

        let dataPayload = """
        {
          "message": "Hello"
        }
        """.removing(.whitespacesAndNewlines)

        let jsonDict = """
        {
          "event": "user-event",
          "channel": "private-encrypted-channel",
          "data": \(dataPayload.escaped)
        }
        """.toJsonDict()

        channel.decryptionKey = decryptionKey

        let ex = expectation(description: "should call didFailToDecryptEvent")

        eventQueueDelegate.didFailToDecryptEvent = { eventQueue, payload, channelName in
            let equal = NSDictionary(dictionary: jsonDict).isEqual(to: payload)
            XCTAssertTrue(equal)
            XCTAssertEqual("private-encrypted-channel", channelName)
            ex.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }

    func testShouldReloadDecryptionKeyAndDecryptSuccessfully() {
        let channel = createAndSubscribe("private-encrypted-channel")

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

        channel.decryptionKey = wrongDecryptionKey

        let reloadEx = expectation(description: "should attempt to reload key")
        let receivedEv = expectation(description: "should call didReceiveEvent")

        eventQueueDelegate.reloadDecryptionKeySync = { eventQueue, channelToReload in
            XCTAssertEqual(channel, channelToReload)
            channelToReload.decryptionKey = correctDecryptionKey
            reloadEx.fulfill()
        }

        eventQueueDelegate.didReceiveEvent = { eventQueue, event, channelName in
            XCTAssertEqual(event.data, expectedDecryptedPayload)
            XCTAssertEqual("private-encrypted-channel", channelName)
            receivedEv.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }

    func testShouldReloadDecryptionKeyOnceAndFailIfSecondKeyIsBad() {
        let channel = createAndSubscribe("private-encrypted-channel")

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
            XCTAssertEqual("private-encrypted-channel", channelName)
            failedEv.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }

    // swiftlint:disable:next function_body_length
    func testShouldMoveOnAfterFailingToDecryptAMessage() {
        let channel = createAndSubscribe("private-encrypted-channel")

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
            XCTAssertEqual("private-encrypted-channel", channelName)
            failedEx.fulfill()
        }

        eventQueueDelegate.didReceiveEvent = { eventQueue, event, channelName in
            XCTAssertEqual(expectedDecryptedPayload, event.data)
            XCTAssertEqual("private-encrypted-channel", channelName)
            successEx.fulfill()
        }

        eventQueue.enqueue(json: undecryptableEvent)
        eventQueue.enqueue(json: decryptableEvent)

        waitForExpectations(timeout: 0.5)
    }

    // swiftlint:disable:next function_body_length
    func testFailingToDecryptOnOneChannelShouldNotAffectAnother() {
        let decryptableChannel = createAndSubscribe("private-encrypted-decryptable")
        let undecryptableChannel = createAndSubscribe("private-encrypted-undecryptable")

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

        let undecryptableEvent = generateEvent(undecryptableChannel.name, undecryptableData)
        let decryptableEvent = generateEvent(decryptableChannel.name, decryptableData)

        let expectedDecryptedPayload = """
        {
          "name": "freddy",
          "message": "hello"
        }
        """.removing(.whitespacesAndNewlines)

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
            XCTAssertEqual(expectedDecryptedPayload, event.data)
            XCTAssertEqual(decryptableChannel.name, channelName)
            successEx.fulfill()
        }

        eventQueue.enqueue(json: undecryptableEvent)
        eventQueue.enqueue(json: decryptableEvent)

        waitForExpectations(timeout: 0.5)
    }
}
