//
//  PusherConnectionDelegateTests.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 14/09/2016.
//
//

import PusherSwift
import XCTest

class PusherConnectionDelegateTests: XCTestCase {
    open class DummyDelegate: PusherConnectionDelegate {
        open let stubber = StubberForMocks()
        open var socket: MockWebSocket? = nil
        open var ex: XCTestExpectation? = nil
        var testingChannelName: String? = nil

        open func connectionStateDidChange(from old: ConnectionState, to new: ConnectionState) {
            let _ = stubber.stub(
                functionName: "connectionChange",
                args: [old, new],
                functionToCall: nil
            )
        }

        open func debugLog(message: String) {
            if message.range(of: "websocketDidReceiveMessage") != nil {
                self.socket?.appendToCallbackCheckString(message)
            }
        }

        open func subscriptionDidSucceed(channelName: String) {
            if let cName = testingChannelName, cName == channelName {
                ex!.fulfill()
            }
        }

        open func subscriptionDidFail(channelName: String, response: URLResponse?, data: String?, error: NSError?) {
            if let cName = testingChannelName, cName == channelName {
                ex!.fulfill()
            }
        }
    }

    var key: String!
    var pusher: Pusher!
    var socket: MockWebSocket!
    var dummyDelegate: DummyDelegate!

    override func setUp() {
        super.setUp()

        pusher = Pusher(key: "key", options: PusherClientOptions(authMethod: .inline(secret: "superSecretSecret"), autoReconnect: false))
        socket = MockWebSocket()
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        dummyDelegate = DummyDelegate()
        dummyDelegate.socket = socket
        pusher.connection.delegate = dummyDelegate
    }

    func testConnectionStateChangeDelegateFunctionGetsCalledTwiceGoingFromDisconnectedToConnectingToConnected() {
        XCTAssertEqual(pusher.connection.connectionState, ConnectionState.disconnected)
        pusher.connect()
        XCTAssertEqual(pusher.connection.connectionState, ConnectionState.connected)
        XCTAssertEqual(dummyDelegate.stubber.calls.first?.name, "connectionChange")
        XCTAssertEqual(dummyDelegate.stubber.calls.first?.args?.first as? ConnectionState, ConnectionState.disconnected)
        XCTAssertEqual(dummyDelegate.stubber.calls.first?.args?.last as? ConnectionState, ConnectionState.connecting)
        XCTAssertEqual(dummyDelegate.stubber.calls.last?.name, "connectionChange")
        XCTAssertEqual(dummyDelegate.stubber.calls.last?.args?.first as? ConnectionState, ConnectionState.connecting)
        XCTAssertEqual(dummyDelegate.stubber.calls.last?.args?.last as? ConnectionState, ConnectionState.connected)
    }

    func testConnectionStateChangeDelegateFunctionGetsCalledFourTimesGoingFromDisconnectedToConnectingToConnectedToDisconnectingToDisconnected() {
        XCTAssertEqual(pusher.connection.connectionState, ConnectionState.disconnected)
        pusher.connect()
        XCTAssertEqual(pusher.connection.connectionState, ConnectionState.connected)
        pusher.disconnect()
        XCTAssertEqual(dummyDelegate.stubber.calls.count, 4)
        XCTAssertEqual(dummyDelegate.stubber.calls[2].name, "connectionChange")
        XCTAssertEqual(dummyDelegate.stubber.calls[2].args?.first as? ConnectionState, ConnectionState.connected)
        XCTAssertEqual(dummyDelegate.stubber.calls[2].args?.last as? ConnectionState, ConnectionState.disconnecting)
        XCTAssertEqual(dummyDelegate.stubber.calls.last?.name, "connectionChange")
        XCTAssertEqual(dummyDelegate.stubber.calls.last?.args?.first as? ConnectionState, ConnectionState.disconnecting)
        XCTAssertEqual(dummyDelegate.stubber.calls.last?.args?.last as? ConnectionState, ConnectionState.disconnected)
    }

    func testPassingIncomingMessagesToTheDebugLogFunctionIfOneIsImplemented() {
        pusher.connect()

        XCTAssertEqual(socket.callbackCheckString, "[PUSHER DEBUG] websocketDidReceiveMessage {\"event\":\"pusher:connection_established\",\"data\":\"{\\\"socket_id\\\":\\\"45481.3166671\\\",\\\"activity_timeout\\\":120}\"}")
    }

    func testsubscriptionDidSucceedDelegateFunctionGetsCalledWhenChannelSubscriptionSucceeds() {
        let ex = expectation(description: "the subscriptionDidSucceed function should be called")
        let channelName = "private-channel"
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName

        let _ = pusher.subscribe(channelName)
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testsubscriptionDidFailDelegateFunctionGetsCalledWhenChannelSubscriptionFails() {
        let ex = expectation(description: "the subscriptionDidFail function should be called")
        let channelName = "private-channel"
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName
        pusher.connection.options.authMethod = .noMethod

        let _ = pusher.subscribe(channelName)
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }
}
