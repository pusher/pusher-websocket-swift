@testable import PusherSwift
import XCTest

class PusherPresenceChannelTests: XCTestCase {
    var pusher: Pusher!
    var socket: MockWebSocket!
    var options: PusherClientOptions!
    var stubber: StubberForMocks!

    override func setUp() {
        super.setUp()

        options = PusherClientOptions(
            authMethod: .inline(secret: "secret"),
            autoReconnect: false
        )
        pusher = Pusher(key: "key", options: options)
        socket = MockWebSocket()
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        stubber = StubberForMocks()
    }

    func testMembersObjectStoresUserIdIfAUserDataFetcherIsProvided() {
        pusher.connection.userDataFetcher = { () -> PusherPresenceChannelMember in
            return PusherPresenceChannelMember(userId: "123")
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
        pusher.connection.userDataFetcher = { () -> PusherPresenceChannelMember in
            return PusherPresenceChannelMember(userId: "123", userInfo: ["twitter": "hamchapman"] as Any?)
        }
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        pusher.connect()

        let channelName = "presence-test"
        guard let chan = pusher.subscribe(channelName) as? PusherPresenceChannel else {
            return XCTFail("Couldn't subscribe to channel: \(channelName).")
        }

        guard let firstUser = chan.members.first else {
            return XCTFail("User doesn't exist.")
        }

        let userId = firstUser.userId
        let userInfo = firstUser.userInfo as! [String: String]

        XCTAssertEqual(userId, "123", "the userId should be 123")
        XCTAssertEqual(userInfo, ["twitter": "hamchapman"], "the userInfo should be [\"twitter\": \"hamchapman\"]")
    }

    func testFindingPusherPresenceChannelMemberByUserId() {
        pusher.connect()

        let chan = pusher.subscribe("presence-channel") as? PusherPresenceChannel
        let pusherEvent = PusherEvent(jsonObject: ["event": "pusher_internal:member_added" as AnyObject, "channel": "presence-channel" as AnyObject, "data": "{\"user_id\":\"100\", \"user_info\":{\"twitter\":\"hamchapman\"}}" as AnyObject])
        pusher.connection.handleEvent(event: pusherEvent!)
        let member = chan!.findMember(userId: "100")

        XCTAssertEqual(member!.userId, "100", "the userId should be 100")
        XCTAssertEqual(member!.userInfo as! [String: String], ["twitter": "hamchapman"], "the userInfo should be [\"twitter\": \"hamchapman\"]")
    }

    func testFindingTheClientsMemberObject() {
        let userId = "123"
        pusher.connection.userDataFetcher = { () -> PusherPresenceChannelMember in
            return PusherPresenceChannelMember(userId: userId, userInfo: ["friends": 0])
        }

        pusher.connect()

        let channelName = "presence-channel"

        guard let presenceChannel = pusher.subscribe(channelName: channelName) as? PusherPresenceChannel else {
            return XCTFail("Couldn't subscribe to channel: \(channelName).")
        }

        guard let member = presenceChannel.me() else {
            return XCTFail("Couldn't find member with id: \(userId).")
        }

        XCTAssertEqual(member.userId, userId, "the userId should be \(userId)")
        XCTAssertEqual(member.userInfo as! [String: Int], ["friends": 0], "the userInfo should be [\"friends\": 0]")
    }

    func testFindingAPresenceChannelAsAPusherPresenceChannel() {
        let userId = "123"
        pusher.connection.userDataFetcher = { () -> PusherPresenceChannelMember in
            return PusherPresenceChannelMember(userId: userId, userInfo: ["friends": 0])
        }

        pusher.connect()

        let channelName = "presence-channel"

        let _ = pusher.subscribe(channelName)

        guard let presenceChannel = pusher.connection.channels.findPresence(name: channelName) else {
            return XCTFail("Presence for channel: \(channelName) not found.")
        }

        guard let member = presenceChannel.me() else {
            return XCTFail("Couldn't find member.")
        }

        XCTAssertEqual(member.userId, userId, "the userId of the client's member object should be \(userId)")
    }

    func testOnMemberAddedFunctionGetsCalledWhenANewSubscriptionSucceeds() {
        let options = PusherClientOptions(
            authMethod: .inline(secret: "secretsecretsecretsecret"),
            autoReconnect: false
        )
        pusher = Pusher(key: "key", options: options)
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        pusher.connect()

        let memberAddedFunction = { (member: PusherPresenceChannelMember) -> Void in
            let _ = self.stubber.stub(functionName: "onMemberAdded", args: [member], functionToCall: nil)
        }
        let _ = pusher.subscribe("presence-channel", onMemberAdded: memberAddedFunction) as? PusherPresenceChannel
        let pusherEvent = PusherEvent(jsonObject: ["event": "pusher_internal:member_added" as AnyObject, "channel": "presence-channel" as AnyObject, "data": "{\"user_id\":\"100\"}" as AnyObject])
        pusher.connection.handleEvent(event: pusherEvent!)

        XCTAssertEqual(stubber.calls.first?.name, "onMemberAdded", "the onMemberAdded function should have been called")
        XCTAssertEqual((stubber.calls.first?.args?.first as? PusherPresenceChannelMember)?.userId, "100", "the userId should be 100")
    }

    func testOnMemberRemovedFunctionGetsCalledWhenANewSubscriptionSucceeds() {
        let options = PusherClientOptions(
            authMethod: .inline(secret: "secretsecretsecretsecret"),
            autoReconnect: false
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

        let pusherEvent = PusherEvent(jsonObject: ["event": "pusher_internal:member_removed" as AnyObject, "channel": "presence-channel" as AnyObject, "data": "{\"user_id\":\"100\"}" as AnyObject])
        pusher.connection.handleEvent(event: pusherEvent!)

        XCTAssertEqual(stubber.calls.last?.name, "onMemberRemoved", "the onMemberRemoved function should have been called")
        XCTAssertEqual((stubber.calls.last?.args?.first as? PusherPresenceChannelMember)?.userId, "100", "the userId should be 100")
    }

    func testOnMemberRemovedFunctionGetsCalledWhenANewSubscriptionSucceedsIfTheMemberUserIdWasNotAStringOriginally() {
        let options = PusherClientOptions(
            authMethod: .inline(secret: "secretsecretsecretsecret"),
            autoReconnect: false
        )
        pusher = Pusher(key: "key", options: options)
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        pusher.connect()
        let memberRemovedFunction = { (member: PusherPresenceChannelMember) -> Void in
            let _ = self.stubber.stub(functionName: "onMemberRemoved", args: [member], functionToCall: nil)
        }
        let _ = pusher.subscribe("presence-channel", onMemberAdded: nil, onMemberRemoved: memberRemovedFunction) as? PusherPresenceChannel

        let addedEvent = PusherEvent(jsonObject: ["event": "pusher_internal:member_added" as AnyObject, "channel": "presence-channel" as AnyObject, "data": "{\"user_id\":100}" as AnyObject])
        let removedEvent = PusherEvent(jsonObject: ["event": "pusher_internal:member_removed" as AnyObject, "channel": "presence-channel" as AnyObject, "data": "{\"user_id\":100}" as AnyObject])

        pusher.connection.handleEvent(event: addedEvent!)
        pusher.connection.handleEvent(event: removedEvent!)

        XCTAssertEqual(stubber.calls.last?.name, "onMemberRemoved", "the onMemberRemoved function should have been called")
        XCTAssertEqual((stubber.calls.last?.args?.first as? PusherPresenceChannelMember)?.userId, "100", "the userId should be 100")
    }
}
