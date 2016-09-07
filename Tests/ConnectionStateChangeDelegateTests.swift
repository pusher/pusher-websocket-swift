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
            let options = PusherClientOptions(autoReconnect: false)
            pusher = Pusher(key: "key", options: options)
            socket = MockWebSocket()
            stateChangeDelegate = TestConnectionStateChangeDelegate()
            socket.delegate = pusher.connection
            pusher.connection.socket = socket
            pusher.connection.stateChangeDelegate = stateChangeDelegate
        })

        describe("the delegate gets called") {
            it("twice going from disconnected -> connecting -> connected") {
                expect(pusher.connection.connectionState).to(equal(ConnectionState.disconnected))
                pusher.connect()
                expect(pusher.connection.connectionState).to(equal(ConnectionState.connected))
                expect(stateChangeDelegate.stubber.calls.first?.name).to(equal("connectionChange"))
                expect(stateChangeDelegate.stubber.calls.first?.args?.first as? ConnectionState).to(equal(ConnectionState.disconnected))
                expect(stateChangeDelegate.stubber.calls.first?.args?.last as? ConnectionState).to(equal(ConnectionState.connecting))
                expect(stateChangeDelegate.stubber.calls.last?.name).to(equal("connectionChange"))
                expect(stateChangeDelegate.stubber.calls.last?.args?.first as? ConnectionState).to(equal(ConnectionState.connecting))
                expect(stateChangeDelegate.stubber.calls.last?.args?.last as? ConnectionState).to(equal(ConnectionState.connected))
            }

            it("four times going from disconnected -> connecting -> connected -> disconnecting -> disconnected") {
                expect(pusher.connection.connectionState).to(equal(ConnectionState.disconnected))
                pusher.connect()
                expect(pusher.connection.connectionState).to(equal(ConnectionState.connected))
                pusher.disconnect()
                expect(stateChangeDelegate.stubber.calls.count).to(equal(4))
                expect(stateChangeDelegate.stubber.calls[2].name).to(equal("connectionChange"))
                expect(stateChangeDelegate.stubber.calls[2].args?.first as? ConnectionState).to(equal(ConnectionState.connected))
                expect(stateChangeDelegate.stubber.calls[2].args?.last as? ConnectionState).to(equal(ConnectionState.disconnecting))
                expect(stateChangeDelegate.stubber.calls.last?.name).to(equal("connectionChange"))
                expect(stateChangeDelegate.stubber.calls.last?.args?.first as? ConnectionState).to(equal(ConnectionState.disconnecting))
                expect(stateChangeDelegate.stubber.calls.last?.args?.last as? ConnectionState).to(equal(ConnectionState.disconnected))
            }
        }
    }
}
