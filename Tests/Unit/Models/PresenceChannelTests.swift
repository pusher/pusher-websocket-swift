import XCTest

@testable import PusherSwift

class PusherPresenceChannelTests: XCTestCase {
    private var pusher: Pusher!
    private var socket: MockWebSocket!
    private var options: PusherClientOptions!
    private var stubber: StubberForMocks!

    private let userIdAsIntegerJSON = "{\"\(Constants.JSONKeys.userId)\":100}"
    private let userIdJSON = "{\"\(Constants.JSONKeys.userId)\":\"100\"}"
    private let userIdWithUserInfoJSON = "{\"\(Constants.JSONKeys.userId)\":\"100\", \"\(Constants.JSONKeys.userInfo)\":{\"twitter\":\"hamchapman\"}}"

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
        let ex = expectation(description: "subscription succeed")
        let chan = pusher.subscribe(TestObjects.Event.presenceChannelName) as? PusherPresenceChannel
        chan?.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { (_: PusherEvent) in
            ex.fulfill()
            XCTAssertEqual(chan?.members.first!.userId, "123", "the userId should be 123")
        }
        waitForExpectations(timeout: 0.5)
    }

    func testMembersObjectStoresSocketIdIfNoUserDataFetcherIsProvided() {
        pusher.connect()

        let chan = pusher.subscribe(TestObjects.Event.presenceChannelName) as? PusherPresenceChannel
        let ex = expectation(description: "subscription succeed")
        chan?.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { (_: PusherEvent) in
            ex.fulfill()
            XCTAssertEqual(chan?.members.first!.userId, "46123.486095", "the userId should be 46123.486095")
        }
        waitForExpectations(timeout: 0.5)
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

        let ex = expectation(description: "subscription succeed")
        guard let chan = pusher.subscribe(channelName) as? PusherPresenceChannel else {
            return XCTFail("Couldn't subscribe to channel: \(channelName).")
        }

        chan.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { (_: PusherEvent) in
            ex.fulfill()

            guard let firstUser = chan.members.first else {
               return XCTFail("User doesn't exist.")
           }

           let userId = firstUser.userId
           let userInfo = firstUser.userInfo as! [String: String]

           XCTAssertEqual(userId, "123", "the userId should be 123")
           XCTAssertEqual(userInfo, ["twitter": "hamchapman"], "the userInfo should be [\"twitter\": \"hamchapman\"]")
        }
        waitForExpectations(timeout: 0.5)
    }

    func testFindingPusherPresenceChannelMemberByUserId() {
        pusher.connect()
        let ex = expectation(description: "member added")

        var chan: PusherPresenceChannel?
        let memberAdded = { (member: PusherPresenceChannelMember) in
            let member = chan!.findMember(userId: "100")

            XCTAssertEqual(member!.userId, "100", "the userId should be 100")
            XCTAssertEqual(member!.userInfo as! [String: String], ["twitter": "hamchapman"], "the userInfo should be [\"twitter\": \"hamchapman\"]")
            ex.fulfill()
        }

        chan = pusher.subscribe(TestObjects.Event.presenceChannelName, onMemberAdded: memberAdded) as? PusherPresenceChannel
        chan?.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { (_: PusherEvent) in
            let jsonDict = TestObjects.Event.withJSON(name: Constants.Events.PusherInternal.memberAdded,
                                                      channel: TestObjects.Event.presenceChannelName,
                                                      data: self.userIdWithUserInfoJSON)
            self.pusher.connection.webSocketDidReceiveMessage(connection: self.socket, string: jsonDict)
        }

        waitForExpectations(timeout: 0.5)
    }

    func testFindingTheClientsMemberObject() {
        let userId = "123"
        pusher.connection.userDataFetcher = { () -> PusherPresenceChannelMember in
            return PusherPresenceChannelMember(userId: userId, userInfo: ["friends": 0])
        }

        pusher.connect()

        guard let presenceChannel = pusher.subscribe(channelName: TestObjects.Event.presenceChannelName) as? PusherPresenceChannel else {
            return XCTFail("Couldn't subscribe to channel: \(TestObjects.Event.presenceChannelName).")
        }

        let ex = expectation(description: "subscription succeed")
        presenceChannel.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { (_: PusherEvent) in
            ex.fulfill()

            guard let member = presenceChannel.me() else {
               return XCTFail("Couldn't find member with id: \(userId).")
           }

           XCTAssertEqual(member.userId, userId, "the userId should be \(userId)")
           XCTAssertEqual(member.userInfo as! [String: Int], ["friends": 0], "the userInfo should be [\"friends\": 0]")
        }
        waitForExpectations(timeout: 0.5)
    }

    func testFindingAPresenceChannelAsAPusherPresenceChannel() {
        let userId = "123"
        pusher.connection.userDataFetcher = { () -> PusherPresenceChannelMember in
            return PusherPresenceChannelMember(userId: userId, userInfo: ["friends": 0])
        }

        pusher.connect()

        let presenceChannel = pusher.subscribe(TestObjects.Event.presenceChannelName)

        let ex = expectation(description: "subscription succeed")
        presenceChannel.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { (_: PusherEvent) in
            ex.fulfill()
            guard let presenceChannel = self.pusher.connection.channels.findPresence(name: TestObjects.Event.presenceChannelName) else {
                return XCTFail("Presence for channel: \(TestObjects.Event.presenceChannelName) not found.")
            }

            guard let member = presenceChannel.me() else {
                return XCTFail("Couldn't find member.")
            }

            XCTAssertEqual(member.userId, userId, "the userId of the client's member object should be \(userId)")
        }
        waitForExpectations(timeout: 0.5)
    }

    func testOnMemberAddedFunctionGetsCalledWhenANewSubscriptionSucceeds() {
        let ex = expectation(description: "member added")

        pusher.connect()

        let memberAddedFunction = { (member: PusherPresenceChannelMember) -> Void in
            XCTAssertEqual(member.userId, "100", "the userId should be 100")
            ex.fulfill()
        }
        let chan = pusher.subscribe(TestObjects.Event.presenceChannelName, onMemberAdded: memberAddedFunction) as? PusherPresenceChannel
        chan?.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { (_: PusherEvent) in
            let jsonDict = TestObjects.Event.withJSON(name: Constants.Events.PusherInternal.memberAdded,
                                                      channel: TestObjects.Event.presenceChannelName,
                                                      data: self.userIdJSON)
            self.pusher.connection.webSocketDidReceiveMessage(connection: self.socket, string: jsonDict)
        }
        waitForExpectations(timeout: 0.5)
    }

    func testOnMemberRemovedFunctionGetsCalledWhenANewSubscriptionSucceeds() {
        let ex = expectation(description: "member removed")

        pusher.connect()

        let memberRemovedFunction = { (member: PusherPresenceChannelMember) -> Void in
            XCTAssertEqual(member.userId, "100", "the userId should be 100")
            ex.fulfill()
        }
        let chan = pusher.subscribe(TestObjects.Event.presenceChannelName, onMemberAdded: nil, onMemberRemoved: memberRemovedFunction) as? PusherPresenceChannel
        chan?.members.append(PusherPresenceChannelMember(userId: "100"))
        chan?.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { (_: PusherEvent) in
            let jsonDict = TestObjects.Event.withJSON(name: Constants.Events.PusherInternal.memberRemoved,
                                                      channel: TestObjects.Event.presenceChannelName,
                                                      data: self.userIdJSON)
            self.pusher.connection.webSocketDidReceiveMessage(connection: self.socket, string: jsonDict)
        }
        waitForExpectations(timeout: 0.5)
    }

    func testOnMemberRemovedFunctionGetsCalledWhenANewSubscriptionSucceedsIfTheMemberUserIdWasNotAStringOriginally() {
        let ex = expectation(description: "member removed")

        pusher.connect()

        let memberRemovedFunction = { (member: PusherPresenceChannelMember) -> Void in
            XCTAssertEqual(member.userId, "100", "the userId should be 100")
            ex.fulfill()
        }
        let chan = pusher.subscribe(TestObjects.Event.presenceChannelName, onMemberAdded: nil, onMemberRemoved: memberRemovedFunction) as? PusherPresenceChannel
        chan?.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { (_: PusherEvent) in
            let addedJsonDict = TestObjects.Event.withJSON(name: Constants.Events.PusherInternal.memberAdded,
                                                      channel: TestObjects.Event.presenceChannelName,
                                                      data: self.userIdAsIntegerJSON)
            self.pusher.connection.webSocketDidReceiveMessage(connection: self.socket, string: addedJsonDict)

            let removedJsonDict = TestObjects.Event.withJSON(name: Constants.Events.PusherInternal.memberRemoved,
                                                             channel: TestObjects.Event.presenceChannelName,
                                                             data: self.userIdAsIntegerJSON)
            self.pusher.connection.webSocketDidReceiveMessage(connection: self.socket, string: removedJsonDict)
        }
        waitForExpectations(timeout: 0.5)
    }
}
