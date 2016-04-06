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

let VERSION = "0.3.0"

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

                it("has auth endpoint as nil") {
                    expect(pusher.connection.options.authEndpoint).to(beNil())
                }

                it("has secret as nil") {
                    expect(pusher.connection.options.secret).to(beNil())
                }

                it("has userDataFetcher as nil") {
                    expect(pusher.connection.options.userDataFetcher).to(beNil())
                }

                it("has attemptToReturnJSONObject as true") {
                    expect(pusher.connection.options.attemptToReturnJSONObject).to(beTruthy())
                }

                it("has auth method of none") {
                    expect(pusher.connection.options.authMethod).to(equal(AuthMethod.NoMethod))
                }

                it("has authRequestCustomizer as nil") {
                    expect(pusher.connection.options.authRequestCustomizer).to(beNil())
                }

                it("has the host set correctly") {
                    expect(pusher.connection.options.host).to(equal("ws.pusherapp.com"))
                }

                it("has the port set as nil") {
                    expect(pusher.connection.options.port).to(beNil())
                }
            }

            context("passing in configuration options") {
                context("unencrypted") {
                    it("has the correct conection url") {
                        pusher = Pusher(key: key, options: ["encrypted": false])
                        expect(pusher.connection.url).to(equal("ws://ws.pusherapp.com:80/app/testKey123?client=pusher-websocket-swift&version=\(VERSION)&protocol=7"))
                    }
                }

                context("an auth endpoint") {
                    it("has one set") {
                        pusher = Pusher(key: key, options: ["authEndpoint": "http://myapp.com/auth-endpoint"])
                        expect(pusher.connection.options.authEndpoint).to(equal("http://myapp.com/auth-endpoint"))
                    }
                }

                context("a secret") {
                    it("has one set") {
                        pusher = Pusher(key: key, options: ["secret": "superSecret"])
                        expect(pusher.connection.options.secret).to(equal("superSecret"))
                    }
                }

                context("a userDataFetcher function") {
                    it("has one function set") {
                        func fetchFunc() -> PusherUserData {
                            return PusherUserData(userId: "1")
                        }
                        pusher = Pusher(key: key, options: ["userDataFetcher": fetchFunc])
                        expect(pusher.connection.options.userDataFetcher).toNot(beNil())
                    }
                }

                context("attemptToReturnJSONObject as false") {
                    it("is false") {
                        pusher = Pusher(key: key, options: ["attemptToReturnJSONObject": false])
                        expect(pusher.connection.options.attemptToReturnJSONObject).to(beFalsy())
                    }
                }

                context("an authRequestCustomizer") {
                    it("has one set") {
                        func customizer(request: NSMutableURLRequest) -> NSMutableURLRequest {
                            return request
                        }
                        pusher = Pusher(key: key, options: ["authRequestCustomizer": customizer])
                        expect(pusher.connection.options.authRequestCustomizer).toNot(beNil())
                    }
                }

                context("a host") {
                    it("has one set") {
                        pusher = Pusher(key: key, options: ["host": "test.test.test"])
                        expect(pusher.connection.options.host).to(equal("test.test.test"))
                    }
                }

                context("a port") {
                    it("sets the URL with it") {
                        pusher = Pusher(key: key, options: ["port": 123])
                        expect(pusher.connection.options.port).to(equal(123))
                    }
                }

                context("a cluster") {
                    context("and no host") {
                        it("sets the host correctly") {
                            pusher = Pusher(key: key, options: ["cluster": "eu"])
                            expect(pusher.connection.options.host).to(equal("ws-eu.pusher.com"))
                        }
                    }

                    context("and a host") {
                        it("sets the host correctly") {
                            pusher = Pusher(key: key, options: ["cluster": "eu", "host": "test.test.test"])
                            expect(pusher.connection.options.host).to(equal("test.test.test"))
                        }
                    }
                }
            }
        }
    }
}
