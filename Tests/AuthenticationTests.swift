//
//  AuthenticationTests.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 07/04/2016.
//
//

import Quick
import Nimble
import PusherSwift

class AuthenticationSpec: QuickSpec {
    override func spec() {
        var pusher: Pusher!
        var socket: MockWebSocket!

        beforeEach({
            let options = PusherClientOptions(
                authMethod: AuthMethod.endpoint(authEndpoint: "http://localhost:9292/pusher/auth")
            )
            pusher = Pusher(key: "testKey123", options: options)
            socket = MockWebSocket()
            socket.delegate = pusher.connection
            pusher.connection.socket = socket
        })

        describe("subscribing to a private channel") {
            it("should make a request to the authEndpoint") {
                if case .endpoint(authEndpoint: let authEndpoint) = pusher.connection.options.authMethod {
                    let jsonData = "{\"auth\":\"testKey123:12345678gfder78ikjbg\"}".data(using: String.Encoding.utf8, allowLossyConversion: false)!
                    let urlResponse = HTTPURLResponse(url: URL(string: "\(authEndpoint)?channel_name=private-test-channel&socket_id=45481.3166671")!, statusCode: 200, httpVersion: nil, headerFields: nil)
                    MockSession.mockResponse = (jsonData, urlResponse: urlResponse, error: nil)
                    pusher.connection.URLSession = MockSession.mockShared

                }
                let chan = pusher.subscribe("private-test-channel")
                expect(chan.subscribed).to(beFalsy())
                pusher.connect()
                expect(chan.subscribed).toEventually(beTruthy())
            }

            it("should create the auth signature internally") {
                let options = PusherClientOptions(
                    authMethod: .inline(secret: "secret")
                )
                pusher = Pusher(key: "key", options: options)
                socket.delegate = pusher.connection
                pusher.connection.socket = socket

                let chan = pusher.subscribe("private-test-channel")
                expect(chan.subscribed).to(beFalsy())
                pusher.connect()
                expect(chan.subscribed).to(beTruthy())
            }

            it("should not subscribe successfully to a private or presence channel if no auth method provided") {
                pusher = Pusher(key: "key")
                socket.delegate = pusher.connection
                pusher.connection.socket = socket

                let chan = pusher.subscribe("private-test-channel")
                expect(chan.subscribed).to(beFalsy())
                pusher.connect()
                expect(chan.subscribed).to(beFalsy())
            }

            it("should handle authorization errors by locally handling a pusher:subscription_error event") {
                let stubber = StubberForMocks()

                if case .endpoint(authEndpoint: let authEndpoint) = pusher.connection.options.authMethod {
                    let urlResponse = HTTPURLResponse(url: URL(string: "\(authEndpoint)?channel_name=private-test-channel&socket_id=45481.3166671")!, statusCode: 500, httpVersion: nil, headerFields: nil)
                    MockSession.mockResponse = (nil, urlResponse: urlResponse, error: nil)
                    pusher.connection.URLSession = MockSession.mockShared
                }

                let chan = pusher.subscribe("private-test-channel")
                expect(chan.subscribed).to(beFalsy())

                let _ = pusher.bind({ (data: Any?) -> Void in
                    if let data = data as? [String: AnyObject], let eventName = data["event"] as? String, eventName == "pusher:subscription_error" {
                        expect(Thread.isMainThread).to(equal(true))
                        let _ = stubber.stub("subscriptionErrorCallback", args: [eventName], functionToCall: nil)
                    }
                })

                pusher.connect()
                expect(stubber.calls.last?.name).toEventually(equal("subscriptionErrorCallback"))
                expect(stubber.calls.last?.args?.last as? String).toEventually(equal("pusher:subscription_error"))
            }

            it("should make the request created by something conforming to the AuthRequestBuilderProtocol") {
                struct AuthRequestBuilder: AuthRequestBuilderProtocol {
                    func requestFor(socketID: String, channel: PusherChannel) -> NSMutableURLRequest? {
                        let request = NSMutableURLRequest(url: URL(string: "http://localhost:9292/builder")!)
                        request.httpMethod = "POST"
                        request.httpBody = "socket_id=\(socketID)&channel_name=\(channel.name)".data(using: String.Encoding.utf8)
                        request.addValue("myToken", forHTTPHeaderField: "Authorization")
                        return request
                    }
                }

                let options = PusherClientOptions(
                    authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: AuthRequestBuilder())
                )
                pusher = Pusher(key: "testKey123", options: options)
                socket.delegate = pusher.connection
                pusher.connection.socket = socket

                let jsonData = "{\"auth\":\"testKey123:12345678gfder78ikjbg\"}".data(using: String.Encoding.utf8, allowLossyConversion: false)!
                let urlResponse = HTTPURLResponse(url: URL(string: "http://localhost:9292/builder?channel_name=private-test-channel&socket_id=45481.3166671")!, statusCode: 200, httpVersion: nil, headerFields: nil)
                MockSession.mockResponse = (jsonData, urlResponse: urlResponse, error: nil)
                pusher.connection.URLSession = MockSession.mockShared

                let chan = pusher.subscribe("private-test-channel")
                expect(chan.subscribed).to(beFalsy())
                pusher.connect()
                expect(chan.subscribed).toEventually(beTruthy())
            }
        }
    }
}
