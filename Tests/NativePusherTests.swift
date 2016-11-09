//
//  NativePusherTests.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 19/09/2016.
//
//

#if os(iOS)

@testable import PusherSwift
import XCTest

func setUpDefaultMockResponses(pusherClient: Pusher, deviceClientId: String) {
    let jsonData = "{\"id\":\"\(deviceClientId)\"}".data(using: String.Encoding.utf8, allowLossyConversion: false)!
    let url = URL(string: "https://nativepushclient-cluster1.pusher.com/client_api/v1/clients")!
    let urlResponse = HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil, headerFields: nil)
    MockSession.addMockResponse(for: url, httpMethod: "POST", data: jsonData, urlResponse: urlResponse, error: nil)

    let emptyJsonData = "".data(using: String.Encoding.utf8)!
    let subscriptionModificationUrl = URL(string: "https://nativepushclient-cluster1.pusher.com/client_api/v1/clients/\(deviceClientId)/interests/donuts")!
    let susbcriptionModificationResponse = HTTPURLResponse(url: subscriptionModificationUrl, statusCode: 204, httpVersion: nil, headerFields: nil)
    let httpMethodForSubscribe = "POST"
    MockSession.addMockResponse(for: subscriptionModificationUrl, httpMethod: httpMethodForSubscribe, data: emptyJsonData, urlResponse: susbcriptionModificationResponse, error: nil)
    let httpMethodForUnsubscribe = "DELETE"
    MockSession.addMockResponse(for: subscriptionModificationUrl, httpMethod: httpMethodForUnsubscribe, data: emptyJsonData, urlResponse: susbcriptionModificationResponse, error: nil)

    pusherClient.nativePusher.URLSession = MockSession.shared
}

class NativePusherTests: XCTestCase {
    public class DummyDelegate: PusherDelegate {
        public var testClientId: String? = nil
        public var registerEx: XCTestExpectation? = nil
        public var subscribeEx: XCTestExpectation? = nil
        public var unsubscribeEx: XCTestExpectation? = nil
        public var interestName: String? = nil

        public func subscribedToInterest(name: String) {
            if interestName == name {
                subscribeEx!.fulfill()
            }
        }

        public func unsubscribedFromInterest(name: String) {
            if interestName == name {
                unsubscribeEx!.fulfill()
            }
        }

        public func registeredForPushNotifications(clientId: String) {
            XCTAssertEqual(clientId, testClientId)
            registerEx!.fulfill()
        }
    }

    var key: String!
    var pusher: Pusher!
    var socket: MockWebSocket!
    var dummyDelegate: DummyDelegate!
    var testClientId: String!

    override func setUp() {
        super.setUp()

        key = "testKey123"
        testClientId = "your_client_id"
        let options = PusherClientOptions(
            authMethod: AuthMethod.inline(secret: "secret"),
            autoReconnect: false
        )

        pusher = Pusher(key: key, options: options)
        socket = MockWebSocket()
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        dummyDelegate = DummyDelegate()
        pusher.delegate = dummyDelegate
    }

    func testReceivingAClientIdAfterRegisterIsCalled() {
        setUpDefaultMockResponses(pusherClient: pusher, deviceClientId: testClientId)

        let ex = expectation(description: "the clientId should be received when registration succeeds")
        dummyDelegate.testClientId = testClientId
        dummyDelegate.registerEx = ex

        pusher.nativePusher.register(deviceToken: "SOME_DEVICE_TOKEN".data(using: String.Encoding.utf8)!)
        waitForExpectations(timeout: 0.5)
    }

    func testSubscribingToAnInterest() {
        setUpDefaultMockResponses(pusherClient: pusher, deviceClientId: testClientId)

        let registerEx = expectation(description: "the clientId should be received when registration succeeds")
        let subscribeEx = expectation(description: "the client should successfully subscribe to an interest")

        dummyDelegate.testClientId = testClientId
        dummyDelegate.interestName = "donuts"
        dummyDelegate.registerEx = registerEx
        dummyDelegate.subscribeEx = subscribeEx

        pusher.nativePusher.subscribe(interestName: "donuts")
        pusher.nativePusher.register(deviceToken: "SOME_DEVICE_TOKEN".data(using: String.Encoding.utf8)!)

        waitForExpectations(timeout: 0.5)
    }

    func testUnsubscribingFromAnInterest() {
        setUpDefaultMockResponses(pusherClient: pusher, deviceClientId: testClientId)

        let registerEx = expectation(description: "the clientId should be received when registration succeeds")
        let subscribeEx = expectation(description: "the client should successfully subscribe to an interest")
        let unsubscribeEx = expectation(description: "the client should successfully unsubscribe from an interest")
        dummyDelegate.testClientId = testClientId
        dummyDelegate.interestName = "donuts"
        dummyDelegate.registerEx = registerEx
        dummyDelegate.subscribeEx = subscribeEx
        dummyDelegate.unsubscribeEx = unsubscribeEx

        pusher.nativePusher.subscribe(interestName: "donuts")
        pusher.nativePusher.register(deviceToken: "SOME_DEVICE_TOKEN".data(using: String.Encoding.utf8)!)
        pusher.nativePusher.unsubscribe(interestName: "donuts")

        waitForExpectations(timeout: 0.5)
    }

    func testSubscribingWhenClientIdIsNotSetQueuesSubscriptionModificationRequest() {
        pusher.nativePusher.clientId = nil

        XCTAssertEqual(pusher.nativePusher.requestQueue.count, 0, "the nativePusher request queue should be empty")
        pusher.nativePusher.subscribe(interestName: "donuts")

        Thread.sleep(forTimeInterval: 0.5)

        XCTAssertEqual(pusher.nativePusher.requestQueue.count, 1, "the nativePusher request queue should contain the subscribe request")
        XCTAssertEqual(pusher.nativePusher.requestQueue.paused, true, "the nativePusher request queue should be paused")
    }
}

#endif
