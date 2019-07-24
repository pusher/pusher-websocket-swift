import PusherSwift
import XCTest

class PusherTopLevelApiTests: XCTestCase {
    class DummyDelegate: PusherDelegate {
        var ex: XCTestExpectation? = nil
        var testingChannelName: String? = nil

        func subscribedToChannel(name: String) {
            if let cName = testingChannelName, cName == name {
                ex!.fulfill()
            }
        }
    }

    var key: String!
    var pusher: Pusher!
    var socket: MockWebSocket!

    override func setUp() {
        super.setUp()

        key = "testKey123"
        let options = PusherClientOptions(
            authMethod: AuthMethod.inline(secret: "secret"),
            autoReconnect: false
        )

        pusher = Pusher(key: key, options: options)
        socket = MockWebSocket()
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
    }

    func testCallingConnectCallsConnectOnTheSocket() {
        pusher.connect()
        XCTAssertEqual(socket.stubber.calls[0].name, "connect")
    }

    func testConnectedPropertyIsTrueWhenConnectionConnects() {
        pusher.connect()
        XCTAssertEqual(pusher.connection.connectionState, ConnectionState.connected)
    }

    func testCallingDisconnectCallsDisconnectOnTheSocket() {
        pusher.connect()
        pusher.disconnect()
        XCTAssertEqual(socket.stubber.calls[1].name, "disconnect")
    }

    func testConnectedPropertyIsFalseWhenConnectionDisconnects() {
        pusher.connect()
        XCTAssertEqual(pusher.connection.connectionState, ConnectionState.connected)
        pusher.disconnect()
        XCTAssertEqual(pusher.connection.connectionState, ConnectionState.disconnected)
    }

    func testCallingDisconnectSetsTheSubscribedPropertyOfChannelsToFalse() {
        pusher.connect()
        let chan = pusher.subscribe("test-channel")
        XCTAssertTrue(chan.subscribed)
        pusher.disconnect()
        XCTAssertFalse(chan.subscribed)
    }

    /* subscribing to channels when already connected */

    /* public channels */

    func testChannelIsSetupCorrectly() {
        pusher.connect()
        let chan = pusher.subscribe("test-channel")
        XCTAssertEqual(chan.name, "test-channel", "the channel name should be test-channel")
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no event handlers")
    }

