//
//  PusherConnectionTests.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 21/06/2016.
//
//

import Foundation
import Quick
import Nimble
import PusherSwift

class PusherConnectionSpec: QuickSpec {
    override func spec() {
        describe("creating the connection") {
            var key: String!
            var pusher: Pusher!

            beforeEach({
                key = "testKey123"
                pusher = Pusher(key: key)
            })

            context("setting no properties") {
                it("has userDataFetcher as nil") {
                    expect(pusher.connection.userDataFetcher).to(beNil())
                }

                it("has debugLogger set as nil") {
                    expect(pusher.connection.debugLogger).to(beNil())
                }
            }

            context("providing option") {
                context("debugLogger") {
                    it("has a closure set") {
                        let debugLogger = { (text: String) in }
                        pusher.connection.debugLogger = debugLogger
                        expect(pusher.connection.debugLogger).toNot(beNil())
                    }
                }

                context("userDataFetcher") {
                    it("has a closure set") {
                        func fetchFunc() -> PusherUserData {
                            return PusherUserData(userId: "1")
                        }
                        pusher.connection.userDataFetcher = fetchFunc
                        expect(pusher.connection.userDataFetcher).toNot(beNil())
                    }
                }
            }
        }
    }
}
