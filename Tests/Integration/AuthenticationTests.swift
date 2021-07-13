import XCTest

@testable import PusherSwift

class AuthenticationTests: XCTestCase {
    private class DummyDelegate: PusherDelegate {
        var ex: XCTestExpectation?
        var testingChannelName: String?

        func subscribedToChannel(name: String) {
            guard let cName = testingChannelName, cName == name else {
                return
            }

            ex!.fulfill()
        }
    }

    private var pusher: Pusher!
    private var socket: MockWebSocket!

    private let authJSONData = "{\"\(Constants.JSONKeys.auth)\":\"testKey123:12345678gfder78ikjbg\"}".data(using: .utf8)!

    override func setUp() {
        super.setUp()

        let options = PusherClientOptions(
            authMethod: AuthMethod.endpoint(authEndpoint: "http://localhost:9292/pusher/auth"),
            autoReconnect: false
        )
        pusher = Pusher(key: "testKey123", options: options)
        socket = MockWebSocket()
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
    }

    func testSubscribingToAPrivateChannelShouldMakeARequestToTheAuthEndpoint() {
        let ex = expectation(description: "the channel should be subscribed to successfully")
        let channelName = "private-test-channel"

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName
        pusher.delegate = dummyDelegate

        if case .endpoint(authEndpoint: let authEndpoint) = pusher.connection.options.authMethod {
            let urlResponse = HTTPURLResponse(url: URL(string: "\(authEndpoint)?channel_name=private-test-channel&socket_id=45481.3166671")!, statusCode: 200, httpVersion: nil, headerFields: nil)
            MockSession.mockResponse = (authJSONData, urlResponse: urlResponse, error: nil)
            pusher.connection.URLSession = MockSession.shared
        }

        let chan = pusher.subscribe(channelName)
        XCTAssertFalse(chan.subscribed, "the channel should not be subscribed")
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testSubscribingToAPrivateChannelShouldMakeARequestToTheAuthEndpointWithAnEncodedChannelName() {
        let ex = expectation(description: "the channel should be subscribed to successfully")
        let channelName = "private-reservations-for-venue@venue_id=399edd2d-3f4a-43k9-911c-9e4b6bdf0f16;date=2017-01-13"

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName
        pusher.delegate = dummyDelegate

        if case .endpoint(authEndpoint: let authEndpoint) = pusher.connection.options.authMethod {
            let urlResponse = HTTPURLResponse(url: URL(string: "\(authEndpoint)?channel_name=private-reservations-for-venue%40venue_id%3D399ccd2d-3f4a-43c9-803c-9e4b6bdf0f16%3Bdate%3D2017-01-13&socket_id=45481.3166671")!, statusCode: 200, httpVersion: nil, headerFields: nil)
            MockSession.mockResponse = (authJSONData, urlResponse: urlResponse, error: nil)
            pusher.connection.URLSession = MockSession.shared
        }

        let chan = pusher.subscribe(channelName)
        XCTAssertFalse(chan.subscribed, "the channel should not be subscribed")
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testSubscribingToAPrivateChannelShouldCreateAuthSignatureInternally() {
        let options = PusherClientOptions(
            authMethod: .inline(secret: "secret"),
            autoReconnect: false
        )
        pusher = Pusher(key: "key", options: options)
        socket.delegate = pusher.connection
        pusher.connection.socket = socket

        let chan = pusher.subscribe("private-test-channel")
        XCTAssertFalse(chan.subscribed, "the channel should not be subscribed")

        let ex = expectation(description: "subscription succeed")
        chan.bind(eventName: Constants.Events.Pusher.subscriptionSucceeded) { (_: PusherEvent) in
            ex.fulfill()
            XCTAssertTrue(chan.subscribed, "the channel should be subscribed")
        }
        pusher.connect()
        waitForExpectations(timeout: 0.5)
    }

    func testSubscribingToAPrivateChannelShouldFailIfNoAuthMethodIsProvided() {
        let options = PusherClientOptions(
            autoReconnect: false
        )
        pusher = Pusher(key: "key", options: options)
        socket.delegate = pusher.connection
        pusher.connection.socket = socket

        let chan = pusher.subscribe("private-test-channel")
        XCTAssertFalse(chan.subscribed, "the channel should not be subscribed")
        pusher.connect()
        XCTAssertFalse(chan.subscribed, "the channel should not be subscribed")
    }

    func testAuthorizationErrorsShouldLeadToAPusherSubscriptionErrorEventBeingHandled() {
        let ex = expectation(description: "subscription error callback gets called")

        if case .endpoint(authEndpoint: let authEndpoint) = pusher.connection.options.authMethod {
            let urlResponse = HTTPURLResponse(url: URL(string: "\(authEndpoint)?channel_name=private-test-channel&socket_id=45481.3166671")!, statusCode: 500, httpVersion: nil, headerFields: nil)
            MockSession.mockResponse = (nil, urlResponse: urlResponse, error: nil)
            pusher.connection.URLSession = MockSession.shared
        }

        let chan = pusher.subscribe("private-test-channel")
        XCTAssertFalse(chan.subscribed, "the channel should not be subscribed")

        pusher.bind { event in
            XCTAssertEqual(event.eventName, Constants.Events.Pusher.subscriptionError)
            XCTAssertEqual(event.channelName, "private-test-channel")
            XCTAssertTrue(Thread.isMainThread)
            ex.fulfill()
        }

        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testAuthorizationUsingSomethingConformingToTheAuthRequestBuilderProtocol() {

        class AuthRequestBuilder: AuthRequestBuilderProtocol {
            func requestFor(socketID: String, channelName: String) -> URLRequest? {
                var request = URLRequest(url: URL(string: "http://localhost:9292/builder")!)
                request.httpMethod = "POST"
                request.httpBody = "socket_id=\(socketID)&channel_name=\(channelName)".data(using: .utf8)
                request.addValue("myToken", forHTTPHeaderField: "Authorization")
                return request
            }
        }

        let ex = expectation(description: "the channel should be subscribed to successfully")
        let channelName = "private-test-channel"

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName

        let options = PusherClientOptions(
            authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: AuthRequestBuilder()),
            autoReconnect: false
        )
        pusher = Pusher(key: "testKey123", options: options)
        pusher.delegate = dummyDelegate
        socket.delegate = pusher.connection
        pusher.connection.socket = socket

        let urlResponse = HTTPURLResponse(url: URL(string: "http://localhost:9292/builder?channel_name=private-test-channel&socket_id=45481.3166671")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        MockSession.mockResponse = (authJSONData, urlResponse: urlResponse, error: nil)
        pusher.connection.URLSession = MockSession.shared

        let chan = pusher.subscribe("private-test-channel")
        XCTAssertFalse(chan.subscribed, "the channel should not be subscribed")
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testSubscribingToAPrivateChannelWhenAnAuthValueIsProvidedShouldWork() {
        let ex = expectation(description: "the channel should be subscribed to successfully")
        let channelName = "private-manual-auth"

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName
        pusher.delegate = dummyDelegate

        let chan = pusher.subscribe(channelName, auth: PusherAuth(auth: "testKey123:12345678gfder78ikjbgmanualauth"))
        XCTAssertFalse(chan.subscribed, "the channel should not be subscribed")
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testSubscribingToAPresenceChannelWhenAnAuthValueIsProvidedShouldWork() {
        let ex = expectation(description: "the channel should be subscribed to successfully")
        let channelName = "presence-manual-auth"

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName
        pusher.delegate = dummyDelegate

        let chan = pusher.subscribe(
            channelName,
            auth: PusherAuth(
                auth: "testKey123:12345678gfder78ikjbgmanualauth",
                channelData: "{\"\(Constants.JSONKeys.userId)\":16,\"\(Constants.JSONKeys.userInfo)\":{\"time\":\"2017-02-20 14:54:36 +0000\"}}"
            )
        )
        XCTAssertFalse(chan.subscribed, "the channel should not be subscribed")
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testAuthorizationUsingSomethingConformingToTheAuthorizerProtocol() {

        class SomeAuthorizer: Authorizer {
            func fetchAuthValue(socketID: String, channelName: String, completionHandler: @escaping (PusherAuth?) -> Void) {
                completionHandler(PusherAuth(auth: "testKey123:authorizerblah123"))
            }
        }

        let ex = expectation(description: "the channel should be subscribed to successfully")
        let channelName = "private-test-channel-authorizer"

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName

        let options = PusherClientOptions(
            authMethod: AuthMethod.authorizer(authorizer: SomeAuthorizer()),
            autoReconnect: false
        )
        pusher = Pusher(key: "testKey123", options: options)
        pusher.delegate = dummyDelegate
        socket.delegate = pusher.connection
        pusher.connection.socket = socket

        let chan = pusher.subscribe(channelName)
        XCTAssertFalse(chan.subscribed, "the channel should not be subscribed")
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }

    func testAuthorizationOfPresenceChannelSubscriptionUsingSomethingConformingToTheAuthorizerProtocol() {

        class SomeAuthorizer: Authorizer {
            func fetchAuthValue(socketID: String, channelName: String, completionHandler: @escaping (PusherAuth?) -> Void) {
                completionHandler(PusherAuth(
                    auth: "testKey123:authorizerblah1234",
                    channelData: "{\"\(Constants.JSONKeys.userId)\":\"777\", \"\(Constants.JSONKeys.userInfo)\":{\"twitter\":\"hamchapman\"}}"
                ))
            }
        }

        let ex = expectation(description: "the channel should be subscribed to successfully")
        let channelName = "presence-test-channel-authorizer"

        let dummyDelegate = DummyDelegate()
        dummyDelegate.ex = ex
        dummyDelegate.testingChannelName = channelName

        let options = PusherClientOptions(
            authMethod: AuthMethod.authorizer(authorizer: SomeAuthorizer()),
            autoReconnect: false
        )
        pusher = Pusher(key: "testKey123", options: options)
        pusher.delegate = dummyDelegate
        socket.delegate = pusher.connection
        pusher.connection.socket = socket

        let chan = pusher.subscribe(channelName)
        XCTAssertFalse(chan.subscribed, "the channel should not be subscribed")
        pusher.connect()

        waitForExpectations(timeout: 0.5)
    }
}
