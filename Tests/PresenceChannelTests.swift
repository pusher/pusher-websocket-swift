//
//  PresenceChannelTests.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 07/04/2016.
//
//

import PusherSwift
import XCTest

class PusherPresenceChannelTests: XCTestCase {
    var pusher: Pusher!
    var socket: MockWebSocket!
    var options: PusherClientOptions!
    var stubber: StubberForMocks!

    override func setUp() {
        super.setUp()

        options = PusherClientOptions(
            authMethod: .inline(secret: "secret")
        )
        pusher = Pusher(key: "key", options: options)
        socket = MockWebSocket()
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        stubber = StubberForMocks()
    }

    func testMembersObjectStoresUserIdIfAUserDataFetcherIsProvided() {
        pusher.connection.userDataFetcher = { () -> PusherUserData in
            return PusherUserData(userId: "123")
        }

        pusher.connect()
        let chan = pusher.subscribe("presence-channel") as? PusherPresenceChannel
        XCTAssertEqual(chan?.members.first!.userId, "123", "the userId should be 123")
    }

    func testMembersObjectStoresSocketIdIfNoUserDataFetcherIsProvided() {
        pusher.connect()
        let chan = pusher.subscribe("presence-channel") as? PusherPresenceChannel
        XCTAssertEqual(chan?.members.first!.userId, "46123.486095", "the userId should be 46123.486095")
    }

    func testMembersObjectStoresUserIdAndUserInfoIfAUserDataFetcherIsProvidedThatReturnsBoth() {
        pusher = Pusher(key: "testKey123", options: options)
        pusher.connection.userDataFetcher = { () -> PusherUserData in
            return PusherUserData(userId: "123", userInfo: ["twitter": "hamchapman"] as Any?)
        }
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        pusher.connect()
        let chan = pusher.subscribe("presence-test") as? PusherPresenceChannel

        XCTAssertEqual(chan?.members.first!.userId, "123", "the userId should be 123")
        XCTAssertEqual(chan?.members.first!.userInfo as! [String: String], ["twitter": "hamchapman"], "the userInfo should be [\"twitter\": \"hamchapman\"]")
    }

    func testFindingPusherPresenceChannelMemberByUserId() {
        pusher.connect()

        let chan = pusher.subscribe("presence-channel") as? PusherPresenceChannel
        pusher.connection.handleEvent(eventName: "pusher_internal:member_added", jsonObject: ["event": "pusher_internal:member_added" as AnyObject, "channel": "presence-channel" as AnyObject, "data": "{\"user_id\":\"100\", \"user_info\":{\"twitter\":\"hamchapman\"}}" as AnyObject])
        let member = chan!.findMember(userId: "100")

        XCTAssertEqual(member!.userId, "100", "the userId should be 100")
        XCTAssertEqual(member!.userInfo as! [String: String], ["twitter": "hamchapman"], "the userInfo should be [\"twitter\": \"hamchapman\"]")
    }

    func testFindingTheClientsMemberObject() {
        pusher.connection.userDataFetcher = { () -> PusherUserData in
            return PusherUserData(userId: "123", userInfo: ["friends": 0])
        }

        pusher.connect()

        let chan = pusher.subscribe("presence-channel") as? PusherPresenceChannel
        let me = chan!.me()

        XCTAssertEqual(me!.userId, "123", "the userId should be 123")
        XCTAssertEqual(me!.userInfo as! [String: Int], ["friends": 0], "the userInfo should be [\"friends\": 0]")
    }

    func testOnMemberAddedFunctionGetsCalledWhenANewSubscriptionSucceeds() {
        let options = PusherClientOptions(
            authMethod: .inline(secret: "secretsecretsecretsecret")
        )
        pusher = Pusher(key: "key", options: options)
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        pusher.connect()

        let memberAddedFunction = { (member: PusherPresenceChannelMember) -> Void in
            let _ = self.stubber.stub(functionName: "onMemberAdded", args: [member], functionToCall: nil)
        }
        let _ = pusher.subscribe("presence-channel", onMemberAdded: memberAddedFunction) as? PusherPresenceChannel
        pusher.connection.handleEvent(eventName: "pusher_internal:member_added", jsonObject: ["event": "pusher_internal:member_added" as AnyObject, "channel": "presence-channel" as AnyObject, "data": "{\"user_id\":\"100\"}" as AnyObject])

        XCTAssertEqual(stubber.calls.first?.name, "onMemberAdded", "the onMemberAdded function should have been called")
        XCTAssertEqual((stubber.calls.first?.args?.first as? PusherPresenceChannelMember)?.userId, "100", "the userId should be 100")
    }

    func testOnMemberRemovedFunctionGetsCalledWhenANewSubscriptionSucceeds() {
        let options = PusherClientOptions(
            authMethod: .inline(secret: "secretsecretsecretsecret")
        )
        pusher = Pusher(key: "key", options: options)
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        pusher.connect()

        let memberRemovedFunction = { (member: PusherPresenceChannelMember) -> Void in
            let _ = self.stubber.stub(functionName: "onMemberRemoved", args: [member], functionToCall: nil)
        }
        let chan = pusher.subscribe("presence-channel", onMemberAdded: nil, onMemberRemoved: memberRemovedFunction) as? PusherPresenceChannel
        chan?.members.append(PusherPresenceChannelMember(userId: "100"))

        pusher.connection.handleEvent(eventName: "pusher_internal:member_removed", jsonObject: ["event": "pusher_internal:member_removed" as AnyObject, "channel": "presence-channel" as AnyObject, "data": "{\"user_id\":\"100\"}" as AnyObject])

        XCTAssertEqual(stubber.calls.last?.name, "onMemberRemoved", "the onMemberRemoved function should have been called")
        XCTAssertEqual((stubber.calls.last?.args?.first as? PusherPresenceChannelMember)?.userId, "100", "the userId should be 100")
    }

    func testOnMemberRemovedFunctionGetsCalledWhenANewSubscriptionSucceedsIfTheMemberUserIdWasNotAStringOriginally() {
        let options = PusherClientOptions(
            authMethod: .inline(secret: "secretsecretsecretsecret")
        )
        pusher = Pusher(key: "key", options: options)
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        pusher.connect()
        let memberRemovedFunction = { (member: PusherPresenceChannelMember) -> Void in
            let _ = self.stubber.stub(functionName: "onMemberRemoved", args: [member], functionToCall: nil)
        }
        let _ = pusher.subscribe("presence-channel", onMemberAdded: nil, onMemberRemoved: memberRemovedFunction) as? PusherPresenceChannel
        pusher.connection.handleEvent(eventName: "pusher_internal:member_added", jsonObject: ["event": "pusher_internal:member_added" as AnyObject, "channel": "presence-channel" as AnyObject, "data": "{\"user_id\":100}" as AnyObject])
        pusher.connection.handleEvent(eventName: "pusher_internal:member_removed", jsonObject: ["event": "pusher_internal:member_removed" as AnyObject, "channel": "presence-channel" as AnyObject, "data": "{\"user_id\":100}" as AnyObject])

        XCTAssertEqual(stubber.calls.last?.name, "onMemberRemoved", "the onMemberRemoved function should have been called")
        XCTAssertEqual((stubber.calls.last?.args?.first as? PusherPresenceChannelMember)?.userId, "100", "the userId should be 100")
    }
}
