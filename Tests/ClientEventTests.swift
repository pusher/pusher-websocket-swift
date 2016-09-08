//
//  ClientEventTests.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 07/04/2016.
//
//

import PusherSwift
import XCTest

class ClientEventTests: XCTestCase {
    var connection: MockPusherConnection!
    var socket: MockWebSocket!

  override func setUp() {
      super.setUp()

      socket = MockWebSocket()
      connection = MockPusherConnection(options: PusherClientOptions(authMethod: .inline(secret: "superSecretSecret")))
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
        let expectedDict = ["data": ["data": "testing client events"], "event": "client-test-event", "channel": "private-channel"] as [String : Any]
        let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject : AnyObject])
        XCTAssertTrue(parsedEqualsExpected)
    }

    func testQueuedClientEventsGetSentOnceSubscriptionSucceeds() {
        let chan = PusherChannel(name: "private-channel", connection: connection)
        connection.channels.channels["private-channel"] = chan
        XCTAssertEqual(chan.unsentEvents.count, 0, "no events should have been queued yet")
        chan.trigger(eventName: "client-test-event", data: ["data": "testing client events"])
        XCTAssertEqual(chan.unsentEvents.last!.name, "client-test-event")
        XCTAssertEqual(socket.stubber.calls.count, 0, "no events should have been sent yet")
        connection.connect()
        let parsedSubscribeArgs = convertStringToDictionary(socket.stubber.calls.last?.args!.first as! String)
        let expectedDict = ["data": ["data": "testing client events"], "event": "client-test-event", "channel": "private-channel"] as [String : Any]
        let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject : AnyObject])
        XCTAssertTrue(parsedEqualsExpected)
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
        connection.connect()
        let parsedSubscribeArgs = convertStringToDictionary(socket.stubber.calls.last?.args!.first as! String)
        let expectedDict = ["data": ["data": "more testing client events"], "event": "client-test-event", "channel": "private-channel"] as [String : Any]
        let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqual(to: NSDictionary(dictionary: expectedDict) as [NSObject : AnyObject])
        XCTAssertTrue(parsedEqualsExpected)
    }
}
