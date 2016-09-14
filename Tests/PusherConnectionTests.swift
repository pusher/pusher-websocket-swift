//
//  PusherConnectionTests.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 21/06/2016.
//
//

import PusherSwift
import XCTest

class PusherConnectionTests: XCTestCase {
    var key: String!
    var pusher: Pusher!

    override func setUp() {
        super.setUp()

        key = "testKey123"
        pusher = Pusher(key: key)
    }

    func testUserDataFetcherIsNilByDefault() {
        XCTAssertNil(pusher.connection.userDataFetcher, "userDataFetcher should be nil")
    }

    func testDelegateIsNilByDefault() {
        XCTAssertNil(pusher.connection.delegate, "delegate should be nil")
    }

    func testSettingADelegate() {
        class DummyDelegate: PusherConnectionDelegate {}
        let dummyDelegate = DummyDelegate()
        pusher.connection.delegate = dummyDelegate
        XCTAssertNotNil(pusher.connection.delegate, "delegate should not be nil")
    }

    func testSettingAUserDataFetcher() {
        func fetchFunc() -> PusherPresenceChannelMember {
            return PusherPresenceChannelMember(userId: "1")
        }
        pusher.connection.userDataFetcher = fetchFunc
        XCTAssertNotNil(pusher.connection.userDataFetcher, "userDataFetcher should not be nil")
    }
}
