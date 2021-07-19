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

        let chan = pusher.subscribe(TestObjects.Event.testChannelName)
        connectionDelegate.registerCallback(connectionState: ConnectionState.disconnected) {
            XCTAssertFalse(chan.subscribed)
            disconnected.fulfill()
        }

        chan.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { (_: PusherEvent) in
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
        let chan = pusher.subscribe(TestObjects.Event.testChannelName)
        XCTAssertEqual(chan.name, TestObjects.Event.testChannelName, "the channel name should be \(TestObjects.Event.testChannelName)")
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no event handlers")
    }

    func testCallingSubscribeAfterSuccessfulConnectionSendsSubscribeEventOverSocket() {
        let delegate = ConnectionStateDelegate()
        pusher.delegate = delegate

        let connected = expectation(description: "should connect")
        let subscribed = expectation(description: "should subscribe")

        delegate.registerCallback(connectionState: ConnectionState.connected) {
            connected.fulfill()
            _ = self.pusher.subscribe(TestObjects.Event.testChannelName)

            self.socket.stubber.registerCallback { calls in
                guard let name = calls.last?.name, name == "writeString" else {
                    return
                }

                let parsedSubscribeArgs = convertStringToDictionary(calls.last?.args!.first as! String)
                let expectedDict = [Constants.JSONKeys.data: [Constants.JSONKeys.channel: TestObjects.Event.testChannelName], Constants.JSONKeys.event: Constants.Events.Pusher.subscribe] as [String: Any]
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
        let channel = pusher.subscribe(TestObjects.Event.testChannelName)
        channel.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { (_: PusherEvent) in
            let testChannel = self.pusher.connection.channels.channels[TestObjects.Event.testChannelName]
            XCTAssertTrue(testChannel!.subscribed)
            subscribed.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }

    func testSubscriptionSucceededEventSentToGlobalChannelViaEventCallback() {
        let ex = expectation(description: "should call global callback")
        pusher.connect()
        pusher.bind { event in
            XCTAssertEqual(event.eventName, Constants.Events.Pusher.subscriptionSucceeded)
            ex.fulfill()
        }
        _ = pusher.subscribe(TestObjects.Event.testChannelName)
        waitForExpectations(timeout: 0.5)
    }

    func testSubscriptionSucceededEventSentToChannelCallbackViaEventCallback() {
        let ex = expectation(description: "should call channel callback")
        let channel = pusher.subscribe(TestObjects.Event.testChannelName)
        channel.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { event in
            ex.fulfill()
        }
        pusher.connect()
        waitForExpectations(timeout: 0.5)
    }

    /* authenticated channels */

    func testAuthenticatedChannelIsSetupCorrectly() {
        pusher.connect()
        let chan = pusher.subscribe(TestObjects.Event.privateChannelName)
        XCTAssertEqual(chan.name, TestObjects.Event.privateChannelName, "the channel name should be \(TestObjects.Event.privateChannelName)")
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no event handlers")
    }

    func testSubscribingToAPrivateChannel() {
        let ex = expectation(description: "the channel should be subscribed to successfully")

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = TestObjects.Event.privateChannelName
        pusher.delegate = dummyDelegate

        pusher.connect()
        _ = pusher.subscribe(TestObjects.Event.privateChannelName)

        waitForExpectations(timeout: 0.5)
    }

    func testSubscribingToAPresenceChannel() {
        let ex = expectation(description: "the channel should be subscribed to successfully")

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = TestObjects.Event.presenceChannelName
        pusher.delegate = dummyDelegate

        pusher.connect()
        _ = pusher.subscribe(TestObjects.Event.presenceChannelName)

        waitForExpectations(timeout: 0.5)
    }

    /* subscribing to channels when starting disconnected */

    func testChannelIsSetupCorrectlyWhenSubscribingStartingDisconnected() {
        let chan = pusher.subscribe(TestObjects.Event.testChannelName)
        pusher.connect()
        XCTAssertEqual(chan.name, TestObjects.Event.testChannelName, "the channel name should be \(TestObjects.Event.testChannelName)")
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no event handlers")
    }

    func testSubscribingToAPublicChannelWhenCurrentlyDisconnected() {
        let subscribed = expectation(description: "should subscribe")
        _ = pusher.subscribe(TestObjects.Event.testChannelName)
        let testChannel = pusher.connection.channels.channels[TestObjects.Event.testChannelName]
        testChannel!.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { (_: PusherEvent) in
            XCTAssertTrue(testChannel!.subscribed)
            subscribed.fulfill()
        }
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    /* authenticated channels */

    func testAuthenticatedChannelIsSetupCorrectlyWhenSubscribingStartingDisconnected() {
        let chan = pusher.subscribe(TestObjects.Event.privateChannelName)
        pusher.connect()
        XCTAssertEqual(chan.name, TestObjects.Event.privateChannelName, "the channel name should be \(TestObjects.Event.privateChannelName)")
        XCTAssertEqual(chan.eventHandlers.count, 0, "the channel should have no event handlers")
    }

    func testSubscribingToAPrivateChannelWhenStartingDisconnected() {
        let ex = expectation(description: "the channel should be subscribed to successfully")

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = TestObjects.Event.privateChannelName
        pusher.connection.delegate = dummyDelegate

        _ = pusher.subscribe(TestObjects.Event.privateChannelName)
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testSubscribingToAPresenceChannelWhenStartingDisconnected() {
        let ex = expectation(description: "the channel should be subscribed to successfully")

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = TestObjects.Event.presenceChannelName
        pusher.connection.delegate = dummyDelegate

        _ = pusher.subscribe(TestObjects.Event.presenceChannelName)
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    /* unsubscribing */

    func testUnsubscribingFromAChannelRemovesTheChannel() {
        pusher.connect()
        let chan = pusher.subscribe(TestObjects.Event.testChannelName)
        let ex = expectation(description: "the channel should be subscribed to successfully")
        chan.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { (_: PusherEvent) in
            XCTAssertNotNil(self.pusher.connection.channels.channels[TestObjects.Event.testChannelName], "\(TestObjects.Event.testChannelName) should exist")
            self.pusher.unsubscribe(TestObjects.Event.testChannelName)
            XCTAssertNil(self.pusher.connection.channels.channels[TestObjects.Event.testChannelName], "\(TestObjects.Event.testChannelName) should not exist")
            ex.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }

    func testUnsubscribingFromAChannelSendsUnsubscribeEventOverSocket() {
        pusher.connect()
        let chan = pusher.subscribe(TestObjects.Event.testChannelName)
        chan.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { (_: PusherEvent) in
            self.pusher.unsubscribe(TestObjects.Event.testChannelName)
        }
        let ex = expectation(description: "should send unsubscribe")
        socket.stubber.registerCallback { calls in
            guard let name = calls.last?.name,
                  name == "writeString" else {
                return
            }

            let parsedSubscribeArgs = convertStringToDictionary(calls.last?.args!.first as! String)
            let expectedDict = [Constants.JSONKeys.data: [Constants.JSONKeys.channel: TestObjects.Event.testChannelName], Constants.JSONKeys.event: Constants.Events.Pusher.unsubscribe] as [String: Any]
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
        let channels = [TestObjects.Event.testChannelName, "test-channel2"]

        let dispatchGroup = DispatchGroup()
        for channel in channels {
            dispatchGroup.enter()
            let chan = self.pusher.subscribe(channel)
            chan.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { (_: PusherEvent) in
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
                    let expectedCallArguments = [Constants.JSONKeys.data: [Constants.JSONKeys.channel: channel], Constants.JSONKeys.event: Constants.Events.Pusher.unsubscribe] as [String: Any]
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

    func testBindingToEventsGloballyAddsACallbackToTheGlobalChannel() {
        pusher.connect()

        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 0, "the global channel should not have any bound callbacks")
        pusher.bind { event in }
        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 1, "the global channel should have 1 bound callback")
    }

    func testUnbindingAGlobalEventCallbackRemovesItFromTheGlobalChannelsCallbackList() {
        pusher.connect()
        let callBackId = pusher.bind { event in }

        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 1, "the global channel should have 1 bound callback")
        pusher.unbind(callbackId: callBackId)
        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 0, "the global channel should not have any bound callbacks")
    }

    func testUnbindingAllGlobalCallbacksShouldRemoveAllCallbacksFromGlobalChannel() {
        pusher.connect()
        pusher.bind { event in }

        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 1, "the global channel should have 1 bound regular callback")
        pusher.unbindAll()
        XCTAssertEqual(pusher.connection.globalChannel?.globalCallbacks.count, 0, "the global channel should not have any bound regular callbacks")
    }
}