    func testCallingSubscribeAfterSuccessfulConnectionSendsSubscribeEventOverSocket() {
        pusher.connect()
        let _ = pusher.subscribe("test-channel")

        XCTAssertEqual(socket.stubber.calls.last?.name, "writeString", "the write function should have been called")
        let parsedSubscribeArgs = convertStringToDictionary(socket.stubber.calls.last?.args!.first as! String)
        let expectedDict = ["data": ["channel": "test-channel"], "event": "pusher:subscribe"] as [String: Any]
        let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject: AnyObject])
        XCTAssertTrue(parsedEqualsExpected)
    }

    func testSubscribingToAPublicChannel() {
        pusher.connect()
        let _ = pusher.subscribe("test-channel")
        let testChannel = pusher.connection.channels.channels["test-channel"]
        XCTAssertTrue(testChannel!.subscribed)
    }

    func testSubscriptionSucceededEventSentToGlobalChannelViaDataCallback() {
        pusher.connect()
        let callback = { (data: Any?) -> Void in
            if let data = data as? [String: Any], let eName = data["event"] as? String, eName == "pusher:subscription_succeeded" {
                self.socket.appendToCallbackCheckString("globalCallbackCalled")
            }
        }
        let _ = pusher.bind(callback)
        XCTAssertEqual(socket.callbackCheckString, "")
        let _ = pusher.subscribe("test-channel")
        XCTAssertEqual(socket.callbackCheckString, "globalCallbackCalled")
    }

    func testSubscriptionSucceededEventSentToChannelCallbackViaDataCallback() {
        let callback = { (data: Any?) -> Void in
            self.socket.appendToCallbackCheckString("channelCallbackCalled")
        }
        XCTAssertEqual(socket.callbackCheckString, "")
        let channel = pusher.subscribe("test-channel")
        let _ = channel.bind(eventName: "pusher:subscription_succeeded", callback: callback)
        pusher.connect()
        XCTAssertEqual(socket.callbackCheckString, "channelCallbackCalled")
    }

    func testSubscriptionSucceededEventSentToGlobalChannelViaEventCallback() {
        pusher.connect()
        let callback = { (event: PusherEvent) -> Void in
            if event.event == "pusher:subscription_succeeded" {
                self.socket.appendToCallbackCheckString("globalCallbackCalled")
            }
        }
        let _ = pusher.bind(eventCallback: callback)
        XCTAssertEqual(socket.callbackCheckString, "")
        let _ = pusher.subscribe("test-channel")
        XCTAssertEqual(socket.callbackCheckString, "globalCallbackCalled")
    }

    func testSubscriptionSucceededEventSentToChannelCallbackViaEventCallback() {
        let callback = { (event: PusherEvent) -> Void in
            self.socket.appendToCallbackCheckString("channelCallbackCalled")
        }
        XCTAssertEqual(socket.callbackCheckString, "")
        let channel = pusher.subscribe("test-channel")
        let _ = channel.bind(eventName: "pusher:subscription_succeeded", eventCallback: callback)
        pusher.connect()
        XCTAssertEqual(socket.callbackCheckString, "channelCallbackCalled")
    }

    /* authenticated channels */

    func testAuthenticatedChannelIsSetupCorrectly() {
        pusher.connect()
        let chan = pusher.subscribe("private-channel")
        XCTAssertEqual(chan.name, "private-channel", "the channel name should be private-channel")
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no event handlers")
    }

    func testSubscribingToAPrivateChannel() {
        let ex = expectation(description: "the channel should be subscribed to successfully")
        let channelName = "private-channel"

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName
        pusher.delegate = dummyDelegate

        pusher.connect()
        let _ = pusher.subscribe(channelName)

        waitForExpectations(timeout: 0.5)
    }

    func testSubscribingToAPresenceChannel() {
        let ex = expectation(description: "the channel should be subscribed to successfully")
        let channelName = "presence-channel"

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName
        pusher.delegate = dummyDelegate

        pusher.connect()
        let _ = pusher.subscribe(channelName)

        waitForExpectations(timeout: 0.5)
    }

    /* subscribing to channels when starting disconnected */

    func testChannelIsSetupCorrectlyWhenSubscribingStartingDisconnected() {
        let chan = pusher.subscribe("test-channel")
        pusher.connect()
        XCTAssertEqual(chan.name, "test-channel", "the channel name should be test-channel")
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no event handlers")
    }

    func testSubscribingToAPublicChannelWhenCurrentlyDisconnected() {
        let _ = pusher.subscribe("test-channel")
        let testChannel = pusher.connection.channels.channels["test-channel"]
        pusher.connect()
        XCTAssertTrue(testChannel!.subscribed)
    }

    /* authenticated channels */

    func testAuthenticatedChannelIsSetupCorrectlyWhenSubscribingStartingDisconnected() {
        let chan = pusher.subscribe("private-channel")
        pusher.connect()
        XCTAssertEqual(chan.name, "private-channel", "the channel name should be private-channel")
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no event handlers")
    }

    func testSubscribingToAPrivateChannelWhenStartingDisconnected() {
        let ex = expectation(description: "the channel should be subscribed to successfully")
        let channelName = "private-channel"

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName
        pusher.connection.delegate = dummyDelegate

        let _ = pusher.subscribe(channelName)
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testSubscribingToAPresenceChannelWhenStartingDisconnected() {
        let ex = expectation(description: "the channel should be subscribed to successfully")
        let channelName = "presence-channel"

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName
        pusher.connection.delegate = dummyDelegate

        let _ = pusher.subscribe(channelName)
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    /* unsubscribing */

    func testUnsubscribingFromAChannelRemovesTheChannel() {
        pusher.connect()
        let _ = pusher.subscribe("test-channel")

        XCTAssertNotNil(pusher.connection.channels.channels["test-channel"], "test-channel should exist")
        pusher.unsubscribe("test-channel")
        XCTAssertNil(pusher.connection.channels.channels["test-channel"], "test-channel should not exist")
    }

    func testUnsubscribingFromAChannelSendsUnsubscribeEventOverSocket() {
        pusher.connect()
        let _ = pusher.subscribe("test-channel")
        pusher.unsubscribe("test-channel")

        XCTAssertEqual(socket.stubber.calls.last?.name, "writeString", "write function should have been called")

        let parsedSubscribeArgs = convertStringToDictionary(socket.stubber.calls.last?.args!.first as! String)
        let expectedDict = ["data": ["channel": "test-channel"], "event": "pusher:unsubscribe"] as [String: Any]
        let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject: AnyObject])

        XCTAssertTrue(parsedEqualsExpected)
    }

    func testUnsubscribingFromAllChannelsRemovesTheChannels() {
        pusher.connect()
        let channels = ["test-channel", "test-channel2"]

        for channel in channels {
            let _ = pusher.subscribe(channel)
        }

        XCTAssertEqual(pusher.connection.channels.channels.count, channels.count, "should have \(channels.count) channels")
        XCTAssertEqual(socket.stubber.calls.last?.name, "writeString", "write function should have been called")
        pusher.unsubscribeAll()

        for channel in channels {
            let expectedCallArguments = ["data": ["channel": channel], "event": "pusher:unsubscribe"] as [String: Any]
            let unsubscribedFromChannel = socket.stubber.calls.contains { call in
                guard
                    call.name == "writeString",
                    let arguments = call.args,
                    let firstArg = arguments.first,
                    let stringFirstArg = firstArg as? String,
                    let parsedCallArgs = convertStringToDictionary(stringFirstArg)
                else {
                    return false
                }
                return NSDictionary(dictionary: parsedCallArgs).isEqual(to: NSDictionary(dictionary: expectedCallArguments) as [NSObject: AnyObject])
            }
            XCTAssertTrue(unsubscribedFromChannel, "should have unsubscribed from \(channel)")
        }

        XCTAssertEqual(pusher.connection.channels.channels.count, 0, "should have no channels")
    }

    /* global channel interactions */

    func testBindingToEventsGloballyAddsACallbackToTheGlobalChannel() {
        pusher.connect()
        let callback = { (data: Any?) in }

        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 0, "the global channel should not have any bound callbacks")
        let _ = pusher.bind(callback)
        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 1, "the global channel should have 1 bound callback")
    }

    func testUnbindingAGlobalDataCallbackRemovesItFromTheGlobalChannelsCallbackList() {
        pusher.connect()
        let callback = { (data: Any?) in }
        let callBackId = pusher.bind(callback)

        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 1, "the global channel should have 1 bound callback")
        pusher.unbind(callbackId: callBackId)
        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 0, "the global channel should not have any bound callbacks")
    }

    func testUnbindingAGlobalEventCallbackRemovesItFromTheGlobalChannelsCallbackList() {
        pusher.connect()
        let callback = { (event: PusherEvent) in }
        let callBackId = pusher.bind(eventCallback: callback)

        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 1, "the global channel should have 1 bound callback")
        pusher.unbind(callbackId: callBackId)
        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 0, "the global channel should not have any bound callbacks")
    }

    func testUnbindingAllGlobalCallbacksShouldRemoveAllCallbacksFromGlobalChannel() {
        pusher.connect()
        let callback = { (data: Any?) in }
        let _ = pusher.bind(callback)
        let callbackTwo = { (someData: Any?) in }
        let _ = pusher.bind(callbackTwo)

        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 2, "the global channel should have 2 bound callbacks")
        pusher.unbindAll()
        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 0, "the global channel should not have any bound callbacks")
    }
}
