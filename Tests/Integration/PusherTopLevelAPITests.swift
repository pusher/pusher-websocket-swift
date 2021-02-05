import XCTest

@testable import PusherSwift

// swiftlint:disable unused_closure_parameter

class PusherTopLevelApiTests: XCTestCase {

    private class ConnectionStateDelegate: PusherDelegate {
        var callbacks: [ConnectionState: [() -> Void]] = [:]

        func registerCallback(connectionState: ConnectionState, callback: @escaping () -> Void) {
            var connectionStateCallbacks = callbacks[connectionState, default: []]
            connectionStateCallbacks.append(callback)
            callbacks[connectionState] = connectionStateCallbacks
        }

        func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
            guard let stateCallbacks = callbacks[new] else {
                return
            }

            for callback in stateCallbacks {
                callback()
            }
        }
    }

    private class DummyDelegate: PusherDelegate {
        var ex: XCTestExpectation?
        var testingChannelName: String?
        var connectionStubber = StubberForMocks()

        func subscribedToChannel(name: String) {
            guard let cName = testingChannelName,
                  cName == name else {
                return
            }

            ex!.fulfill()
        }

        func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
            _ = connectionStubber.stub(
                functionName: "connectionChange",
                args: [old, new],
                functionToCall: nil
            )
        }
    }

    private var key: String!
    private var pusher: Pusher!
    private var socket: MockWebSocket!

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
        let delegate = DummyDelegate()
        pusher.delegate = delegate

        let ex = expectation(description: "should connect")
        delegate.connectionStubber.registerCallback { calls in
            if calls.last!.args![1] as! ConnectionState == ConnectionState.connected {
                XCTAssertEqual(self.pusher.connection.connectionState, ConnectionState.connected)
                ex.fulfill()
            }
        }
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testCallingDisconnectCallsDisconnectOnTheSocket() {
        pusher.connect()

        let delegate = DummyDelegate()
        pusher.delegate = delegate

        let ex = expectation(description: "should connect")
        delegate.connectionStubber.registerCallback { calls in
            if calls.last!.args![1] as! ConnectionState == ConnectionState.connected {
                self.pusher.disconnect()
                XCTAssertEqual(self.socket.stubber.calls.last!.name, "disconnect")
                ex.fulfill()
            }
        }
        pusher.connect()
        waitForExpectations(timeout: 0.5)
    }

    func testConnectedPropertyIsFalseWhenConnectionDisconnects() {
        let delegate = ConnectionStateDelegate()
        pusher.delegate = delegate

        let connected = expectation(description: "should connect")
        let disconnected = expectation(description: "should disconnect")

        delegate.registerCallback(connectionState: ConnectionState.connected) {
            XCTAssertEqual(self.pusher.connection.connectionState, ConnectionState.connected)
            connected.fulfill()
            self.pusher.disconnect()
        }

        delegate.registerCallback(connectionState: ConnectionState.disconnected) {
            XCTAssertEqual(self.pusher.connection.connectionState, ConnectionState.disconnected)
            disconnected.fulfill()
        }
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testCallingDisconnectSetsTheSubscribedPropertyOfChannelsToFalse() {
        let connectionDelegate = ConnectionStateDelegate()
        pusher.delegate = connectionDelegate

        let subscribed = expectation(description: "should subscribe")
        let disconnected = expectation(description: "should disconnect")

        let chan = pusher.subscribe("test-channel")
        connectionDelegate.registerCallback(connectionState: ConnectionState.disconnected) {
            XCTAssertFalse(chan.subscribed)
            disconnected.fulfill()
        }

        chan.bind(eventName: "pusher:subscription_succeeded") { (_: PusherEvent) in
            XCTAssertTrue(chan.subscribed)
            subscribed.fulfill()
            self.pusher.disconnect()
        }

        pusher.connect()
        waitForExpectations(timeout: 0.5)
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
        let delegate = ConnectionStateDelegate()
        pusher.delegate = delegate

        let connected = expectation(description: "should connect")
        let subscribed = expectation(description: "should subscribe")

        delegate.registerCallback(connectionState: ConnectionState.connected) {
            connected.fulfill()
            _ = self.pusher.subscribe("test-channel")

            self.socket.stubber.registerCallback { calls in
                guard let name = calls.last?.name, name == "writeString" else {
                    return
                }

                let parsedSubscribeArgs = convertStringToDictionary(calls.last?.args!.first as! String)
                let expectedDict = ["data": ["channel": "test-channel"], "event": "pusher:subscribe"] as [String: Any]
                let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject: AnyObject])
                XCTAssertTrue(parsedEqualsExpected)
                subscribed.fulfill()
            }
        }

        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testSubscribingToAPublicChannel() {
        pusher.connect()
        let subscribed = expectation(description: "should subscribe")
        let channel = pusher.subscribe("test-channel")
        channel.bind(eventName: "pusher:subscription_succeeded") { (_: PusherEvent) in
            let testChannel = self.pusher.connection.channels.channels["test-channel"]
            XCTAssertTrue(testChannel!.subscribed)
            subscribed.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }

    func testSubscriptionSucceededEventSentToGlobalChannelViaDataCallback() {
        let ex = expectation(description: "should call global callback")
        pusher.connect()
        let callback = { (data: Any?) -> Void in
            guard let data = data as? [String: Any],
                  let eName = data["event"] as? String,
                  eName == "pusher:subscription_succeeded" else {
                return
            }

            ex.fulfill()
        }
        _ = pusher.bind(callback)
        _ = pusher.subscribe("test-channel")
        waitForExpectations(timeout: 0.5)
    }

    func testSubscriptionSucceededEventSentToChannelCallbackViaDataCallback() {
        let ex = expectation(description: "should call channel callback")
        let callback = { (data: Any?) -> Void in
            ex.fulfill()
        }
        let channel = pusher.subscribe("test-channel")
        _ = channel.bind(eventName: "pusher:subscription_succeeded", callback: callback)
        pusher.connect()
        waitForExpectations(timeout: 0.5)
    }

    func testSubscriptionSucceededEventSentToGlobalChannelViaEventCallback() {
        let ex = expectation(description: "should call global callback")
        pusher.connect()
        let callback = { (event: PusherEvent) -> Void in
            if event.eventName == "pusher:subscription_succeeded" {
                ex.fulfill()
            }
        }
        _ = pusher.bind(eventCallback: callback)
        _ = pusher.subscribe("test-channel")
        waitForExpectations(timeout: 0.5)
    }

    func testSubscriptionSucceededEventSentToChannelCallbackViaEventCallback() {
        let ex = expectation(description: "should call channel callback")
        let callback = { (event: PusherEvent) -> Void in
            ex.fulfill()
        }
        let channel = pusher.subscribe("test-channel")
        _ = channel.bind(eventName: "pusher:subscription_succeeded", eventCallback: callback)
        pusher.connect()
        waitForExpectations(timeout: 0.5)
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
        _ = pusher.subscribe(channelName)

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
        _ = pusher.subscribe(channelName)

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
        let subscribed = expectation(description: "should subscribe")
        _ = pusher.subscribe("test-channel")
        let testChannel = pusher.connection.channels.channels["test-channel"]
        testChannel!.bind(eventName: "pusher:subscription_succeeded") { (_: PusherEvent) in
            XCTAssertTrue(testChannel!.subscribed)
            subscribed.fulfill()
        }
        pusher.connect()

        waitForExpectations(timeout: 0.5)
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

        _ = pusher.subscribe(channelName)
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

        _ = pusher.subscribe(channelName)
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    /* unsubscribing */

    func testUnsubscribingFromAChannelRemovesTheChannel() {
        pusher.connect()
        let chan = pusher.subscribe("test-channel")
        let ex = expectation(description: "the channel should be subscribed to successfully")
        chan.bind(eventName: "pusher:subscription_succeeded") { (_: PusherEvent) in
            XCTAssertNotNil(self.pusher.connection.channels.channels["test-channel"], "test-channel should exist")
            self.pusher.unsubscribe("test-channel")
            XCTAssertNil(self.pusher.connection.channels.channels["test-channel"], "test-channel should not exist")
            ex.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }

    func testUnsubscribingFromAChannelSendsUnsubscribeEventOverSocket() {
        pusher.connect()
        let chan = pusher.subscribe("test-channel")
        chan.bind(eventName: "pusher:subscription_succeeded") { (_: PusherEvent) in
            self.pusher.unsubscribe("test-channel")
        }
        let ex = expectation(description: "should send unsubscribe")
        socket.stubber.registerCallback { calls in
            guard let name = calls.last?.name,
                  name == "writeString" else {
                return
            }

            let parsedSubscribeArgs = convertStringToDictionary(calls.last?.args!.first as! String)
            let expectedDict = ["data": ["channel": "test-channel"], "event": "pusher:unsubscribe"] as [String: Any]
            let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject: AnyObject])
            if parsedEqualsExpected {
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 0.5)
    }

    func testUnsubscribingFromAllChannelsRemovesTheChannels() {
        self.continueAfterFailure = false
        let queue = DispatchQueue(label: "com.pusher.PusherSwift-Tests")

        pusher.connect()
        let channels = ["test-channel", "test-channel2"]

        let dispatchGroup = DispatchGroup()
        for channel in channels {
            dispatchGroup.enter()
            let chan = self.pusher.subscribe(channel)
            chan.bind(eventName: "pusher:subscription_succeeded") { (_: PusherEvent) in
                dispatchGroup.leave()
            }
        }

        let ex = expectation(description: "should send unsubscribe for all channels")
        queue.async {
            // Wait for all channels to subscribe
            let waitResult = dispatchGroup.wait(wallTimeout: DispatchWallTime.now() + .milliseconds(500))
            if waitResult == DispatchTimeoutResult.timedOut {
                XCTFail("Timed out waiting for subscribe")
            }

            XCTAssertEqual(self.pusher.connection.channels.channels.count, channels.count, "should have \(channels.count) channels")

            self.socket.stubber.registerCallback { calls in
                var unsubscribeCount = 0
                for channel in channels {
                    let expectedCallArguments = ["data": ["channel": channel], "event": "pusher:unsubscribe"] as [String: Any]
                    let unsubscribedFromChannel = calls.contains { call in
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
                    if unsubscribedFromChannel {
                        unsubscribeCount += 1
                    }
                }
                if unsubscribeCount == channels.count {
                    ex.fulfill()
                }
            }

            self.pusher.unsubscribeAll()
            XCTAssertEqual(self.pusher.connection.channels.channels.count, 0, "should have no channels")
        }
        waitForExpectations(timeout: 0.5)
    }

    /* global channel interactions */

    func testBindingToEventsGloballyAddsALegacyCallbackToTheGlobalChannel() {
        pusher.connect()
        let callback = { (data: Any?) in }

        XCTAssertEqual(pusher.connection.globalChannel?.globalLegacyCallbacks.count, 0, "the global channel should not have any bound callbacks")
        _ = pusher.bind(callback)
        XCTAssertEqual(pusher.connection.globalChannel?.globalLegacyCallbacks.count, 1, "the global channel should have 1 bound callback")
    }

    func testBindingToEventsGloballyAddsACallbackToTheGlobalChannel() {
        pusher.connect()
        let callback = { (data: PusherEvent?) in }

        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 0, "the global channel should not have any bound callbacks")
        _ = pusher.bind(eventCallback: callback)
        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 1, "the global channel should have 1 bound callback")
    }

    func testUnbindingAGlobalDataCallbackRemovesItFromTheGlobalChannelsCallbackList() {
        pusher.connect()
        let callback = { (data: Any?) in }
        let callBackId = pusher.bind(callback)

        XCTAssertEqual(pusher.connection.globalChannel?.globalLegacyCallbacks.count, 1, "the global channel should have 1 bound callback")
        pusher.unbind(callbackId: callBackId)
        XCTAssertEqual(pusher.connection.globalChannel?.globalLegacyCallbacks.count, 0, "the global channel should not have any bound callbacks")
    }

    func testUnbindingAGlobalEventCallbackRemovesItFromTheGlobalChannelsCallbackList() {
        pusher.connect()
        let callback = { (event: PusherEvent) in }
        let callBackId = pusher.bind(eventCallback: callback)

        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 1, "the global channel should have 1 bound callback")
        pusher.unbind(callbackId: callBackId)
        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 0, "the global channel should not have any bound callbacks")
    }

    func testUnbindingAllGlobalCallbacksShouldRemoveAllLegacyCallbacksFromGlobalChannel() {
        pusher.connect()
        let callback = { (data: Any?) in }
        _ = pusher.bind(callback)
        let callbackTwo = { (someData: Any?) in }
        _ = pusher.bind(callbackTwo)

        XCTAssertEqual(pusher.connection.globalChannel?.globalLegacyCallbacks.count, 2, "the global channel should have 2 bound callbacks")
        pusher.unbindAll()
        XCTAssertEqual(pusher.connection.globalChannel?.globalLegacyCallbacks.count, 0, "the global channel should not have any bound callbacks")
    }

    func testUnbindingAllGlobalCallbacksShouldRemoveAllCallbacksFromGlobalChannel() {
        pusher.connect()
        let callback = { (data: Any?) in }
        _ = pusher.bind(callback)
        let callbackTwo = { (someData: PusherEvent?) in }
        _ = pusher.bind(eventCallback: callbackTwo)

        XCTAssertEqual(pusher.connection.globalChannel?.globalLegacyCallbacks.count, 1, "the global channel should have 1 bound legacy callback")
        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 1, "the global channel should have 1 bound regular callback")
        pusher.unbindAll()
        XCTAssertEqual(pusher.connection.globalChannel?.globalLegacyCallbacks.count, 0, "the global channel should not have any bound legacy callbacks")
        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 0, "the global channel should not have any bound regular callbacks")
    }
}
