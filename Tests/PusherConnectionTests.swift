//
//  PusherConnectionTests.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 21/06/2016.
//
//

import Foundation


//                it("has userDataFetcher as nil") {
//                    expect(pusher.connection.options.userDataFetcher).to(beNil())
//                }
//
//                it("has authRequestCustomizer as nil") {
//                    expect(pusher.connection.options.authRequestCustomizer).to(beNil())
//                }
//
//                it("has debugLogger set as nil") {
//                    expect(pusher.connection.options.debugLogger).to(beNil())
//                }
//
//                context("an authRequestCustomizer") {
//                    it("has one set") {
//                        func customizer(request: NSMutableURLRequest) -> NSMutableURLRequest {
//                            return request
//                        }
//                        pusher = Pusher(key: key, options: ["authRequestCustomizer": customizer])
//                        expect(pusher.connection.options.authRequestCustomizer).toNot(beNil())
//                    }
//                }
//
//                context("a debugLogger") {
//                    it("sets the debugLogger with it") {
//                        let debugLogger = { (text: String) in }
//                        pusher = Pusher(key: key, options: ["debugLogger": debugLogger])
//                        expect(pusher.connection.options.debugLogger).toNot(beNil())
//                    }
//                }
//
//                context("a userDataFetcher function") {
//                    it("has one function set") {
//                        func fetchFunc() -> PusherUserData {
//                            return PusherUserData(userId: "1")
//                        }
//                        pusher = Pusher(key: key, options: ["userDataFetcher": fetchFunc])
//                        expect(pusher.connection.options.userDataFetcher).toNot(beNil())
//                    }
//                }