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

    func testDebugLoggerIsNilByDefault() {
        XCTAssertNil(pusher.connection.debugLogger, "debugLogger should be nil")
    }

    func testSettingADebugLogger() {
        let debugLogger = { (text: String) in }
        pusher.connection.debugLogger = debugLogger
        XCTAssertNotNil(pusher.connection.debugLogger, "debugLogger should not be nil")
    }

    func testSettingAUserDataFetcher() {

        func fetchFunc() -> PusherPresenceChannelMember {
            return PusherPresenceChannelMember(userId: "1")
        }
        pusher.connection.userDataFetcher = fetchFunc
        XCTAssertNotNil(pusher.connection.userDataFetcher, "userDataFetcher should not be nil")
    }

    // TODO: test that subscriptionSuccessHandler gets called
    //       plus same for error

    //    func testSubscriptionSucceededEventSentToPrivateChannel() {
    //        let ex = expectation(description: "the channel should be subscribed to successfully")
    //
    //        pusher.connection.subscriptionSuccessHandler = { str in
    //            XCTAssertEqual(self.socket.callbackCheckString, "channelCallbackCalled")
    //            ex.fulfill()
    //        }
    //
    //        let callback = { (data: Any?) -> Void in
    //            if let eName = data?["event"], eName == "pusher:subscription_succeeded" {
    //                self.socket.appendToCallbackCheckString("channelCallbackCalled")
    //            }
    //        }
    //
    //
    //        XCTAssertEqual(socket.callbackCheckString, "")
    //        let chan = pusher.subscribe("private-channel")
    //        let _ = chan.bind(eventName: "pusher:subscription_succeeded", callback: callback)
    //        pusher.connect()
    //
    //        waitForExpectations(timeout: 0.5)
    //    }
}
