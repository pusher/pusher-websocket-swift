//
//  ConnectionStateChangeDelegateTests.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 07/04/2016.
//
//

import Quick
import Nimble
import PusherSwift

class ConnectionStateChangeDelegateSpec: QuickSpec {
    override func spec() {
        var pusher: Pusher!
        var socket: MockWebSocket!
        var stateChangeDelegate: TestConnectionStateChangeDelegate!

        beforeEach({
            pusher = Pusher(key: "key", options: ["autoReconnect": false])
            socket = MockWebSocket()
            stateChangeDelegate = TestConnectionStateChangeDelegate()
            socket.delegate = pusher.connection
            pusher.connection.socket = socket
            pusher.connection.stateChangeDelegate = stateChangeDelegate
        })

        describe("the delegate gets called") {
            it("twice going from disconnected -> connecting -> connected") {
                expect(pusher.connection.connectionState).to(equal(ConnectionState.Disconnected))
                pusher.connect()
                expect(pusher.connection.connectionState).to(equal(ConnectionState.Connected))
                expect(stateChangeDelegate.stubber.calls.first?.name).to(equal("connectionChange"))
                expect(stateChangeDelegate.stubber.calls.first?.args?.first as? ConnectionState).to(equal(ConnectionState.Disconnected))
                expect(stateChangeDelegate.stubber.calls.first?.args?.last as? ConnectionState).to(equal(ConnectionState.Connecting))
                expect(stateChangeDelegate.stubber.calls.last?.name).to(equal("connectionChange"))
                expect(stateChangeDelegate.stubber.calls.last?.args?.first as? ConnectionState).to(equal(ConnectionState.Connecting))
                expect(stateChangeDelegate.stubber.calls.last?.args?.last as? ConnectionState).to(equal(ConnectionState.Connected))
            }

            it("four times going from disconnected -> connecting -> connected -> disconnecting -> disconnected") {
                expect(pusher.connection.connectionState).to(equal(ConnectionState.Disconnected))
                pusher.connect()
                expect(pusher.connection.connectionState).to(equal(ConnectionState.Connected))
                pusher.disconnect()
                expect(stateChangeDelegate.stubber.calls.count).to(equal(4))
                expect(stateChangeDelegate.stubber.calls[2].name).to(equal("connectionChange"))
                expect(stateChangeDelegate.stubber.calls[2].args?.first as? ConnectionState).to(equal(ConnectionState.Connected))
                expect(stateChangeDelegate.stubber.calls[2].args?.last as? ConnectionState).to(equal(ConnectionState.Disconnecting))
                expect(stateChangeDelegate.stubber.calls.last?.name).to(equal("connectionChange"))
                expect(stateChangeDelegate.stubber.calls.last?.args?.first as? ConnectionState).to(equal(ConnectionState.Disconnecting))
                expect(stateChangeDelegate.stubber.calls.last?.args?.last as? ConnectionState).to(equal(ConnectionState.Disconnected))
            }
        }
    }
}