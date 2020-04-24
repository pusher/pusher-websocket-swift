import XCTest

#if WITH_ENCRYPTION
    @testable import PusherSwiftWithEncryption
#else
    @testable import PusherSwift
#endif

class ClientEventTests: XCTestCase {
    var connection: MockPusherConnection!
    var socket: MockWebSocket!

    override func setUp() {
        super.setUp()

        socket = MockWebSocket()
        let options = PusherClientOptions(
            authMethod: .inline(secret: "superSecretSecret"),
            autoReconnect: false
        )
        connection = MockPusherConnection(options: options)
        socket.delegate = connection
        connection.socket = socket
    }

    func testTriggeringClientEventsDoesNotWriteToTheSocketForPublicChannels() {
        let chan = PusherChannel(name: "test-channel", connection: connection)
        chan.subscribed = true
        chan.trigger(eventName: "client-test-event", data: ["data": "testing client events"])
        XCTAssertEqual(socket.stubber.calls.count, 0, "the socket should not have written anything")
    }

    func testTriggeringClientEventsWritesToTheSocketForAuthenticatedChannels() {
        let chan = PusherChannel(name: "private-channel", connection: connection)
        chan.subscribed = true
        chan.trigger(eventName: "client-test-event", data: ["data": "testing client events"])
        let parsedSubscribeArgs = convertStringToDictionary(socket.stubber.calls.first?.args!.first as! String)
        let expectedDict = ["data": ["data": "testing client events"], "event": "client-test-event", "channel": "private-channel"] as [String: Any]
        let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject: AnyObject])
        XCTAssertTrue(parsedEqualsExpected)
    }

    func testQueuedClientEventsGetSentOnceSubscriptionSucceeds() {
        let chan = PusherChannel(name: "private-channel", connection: connection)
        connection.channels.channels["private-channel"] = chan
        XCTAssertEqual(chan.unsentEvents.count, 0, "no events should have been queued yet")
        chan.trigger(eventName: "client-test-event", data: ["data": "testing client events"])
        XCTAssertEqual(chan.unsentEvents.last!.name, "client-test-event")
        XCTAssertEqual(socket.stubber.calls.count, 0, "no events should have been sent yet")

        let ex = expectation(description: "send client event eventually")
        socket.stubber.registerCallback { calls in
            let expectedDict = ["data": ["data": "testing client events"], "event": "client-test-event", "channel": "private-channel"] as [String: Any]
            if let lastCall = calls.last, lastCall.name == "writeString" {
                let parsedSubscribeArgs = convertStringToDictionary(lastCall.args!.first as! String)
                let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject: AnyObject])
                if parsedEqualsExpected {
                    ex.fulfill()
                }
            }
        }
        connection.connect()
        waitForExpectations(timeout: 0.5)
    }

    func testTriggeringMultipleClientEventsWithTheSameNameThatWereQueuedBeforeSuccessfulSubscription() {
        let chan = PusherChannel(name: "private-channel", connection: connection)
        connection.channels.channels["private-channel"] = chan
        XCTAssertEqual(chan.unsentEvents.count, 0, "no events should have been queued yet")
        chan.trigger(eventName: "client-test-event", data: ["data": "testing client events"])
        chan.trigger(eventName: "client-test-event", data: ["data": "more testing client events"])
        XCTAssertEqual(chan.unsentEvents.last!.name, "client-test-event")
        XCTAssertEqual(chan.unsentEvents.count, 2, "two events should have been queued")
        XCTAssertEqual(socket.stubber.calls.count, 0, "no events should have been sent yet")

        let ex = expectation(description: "send client event eventually")
        socket.stubber.registerCallback { calls in
            if let lastCall = calls.last, lastCall.name == "writeString" {
                let parsedSubscribeArgs = convertStringToDictionary(lastCall.args!.first as! String)
                let expectedDict = ["data": ["data": "more testing client events"], "event": "client-test-event", "channel": "private-channel"] as [String: Any]
                let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject: AnyObject])
                if parsedEqualsExpected {
                    ex.fulfill()
                }
            }

        }
        connection.connect()
        waitForExpectations(timeout: 0.5)
    }
}
