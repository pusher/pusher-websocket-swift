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
                pusher = Pusher(key: "key", options: [
                    "secret": "secret",
                    "userDataFetcher": { () -> PusherUserData in
                        return PusherUserData(userId: "123")
                    }
                ])
                socket.delegate = pusher.connection
                pusher.connection.socket = socket
                pusher.connect()
                let chan = pusher.subscribe("presence-channel") as? PresencePusherChannel
                expect(chan?.members.first!.userId).to(equal("123"))
            }
            
            it("stores the socketId if no userDataFetcher is provided") {
                pusher = Pusher(key: "key", options: ["secret": "secret"])
                socket.delegate = pusher.connection
                pusher.connection.socket = socket
                pusher.connect()
                let chan = pusher.subscribe("presence-channel") as? PresencePusherChannel
                expect(chan?.members).toNot(beEmpty())
                expect(chan?.members.first!.userId).to(equal("46123.486095"))
            }
            
            it("stores userId and userInfo if a userDataFetcher that returns both is provided") {
                pusher = Pusher(key: "testKey123", options: [
                    "secret": "secret",
                    "userDataFetcher": { () -> PusherUserData in
                        return PusherUserData(userId: "123", userInfo: ["twitter": "hamchapman"])
                    }
                    ])
                socket.delegate = pusher.connection
                pusher.connection.socket = socket
                pusher.connect()
                let chan = pusher.subscribe("presence-test") as? PresencePusherChannel
                expect(chan?.members).toNot(beEmpty())
                expect(chan?.members.first!.userInfo as? Dictionary<String, String>).to(equal(["twitter": "hamchapman"]))
            }
        }
    }
}
