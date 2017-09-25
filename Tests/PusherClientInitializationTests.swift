//
//  PusherSwiftTests.swift
//  PusherSwiftTests
//
//  Created by Hamilton Chapman on 24/02/2015.
//
//

import PusherSwift
import XCTest

let VERSION = "5.0.1"

class ClientInitializationTests: XCTestCase {
    var key: String!
    var pusher: Pusher!

    override func setUp() {
        super.setUp()

        key = "testKey123"
        pusher = Pusher(key: key)
    }

    func testCreatingTheConnection() {
        XCTAssertNotNil(pusher.connection, "the connection should not be nil")
    }

    func testDefaultConnectionURLConfig() {
        XCTAssertEqual(pusher.connection.url, "wss://ws.pusherapp.com:443/app/testKey123?client=pusher-websocket-swift&version=\(VERSION)&protocol=7", "the connection URL should be set correctly")
    }

    func testDefaultAuthMethodConfig() {
        XCTAssertEqual(pusher.connection.options.authMethod, AuthMethod.noMethod, "the default authMethod should be .noMethod")
    }

    func testDefaultAttemptToReturnJSONObjectConfig() {
        XCTAssertTrue(pusher.connection.options.attemptToReturnJSONObject, "the default value for attemptToReturnJSONObject should be true")
    }

    func testDefaultHostConfig() {
        XCTAssertEqual(pusher.connection.options.host, "ws.pusherapp.com", "the host should be set as \"ws.pusherapp.com\"")
    }

    func testDefaultPortConfig() {
        XCTAssertEqual(pusher.connection.options.port, 443, "the port should be set as 443")
    }

    func testProvidingEcryptedOptionAsFalse() {
        let options = PusherClientOptions(
            encrypted: false
        )
        pusher = Pusher(key: key, options: options)
        XCTAssertEqual(pusher.connection.url, "ws://ws.pusherapp.com:80/app/testKey123?client=pusher-websocket-swift&version=\(VERSION)&protocol=7", "the connection should be set correctly")
    }

    func testProvidingAnAuthEndpointAuthMethodOption() {
        let options = PusherClientOptions(
            authMethod: .endpoint(authEndpoint: "http://myapp.com/auth-endpoint")
        )
        pusher = Pusher(key: key, options: options)
        XCTAssertEqual(pusher.connection.options.authMethod, AuthMethod.endpoint(authEndpoint: "http://myapp.com/auth-endpoint"), "the authMethod should be set correctly")
    }

    func testProvidingAnInlineAuthMethodOption() {
        let options = PusherClientOptions(
            authMethod: .inline(secret: "superSecret")
        )
        pusher = Pusher(key: key, options: options)
        XCTAssertEqual(pusher.connection.options.authMethod, AuthMethod.inline(secret: "superSecret"), "the authMethod should be set correctly")
    }

    func testProvidingAttemptToReturnJSONObjectOptionAsFalse() {
        let options = PusherClientOptions(
            attemptToReturnJSONObject: false
        )
        pusher = Pusher(key: key, options: options)
        XCTAssertFalse(pusher.connection.options.attemptToReturnJSONObject, "the attemptToReturnJSONObject option should be false")
    }

    func testProvidingAHostOption() {
        let options = PusherClientOptions(
            host: PusherHost.host("test.test.test")
        )
        pusher = Pusher(key: key, options: options)
        XCTAssertEqual(pusher.connection.options.host, "test.test.test", "the host should be \"test.test.test\"")
    }

    func testProvidingAPortOption() {
        let options = PusherClientOptions(
            port: 123
        )
        pusher = Pusher(key: key, options: options)
        XCTAssertEqual(pusher.connection.options.port, 123, "the port should be 123")
    }

    func testProvidingAClusterOption() {
        let options = PusherClientOptions(
            host: PusherHost.cluster("eu")
        )
        pusher = Pusher(key: key, options: options)
        XCTAssertEqual(pusher.connection.options.host, "ws-eu.pusher.com", "the host should be \"ws-eu.pusher.com\"")
    }
}
