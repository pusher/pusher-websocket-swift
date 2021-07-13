import XCTest

@testable import PusherSwift

class PusherConnectionDelegateTests: XCTestCase {
    private class DummyDelegate: PusherDelegate {
        let stubber = StubberForMocks()
        var socket: MockWebSocket?
        var ex: XCTestExpectation?
        var testingChannelName: String?

        func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
            _ = stubber.stub(
                functionName: "connectionChange",
                args: [old, new],
                functionToCall: nil
            )
        }

        func debugLog(message: String) {
            if message.range(of: "websocketDidReceiveMessage") != nil {
                self.socket?.appendToCallbackCheckString(message)
            }
        }

        func subscribedToChannel(name: String) {
            guard let cName = testingChannelName, cName == name else {
                return
            }

            ex!.fulfill()
        }

        func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?) {
            guard let cName = testingChannelName, cName == name else {
                return
            }

            ex!.fulfill()
        }

        func receivedError(error: PusherError) {
            _ = stubber.stub(
                functionName: "error",
                args: [error],
                functionToCall: nil
            )
        }
    }

    private var key: String!
    private var pusher: Pusher!
    private var socket: MockWebSocket!
    // swiftlint:disable:next weak_delegate
    private var dummyDelegate: DummyDelegate!

    override func setUp() {
        super.setUp()

        pusher = Pusher(key: "key", options: PusherClientOptions(authMethod: .inline(secret: "superSecretSecret"), autoReconnect: false))
        socket = MockWebSocket()
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        dummyDelegate = DummyDelegate()
        dummyDelegate.socket = socket
        pusher.delegate = dummyDelegate
    }

    func testUnitentionalDisconnectionThatShouldNotReconnect() {
        let isConnected = expectation(description: "there should be 2 calls to changedConnectionState to connected")
        let isDisconnected = expectation(description: "there should be 4 calls to changedConnectionState to disconnected")
        XCTAssertEqual(pusher.connection.connectionState, ConnectionState.disconnected)
        dummyDelegate.stubber.registerCallback { calls in
            if calls.count == 2 {
                XCTAssertEqual(calls.first?.name, "connectionChange")
                XCTAssertEqual(calls.first?.args?.first as? ConnectionState, ConnectionState.disconnected)
                XCTAssertEqual(calls.first?.args?.last as? ConnectionState, ConnectionState.connecting)
                XCTAssertEqual(calls.last?.name, "connectionChange")
                XCTAssertEqual(calls.last?.args?.first as? ConnectionState, ConnectionState.connecting)
                XCTAssertEqual(calls.last?.args?.last as? ConnectionState, ConnectionState.connected)
                isConnected.fulfill()

                // Spoof an unintentional disconnection event (that should not reconnect)
                self.socket.disconnect(closeCode: .privateCode(ChannelsProtocolCloseCode.connectionIsUnauthorized.rawValue))
            } else if calls.count == 3 {
                XCTAssertEqual(calls[0].name, "connectionChange")
                XCTAssertEqual(calls[0].args?.first as? ConnectionState, ConnectionState.disconnected)
                XCTAssertEqual(calls[0].args?.last as? ConnectionState, ConnectionState.connecting)
                XCTAssertEqual(calls[1].name, "connectionChange")
                XCTAssertEqual(calls[1].args?.first as? ConnectionState, ConnectionState.connecting)
                XCTAssertEqual(calls[1].args?.last as? ConnectionState, ConnectionState.connected)
                XCTAssertEqual(calls[2].name, "connectionChange")
                XCTAssertEqual(calls[2].args?.first as? ConnectionState, ConnectionState.connected)
                XCTAssertEqual(calls[2].args?.last as? ConnectionState, ConnectionState.disconnected)
                isDisconnected.fulfill()
            }
        }
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testUnitentionalDisconnectionThatShouldReconnect() {
        let isConnected = expectation(description: "there should be 2 calls to changedConnectionState to connected")
        let isDisconnected = expectation(description: "there should be 4 calls to changedConnectionState to disconnected")
        XCTAssertEqual(pusher.connection.connectionState, ConnectionState.disconnected)
        dummyDelegate.stubber.registerCallback { calls in
            if calls.count == 2 {
                XCTAssertEqual(calls.first?.name, "connectionChange")
                XCTAssertEqual(calls.first?.args?.first as? ConnectionState, ConnectionState.disconnected)
                XCTAssertEqual(calls.first?.args?.last as? ConnectionState, ConnectionState.connecting)
                XCTAssertEqual(calls.last?.name, "connectionChange")
                XCTAssertEqual(calls.last?.args?.first as? ConnectionState, ConnectionState.connecting)
                XCTAssertEqual(calls.last?.args?.last as? ConnectionState, ConnectionState.connected)
                isConnected.fulfill()

                // Spoof an unintentional disconnection event (that should attempt a reconnect)
                self.socket.disconnect(closeCode: .privateCode(ChannelsProtocolCloseCode.genericReconnectImmediately.rawValue))
            } else if calls.count == 6 {
                XCTAssertEqual(calls[0].name, "connectionChange")
                XCTAssertEqual(calls[0].args?.first as? ConnectionState, ConnectionState.disconnected)
                XCTAssertEqual(calls[0].args?.last as? ConnectionState, ConnectionState.connecting)
                XCTAssertEqual(calls[1].name, "connectionChange")
                XCTAssertEqual(calls[1].args?.first as? ConnectionState, ConnectionState.connecting)
                XCTAssertEqual(calls[1].args?.last as? ConnectionState, ConnectionState.connected)
                XCTAssertEqual(calls[2].name, "connectionChange")
                XCTAssertEqual(calls[2].args?.first as? ConnectionState, ConnectionState.connected)
                XCTAssertEqual(calls[2].args?.last as? ConnectionState, ConnectionState.disconnected)
                XCTAssertEqual(calls[3].name, "connectionChange")
                XCTAssertEqual(calls[3].args?.first as? ConnectionState, ConnectionState.disconnected)
                XCTAssertEqual(calls[3].args?.last as? ConnectionState, ConnectionState.reconnecting)
                XCTAssertEqual(calls[4].name, "connectionChange")
                XCTAssertEqual(calls[4].args?.first as? ConnectionState, ConnectionState.reconnecting)
                XCTAssertEqual(calls[4].args?.last as? ConnectionState, ConnectionState.connecting)
                XCTAssertEqual(calls[5].name, "connectionChange")
                XCTAssertEqual(calls[5].args?.first as? ConnectionState, ConnectionState.connecting)
                XCTAssertEqual(calls[5].args?.last as? ConnectionState, ConnectionState.connected)
                isDisconnected.fulfill()
            }
        }
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testConnectionStateChangeDelegateFunctionGetsCalledTwiceGoingFromDisconnectedToConnectingToConnected() {
        let ex = expectation(description: "there should be 2 calls to changedConnectionState")
        XCTAssertEqual(pusher.connection.connectionState, ConnectionState.disconnected)
        pusher.connect()
        dummyDelegate.stubber.registerCallback { calls in
            if calls.count == 2 {
                XCTAssertEqual(calls.first?.name, "connectionChange")
                XCTAssertEqual(calls.first?.args?.first as? ConnectionState, ConnectionState.disconnected)
                XCTAssertEqual(calls.first?.args?.last as? ConnectionState, ConnectionState.connecting)
                XCTAssertEqual(calls.last?.name, "connectionChange")
                XCTAssertEqual(calls.last?.args?.first as? ConnectionState, ConnectionState.connecting)
                XCTAssertEqual(calls.last?.args?.last as? ConnectionState, ConnectionState.connected)
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 0.5)
    }

    func testConnectionStateChangeDelegateFunctionGetsCalledFourTimesGoingFromDisconnectedToConnectingToConnectedToDisconnectingToDisconnected() {
        let isConnected = expectation(description: "there should be 2 calls to changedConnectionState to connected")
        let isDisconnected = expectation(description: "there should be 2 calls to changedConnectionState to disconnected")
        dummyDelegate.stubber.registerCallback { calls in
            if calls.count == 2 {
                XCTAssertEqual(calls.last?.args?.last as? ConnectionState, ConnectionState.connected)
                isConnected.fulfill()
                self.pusher.disconnect()
            } else if calls.count == 4 {
                XCTAssertEqual(calls[2].name, "connectionChange")
                XCTAssertEqual(calls[2].args?.first as? ConnectionState, ConnectionState.connected)
                XCTAssertEqual(calls[2].args?.last as? ConnectionState, ConnectionState.disconnecting)
                XCTAssertEqual(calls.last?.name, "connectionChange")
                XCTAssertEqual(calls.last?.args?.first as? ConnectionState, ConnectionState.disconnecting)
                XCTAssertEqual(calls.last?.args?.last as? ConnectionState, ConnectionState.disconnected)
                isDisconnected.fulfill()
            }
        }
        pusher.connect()
        waitForExpectations(timeout: 0.5)
    }

    func testPassingIncomingMessagesToTheDebugLogFunctionIfOneIsImplemented() {
        pusher.connect()

        XCTAssertEqual(socket.callbackCheckString, "[PUSHER DEBUG] websocketDidReceiveMessage {\"\(Constants.JSONKeys.event)\":\"\(Constants.Events.Pusher.connectionEstablished)\",\"\(Constants.JSONKeys.data)\":\"{\\\"\(Constants.JSONKeys.socketId)\\\":\\\"45481.3166671\\\",\\\"activity_timeout\\\":120}\"}")
    }

    func testsubscriptionDidSucceedDelegateFunctionGetsCalledWhenChannelSubscriptionSucceeds() {
        let ex = expectation(description: "the subscriptionDidSucceed function should be called")
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = TestObjects.Event.privateChannelName

        _ = pusher.subscribe(TestObjects.Event.privateChannelName)
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testsubscriptionDidFailDelegateFunctionGetsCalledWhenChannelSubscriptionFails() {
        let ex = expectation(description: "the subscriptionDidFail function should be called")
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = TestObjects.Event.privateChannelName
        pusher.connection.options.authMethod = .noMethod

        _ = pusher.subscribe(TestObjects.Event.privateChannelName)
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testErrorFunctionCalledWhenPusherErrorIsReceived() {
        let payload = "{\"\(Constants.JSONKeys.event)\":\"\(Constants.Events.Pusher.error)\", \"\(Constants.JSONKeys.data)\":{\"\(Constants.JSONKeys.message)\":\"Application is over connection quota\",\"code\":4004}}"
        pusher.connection.webSocketDidReceiveMessage(connection: socket, string: payload)

        XCTAssertEqual(dummyDelegate.stubber.calls.last?.name, "error")
        guard let error = dummyDelegate.stubber.calls.last?.args?.first as? PusherError else {
            XCTFail("PusherError not returned")
            return
        }

        XCTAssertEqual(error.message, "Application is over connection quota")
        XCTAssertEqual(error.code!, 4004)
    }
}
