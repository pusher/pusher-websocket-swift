//
//  PusherSwiftTests.swift
//  PusherSwiftTests
//
//  Created by Hamilton Chapman on 24/02/2015.
//
//

import Foundation
import Quick
import Nimble
import PusherSwift

let VERSION = "2.0.1"

class PusherClientInitializationSpec: QuickSpec {
    override func spec() {
        describe("creating the connection") {
            var key: String!
            var pusher: Pusher!

            beforeEach({
                key = "testKey123"
                pusher = Pusher(key: key)
            })

            it("has the connection object") {
                expect(pusher.connection).toNot(beNil())
            }

            context("with default config") {
                it("has the correct conection url") {
                    expect(pusher.connection.url).to(equal("wss://ws.pusherapp.com:443/app/testKey123?client=pusher-websocket-swift&version=\(VERSION)&protocol=7"))
                }

                it("has auth method as .NoMethod") {
                    expect(pusher.connection.options.authMethod).to(equal(AuthMethod.NoMethod))
                }

                it("has attemptToReturnJSONObject as true") {
                    expect(pusher.connection.options.attemptToReturnJSONObject).to(beTruthy())
                }

                it("has the host set correctly") {
                    expect(pusher.connection.options.host).to(equal("ws.pusherapp.com"))
                }

                it("has the port set as 443") {
                    expect(pusher.connection.options.port).to(equal(443))
                }
            }

            context("passing in configuration options") {
                context("unencrypted") {
                    it("has the correct conection url") {
                        let options = PusherClientOptions(
                            encrypted: false
                        )
                        pusher = Pusher(key: key, options: options)
                        expect(pusher.connection.url).to(equal("ws://ws.pusherapp.com:80/app/testKey123?client=pusher-websocket-swift&version=\(VERSION)&protocol=7"))
                    }
                }

                context("an auth endpoint") {
                    it("has one set") {
                        let options = PusherClientOptions(
                            authMethod: .Endpoint(authEndpoint: "http://myapp.com/auth-endpoint")
                        )
                        pusher = Pusher(key: key, options: options)
                        expect(pusher.connection.options.authMethod).to(equal(AuthMethod.Endpoint(authEndpoint: "http://myapp.com/auth-endpoint")))
                    }
                }

                context("a secret") {
                    it("has one set") {
                        let options = PusherClientOptions(
                            authMethod: .Internal(secret: "superSecret")
                        )
                        pusher = Pusher(key: key, options: options)
                        expect(pusher.connection.options.authMethod).to(equal(AuthMethod.Internal(secret: "superSecret")))
                    }
                }

                context("attemptToReturnJSONObject as false") {
                    it("is false") {
                        let options = PusherClientOptions(
                            attemptToReturnJSONObject: false
                        )
                        pusher = Pusher(key: key, options: options)
                        expect(pusher.connection.options.attemptToReturnJSONObject).to(beFalsy())
                    }
                }

                context("a host") {
                    it("has one set") {
                        let options = PusherClientOptions(
                            host: PusherHost.Host("test.test.test")
                        )
                        pusher = Pusher(key: key, options: options)
                        expect(pusher.connection.options.host).to(equal("test.test.test"))
                    }
                }

                context("a port") {
                    it("sets the URL with it") {
                        let options = PusherClientOptions(
                            port: 123
                        )
                        pusher = Pusher(key: key, options: options)
                        expect(pusher.connection.options.port).to(equal(123))
                    }
                }

                context("a cluster as host") {
                    it("sets the host correctly") {
                        let options = PusherClientOptions(
                            host: PusherHost.Cluster("eu")
                        )
                        pusher = Pusher(key: key, options: options)
                        expect(pusher.connection.options.host).to(equal("ws-eu.pusher.com"))
                    }
                }
            }
        }
    }
}
