@testable import PusherSwift
import XCTest

class PusherEventQueueDecryptionTests: XCTestCase {

    var eventQueue: PusherEventQueue!
    var channels: PusherChannels!
    var eventFactory: PusherEventFactory!
    // swiftlint:disable:next weak_delegate
    var eventQueueDelegate: InlineMockEventQueueDelegate!
    var mockConnection: PusherConnection!

    override func setUp() {
        super.setUp()
        channels = PusherChannels()
        eventFactory = PusherConcreteEventFactory()
        eventQueue = PusherConcreteEventQueue(eventFactory: eventFactory, channels: channels)
        eventQueueDelegate = InlineMockEventQueueDelegate()
        eventQueue.delegate = eventQueueDelegate
        mockConnection = MockPusherConnection()
    }

    func createAndSubscribe(_ channelName: String) -> PusherChannel {
        let channel = channels.add(name: channelName, connection: mockConnection)
        channel.subscribed = true
        return channel
    }

    func testEncryptedChannelShouldCallDidReceiveEventWithoutAttemptingDecryption() {
        let channel = createAndSubscribe("private-encrypted-channel")
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
            XCTAssertEqual(dataPayload, event.data)
            XCTAssertEqual(channel.name, channelName)
            ex.fulfill()
        }

        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
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
            XCTAssertEqual(dataPayload, event.data)
            XCTAssertNil(channelName)
            ex.fulfill()
        }
        eventQueue.enqueue(json: jsonDict)
        waitForExpectations(timeout: 0.5)
    }
}
