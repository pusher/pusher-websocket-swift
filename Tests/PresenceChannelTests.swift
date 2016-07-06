//
//  PresenceChannelTests.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 07/04/2016.
//
//

import Quick
import Nimble
import PusherSwift

class PusherPresenceChannelSpec: QuickSpec {
    override func spec() {
        var pusher: Pusher!
        var socket: MockWebSocket!

        beforeEach({
            socket = MockWebSocket()
        })

        describe("the members object") {
            it("stores the userId if a userDataFetcher is provided") {
                let options = PusherClientOptions(
                    authMethod: .Internal(secret: "secret")
                )
                pusher = Pusher(key: "key", options: options)
                pusher.connection.userDataFetcher = { () -> PusherUserData in
                    return PusherUserData(userId: "123")
                }
                socket.delegate = pusher.connection
                pusher.connection.socket = socket
                pusher.connect()
                let chan = pusher.subscribe("presence-channel") as? PresencePusherChannel
                expect(chan?.members.first!.userId).to(equal("123"))
            }

            it("stores the socketId if no userDataFetcher is provided") {
                let options = PusherClientOptions(
                    authMethod: .Internal(secret: "secret")
                )
                pusher = Pusher(key: "key", options: options)
                socket.delegate = pusher.connection
                pusher.connection.socket = socket
                pusher.connect()
                let chan = pusher.subscribe("presence-channel") as? PresencePusherChannel
                expect(chan?.members).toNot(beEmpty())
                expect(chan?.members.first!.userId).to(equal("46123.486095"))
            }

            it("stores userId and userInfo if a userDataFetcher that returns both is provided") {
                let options = PusherClientOptions(
                    authMethod: .Internal(secret: "secret")
                )
                pusher = Pusher(key: "testKey123", options: options)
                pusher.connection.userDataFetcher = { () -> PusherUserData in
                    return PusherUserData(userId: "123", userInfo: ["twitter": "hamchapman"])
                }
                socket.delegate = pusher.connection
                pusher.connection.socket = socket
                pusher.connect()
                let chan = pusher.subscribe("presence-test") as? PresencePusherChannel
                expect(chan?.members).toNot(beEmpty())
                expect(chan?.members.first!.userInfo as? [String : String]).to(equal(["twitter": "hamchapman"]))
            }
        }

        describe("finding members") {
            it("returns the PresenceChannelMember object for a given subscribed user id") {
                let options = PusherClientOptions(
                    authMethod: .Internal(secret: "secret")
                )
                pusher = Pusher(key: "key", options: options)
                pusher.connection.userDataFetcher = { () -> PusherUserData in
                    return PusherUserData(userId: "123")
                }
                socket.delegate = pusher.connection
                pusher.connection.socket = socket
                pusher.connect()

                let chan = pusher.subscribe("presence-channel") as? PresencePusherChannel
                pusher.connection.handleEvent("pusher_internal:member_added", jsonObject: ["event": "pusher_internal:member_added", "channel": "presence-channel", "data": "{\"user_id\":\"100\", \"user_info\":{\"twitter\":\"hamchapman\"}}"])
                let member = chan!.findMember("100")

                expect(member!.userId).to(equal("100"))
                expect(member!.userInfo as? [String : String]).to(equal(["twitter": "hamchapman"]))
            }

            it("returns the PresenceChannelMember object for the subscribed user (me)") {
                let options = PusherClientOptions(
                    authMethod: .Internal(secret: "secret")
                )
                pusher = Pusher(key: "key", options: options)
                pusher.connection.userDataFetcher = { () -> PusherUserData in
                    return PusherUserData(userId: "123", userInfo: ["friends": 0])
                }
                socket.delegate = pusher.connection
                pusher.connection.socket = socket
                pusher.connect()

                let chan = pusher.subscribe("presence-channel") as? PresencePusherChannel
                pusher.connection.handleEvent("pusher_internal:member_added", jsonObject: ["event": "pusher_internal:member_added", "channel": "presence-channel", "data": "{\"user_id\":\"100\", \"user_info\":{\"twitter\":\"hamchapman\"}}"])

                let me = chan!.me()

                expect(me!.userId).to(equal("123"))
                expect(me!.userInfo as? [String : Int]).to(equal(["friends": 0]))
            }
        }

        describe("the member added/removed events") {
            var stubber: StubberForMocks!

            beforeEach({
                stubber = StubberForMocks()
            })

            it("calls the onMemberAdded function, if provided") {
                let options = PusherClientOptions(
                    authMethod: .Internal(secret: "secretsecretsecretsecret")
                )
                pusher = Pusher(key: "key", options: options)
                pusher.connection.userDataFetcher = { () -> PusherUserData in
                    return PusherUserData(userId: "123")
                }
                socket.delegate = pusher.connection
                pusher.connection.socket = socket
                pusher.connect()
                let memberAddedFunction = { (member: PresenceChannelMember) -> Void in stubber.stub("onMemberAdded", args: [member], functionToCall: nil) }
                pusher.subscribe("presence-channel", onMemberAdded: memberAddedFunction) as? PresencePusherChannel
                pusher.connection.handleEvent("pusher_internal:member_added", jsonObject: ["event": "pusher_internal:member_added", "channel": "presence-channel", "data": "{\"user_id\":\"100\"}"])

                expect(stubber.calls.first?.name).to(equal("onMemberAdded"))
                expect((stubber.calls.first?.args?.first as? PresenceChannelMember)?.userId).to(equal("100"))
            }

            it("calls the onMemberRemoved function, if provided") {
                let options = PusherClientOptions(
                    authMethod: .Internal(secret: "secret")
                )
                pusher = Pusher(key: "key", options: options)
                pusher.connection.userDataFetcher = { () -> PusherUserData in
                    return PusherUserData(userId: "123")
                }
                socket.delegate = pusher.connection
                pusher.connection.socket = socket
                pusher.connect()
                let memberRemovedFunction = { (member: PresenceChannelMember) -> Void in stubber.stub("onMemberRemoved", args: [member], functionToCall: nil) }
                let chan = pusher.subscribe("presence-channel", onMemberAdded: nil, onMemberRemoved:  memberRemovedFunction) as? PresencePusherChannel

                chan?.members.append(PresenceChannelMember(userId: "100"))
                pusher.connection.handleEvent("pusher_internal:member_removed", jsonObject: ["event": "pusher_internal:member_removed", "channel": "presence-channel", "data": "{\"user_id\":\"100\"}"])

                expect(stubber.calls.last?.name).to(equal("onMemberRemoved"))
                expect((stubber.calls.last?.args?.first as? PresenceChannelMember)?.userId).to(equal("100"))
            }

            it("calls the onMemberRemoved function, if provided, and the userId of the member when they were addded was not a string") {
                let options = PusherClientOptions(
                    authMethod: .Internal(secret: "secret")
                )
                pusher = Pusher(key: "key", options: options)
                socket.delegate = pusher.connection
                pusher.connection.socket = socket
                pusher.connection.userDataFetcher = { () -> PusherUserData in
                    return PusherUserData(userId: "123")
                }
                pusher.connect()
                let memberRemovedFunction = { (member: PresenceChannelMember) -> Void in stubber.stub("onMemberRemoved", args: [member], functionToCall: nil) }
                pusher.subscribe("presence-channel", onMemberAdded: nil, onMemberRemoved: memberRemovedFunction) as? PresencePusherChannel
                pusher.connection.handleEvent("pusher_internal:member_added", jsonObject: ["event": "pusher_internal:member_added", "channel": "presence-channel", "data": "{\"user_id\":100}"])
                pusher.connection.handleEvent("pusher_internal:member_removed", jsonObject: ["event": "pusher_internal:member_removed", "channel": "presence-channel", "data": "{\"user_id\":100}"])

                expect(stubber.calls.last?.name).to(equal("onMemberRemoved"))
                expect((stubber.calls.last?.args?.first as? PresenceChannelMember)?.userId).to(equal("100"))
            }

        }
    }
}
