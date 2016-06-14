//
//  PusherChannelTests.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 07/04/2016.
//
//

import Quick
import Nimble
import PusherSwift

class PusherChannelSpec: QuickSpec {
    override func spec() {
        describe("creating the channel") {
            it("sets up the channel with the correct name and no callbacks") {
                let chan = PusherChannel(name: "test-channel", connection: MockPusherConnection())
                expect(chan.name).to(equal("test-channel"))
                expect(chan.eventHandlers).to(beEmpty())
            }
        }

        describe("binding to an event") {
            it("adds an eventName, callback pair to a channel's callbacks") {
                let chan = PusherChannel(name: "test-channel", connection: MockPusherConnection())
                expect(chan.eventHandlers["test-event"]).to(beNil())
                chan.bind("test-event", callback: { (data: AnyObject?) -> Void in print(data) })
                expect(chan.eventHandlers["test-event"]).toNot(beNil())
            }
        }

        describe("unbinding an eventHandler") {
            it("should remove the eventHandler for the given eventName and eventHandler id") {
                let chan = PusherChannel(name: "test-channel", connection: MockPusherConnection())
                expect(chan.eventHandlers["test-event"]).to(beNil())
                let idOne = chan.bind("test-event", callback: { (data: AnyObject?) -> Void in print(data) })
                chan.bind("test-event", callback: { (data: AnyObject?) -> Void in print(data) })
                expect(chan.eventHandlers["test-event"]?.count).to(equal(2))
                chan.unbind("test-event", callbackId: idOne)
                expect(chan.eventHandlers["test-event"]?.count).to(equal(1))
            }
        }

        describe("unbinding all eventHandlers for an eventName") {
            it("should remove the eventHandlers for the given eventName") {
                let chan = PusherChannel(name: "test-channel", connection: MockPusherConnection())
                expect(chan.eventHandlers["test-event"]).to(beNil())
                chan.bind("test-event", callback: { (data: AnyObject?) -> Void in print(data) })
                chan.bind("test-event", callback: { (data: AnyObject?) -> Void in print(data) })
                expect(chan.eventHandlers["test-event"]?.count).to(equal(2))
                chan.unbindAllForEventName("test-event")
                expect(chan.eventHandlers["test-event"]?.count).to(equal(0))
            }
        }

        describe("unbinding all eventHandlers") {
            it("should remove the eventHandler for the given eventName and eventHandler id") {
                let chan = PusherChannel(name: "test-channel", connection: MockPusherConnection())
                expect(chan.eventHandlers["test-event"]).to(beNil())
                chan.bind("test-event", callback: { (data: AnyObject?) -> Void in print(data) })
                chan.bind("test-event", callback: { (data: AnyObject?) -> Void in print(data) })
                chan.bind("another-test-event", callback: { (data: AnyObject?) -> Void in print(data) })
                expect(chan.eventHandlers.count).to(equal(2))
                chan.unbindAll()
                expect(chan.eventHandlers.count).to(equal(0))
            }
        }

        describe("triggering a client event") {
            var connection: MockPusherConnection!
            var socket: MockWebSocket!

            beforeEach({
                socket = MockWebSocket()
                connection = MockPusherConnection(options: ["secret": "superSecretSecret"])
                socket.delegate = connection
                connection.socket = socket
            })

            it("should not result in the socket writing a string if the channel isn't a private or presence channel") {
                let chan = PusherChannel(name: "test-channel", connection: connection)
                chan.subscribed = true
                chan.trigger("client-test-event", data: ["data": "testing client events"])
                expect(socket.stubber.calls).to(beEmpty())
            }

            it("should result in the socket writing a string if the channel is a private or presence channel") {
                let chan = PusherChannel(name: "private-channel", connection: connection)
                chan.subscribed = true
                chan.trigger("client-test-event", data: ["data": "testing client events"])
                let parsedSubscribeArgs = convertStringToDictionary(socket.stubber.calls.first?.args!.first as! String)
                let expectedDict = ["data": ["data": "testing client events"], "event": "client-test-event", "channel": "private-channel"]
                let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqualToDictionary(NSDictionary(dictionary: expectedDict) as [NSObject : AnyObject])
                expect(parsedEqualsExpected).to(beTrue())
            }

            it("should send any client events that were triggered before subscription was successful") {
                let chan = PusherChannel(name: "private-channel", connection: connection)
                connection.channels.channels["private-channel"] = chan
                expect(chan.unsentEvents).to(beEmpty())
                chan.trigger("client-test-event", data: ["data": "testing client events"])
                expect(chan.unsentEvents.last!.name).to(equal("client-test-event"))
                expect(socket.stubber.calls).to(beEmpty())
                connection.connect()
                let parsedSubscribeArgs = convertStringToDictionary(socket.stubber.calls.last?.args!.first as! String)
                let expectedDict = ["data": ["data": "testing client events"], "event": "client-test-event", "channel": "private-channel"]
                let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqualToDictionary(NSDictionary(dictionary: expectedDict) as [NSObject : AnyObject])
                expect(parsedEqualsExpected).to(beTrue())
            }

            it("should send multipe client events with the same event name that were triggered before subscription was successful") {
                let chan = PusherChannel(name: "private-channel", connection: connection)
                connection.channels.channels["private-channel"] = chan
                expect(chan.unsentEvents).to(beEmpty())
                chan.trigger("client-test-event", data: ["data": "testing client events"])
                chan.trigger("client-test-event", data: ["data": "more testing client events"])
                expect(chan.unsentEvents.last!.name).to(equal("client-test-event"))
                expect(chan.unsentEvents.count).to(equal(2))
                expect(socket.stubber.calls).to(beEmpty())
                connection.connect()
                let parsedSubscribeArgs = convertStringToDictionary(socket.stubber.calls.last?.args!.first as! String)
                let expectedDict = ["data": ["data": "more testing client events"], "event": "client-test-event", "channel": "private-channel"]
                let parsedEqualsExpected = NSDictionary(dictionary: parsedSubscribeArgs!).isEqualToDictionary(NSDictionary(dictionary: expectedDict) as [NSObject : AnyObject])
                expect(parsedEqualsExpected).to(beTrue())
            }
        }
    }
}

