import XCTest

@testable import PusherSwift

class ClientEventTests: XCTestCase {
    private var connection: MockPusherConnection!
    private var socket: MockWebSocket!

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
        let chan = PusherChannel(name: TestObjects.Event.testChannelName, connection: connection)
        chan.subscribed = true
        chan.trigger(eventName: TestObjects.Event.clientEventName, data: [Constants.JSONKeys.data: "testing client events"])
        XCTAssertEqual(socket.stubber.calls.count, 0, "the socket should not have written anything")
    }

    func testTriggeringClientEventsWritesToTheSocketForAuthenticatedChannels() {
        let chan = PusherChannel(name: TestObjects.Event.privateChannelName, connection: connection)
        chan.subscribed = true
        chan.trigger(eventName: TestObjects.Event.clientEventName, data: [Constants.JSONKeys.data: "testing client events"])
        let parsedSubscribeArgs = convertStringToDictionary(socket.stubber.calls.first?.args!.first as! String)
        let expectedDict = [Constants.JSONKeys.data: [Constants.JSONKeys.data: "testing client events"], Constants.JSONKeys.event: TestObjects.Event.clientEventName, Constants.JSONKeys.channel: TestObjects.Event.privateChannelName] as [String: Any]
        let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject: AnyObject])
        XCTAssertTrue(parsedEqualsExpected)
    }

    func testQueuedClientEventsGetSentOnceSubscriptionSucceeds() {
        let chan = PusherChannel(name: TestObjects.Event.privateChannelName, connection: connection)
        connection.channels.channels[TestObjects.Event.privateChannelName] = chan
        XCTAssertEqual(chan.unsentEvents.count, 0, "no events should have been queued yet")
        chan.trigger(eventName: TestObjects.Event.clientEventName, data: [Constants.JSONKeys.data: "testing client events"])
        XCTAssertEqual(chan.unsentEvents.last!.name, TestObjects.Event.clientEventName)
        XCTAssertEqual(socket.stubber.calls.count, 0, "no events should have been sent yet")

        let ex = expectation(description: "send client event eventually")
        socket.stubber.registerCallback { calls in
            let expectedDict = [Constants.JSONKeys.data: [Constants.JSONKeys.data: "testing client events"], Constants.JSONKeys.event: TestObjects.Event.clientEventName, Constants.JSONKeys.channel: TestObjects.Event.privateChannelName] as [String: Any]
            guard let lastCall = calls.last, lastCall.name == "writeString" else {
                return
            }

            let parsedSubscribeArgs = convertStringToDictionary(lastCall.args!.first as! String)
            let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject: AnyObject])
            if parsedEqualsExpected {
                ex.fulfill()
            }
        }
        connection.connect()
        waitForExpectations(timeout: 0.5)
    }

    func testTriggeringMultipleClientEventsWithTheSameNameThatWereQueuedBeforeSuccessfulSubscription() {
        let chan = PusherChannel(name: TestObjects.Event.privateChannelName, connection: connection)
        connection.channels.channels[TestObjects.Event.privateChannelName] = chan
        XCTAssertEqual(chan.unsentEvents.count, 0, "no events should have been queued yet")
        chan.trigger(eventName: TestObjects.Event.clientEventName, data: [Constants.JSONKeys.data: "testing client events"])
        chan.trigger(eventName: TestObjects.Event.clientEventName, data: [Constants.JSONKeys.data: "more testing client events"])
        XCTAssertEqual(chan.unsentEvents.last!.name, TestObjects.Event.clientEventName)
        XCTAssertEqual(chan.unsentEvents.count, 2, "two events should have been queued")
        XCTAssertEqual(socket.stubber.calls.count, 0, "no events should have been sent yet")

        let ex = expectation(description: "send client event eventually")
        socket.stubber.registerCallback { calls in
            guard let lastCall = calls.last, lastCall.name == "writeString" else {
                return
            }

            let parsedSubscribeArgs = convertStringToDictionary(lastCall.args!.first as! String)
            let expectedDict = [Constants.JSONKeys.data: [Constants.JSONKeys.data: "more testing client events"], Constants.JSONKeys.event: TestObjects.Event.clientEventName, Constants.JSONKeys.channel: TestObjects.Event.privateChannelName] as [String: Any]
            let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject: AnyObject])
            if parsedEqualsExpected {
                ex.fulfill()
            }
        }
        connection.connect()
        waitForExpectations(timeout: 0.5)
    }
}
