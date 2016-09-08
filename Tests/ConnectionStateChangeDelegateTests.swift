 //
 //  ConnectionStateChangeDelegateTests.swift
 //  PusherSwift
 //
 //  Created by Hamilton Chapman on 07/04/2016.
 //
 //

 import PusherSwift
 import XCTest

 class ConnectionStateChangeDelegateTests: XCTestCase {
    var pusher: Pusher!
    var socket: MockWebSocket!
    var stateChangeDelegate: TestConnectionStateChangeDelegate!

    override func setUp() {
        super.setUp()

        let options = PusherClientOptions(autoReconnect: false)
        pusher = Pusher(key: "key", options: options)
        socket = MockWebSocket()
        stateChangeDelegate = TestConnectionStateChangeDelegate()
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        pusher.connection.stateChangeDelegate = stateChangeDelegate
    }

    func testDelegateGetsCalledTwiceGoingFromDisconnectedToConnectingToConnected() {
        XCTAssertEqual(pusher.connection.connectionState, ConnectionState.disconnected)
        pusher.connect()
        XCTAssertEqual(pusher.connection.connectionState, ConnectionState.connected)
        XCTAssertEqual(stateChangeDelegate.stubber.calls.first?.name, "connectionChange")
        XCTAssertEqual(stateChangeDelegate.stubber.calls.first?.args?.first as? ConnectionState, ConnectionState.disconnected)
        XCTAssertEqual(stateChangeDelegate.stubber.calls.first?.args?.last as? ConnectionState, ConnectionState.connecting)
        XCTAssertEqual(stateChangeDelegate.stubber.calls.last?.name, "connectionChange")
        XCTAssertEqual(stateChangeDelegate.stubber.calls.last?.args?.first as? ConnectionState, ConnectionState.connecting)
        XCTAssertEqual(stateChangeDelegate.stubber.calls.last?.args?.last as? ConnectionState, ConnectionState.connected)
    }

    func testDelegateGetsCalledFourTimesGoingFromDisconnectedToConnectingToConnectedToDisconnectingToDisconnected() {
        XCTAssertEqual(pusher.connection.connectionState, ConnectionState.disconnected)
        pusher.connect()
        XCTAssertEqual(pusher.connection.connectionState, ConnectionState.connected)
        pusher.disconnect()
        XCTAssertEqual(stateChangeDelegate.stubber.calls.count, 4)
        XCTAssertEqual(stateChangeDelegate.stubber.calls[2].name, "connectionChange")
        XCTAssertEqual(stateChangeDelegate.stubber.calls[2].args?.first as? ConnectionState, ConnectionState.connected)
        XCTAssertEqual(stateChangeDelegate.stubber.calls[2].args?.last as? ConnectionState, ConnectionState.disconnecting)
        XCTAssertEqual(stateChangeDelegate.stubber.calls.last?.name, "connectionChange")
        XCTAssertEqual(stateChangeDelegate.stubber.calls.last?.args?.first as? ConnectionState, ConnectionState.disconnecting)
        XCTAssertEqual(stateChangeDelegate.stubber.calls.last?.args?.last as? ConnectionState, ConnectionState.disconnected)
    }
}
