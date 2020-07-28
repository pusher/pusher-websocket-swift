@testable import PusherSwiftWithEncryption
import XCTest

class PrivateEncryptedChannelTests: XCTestCase {


    private let channelName = "private-encrypted-channel"
    private let eventName = "my-event"
    private let authEndpointURL = "http://localhost:3030"

    private let validAuth = PusherAuth(auth: "636a81ba7e7b15725c00:3ee04892514e8a669dc5d30267221f16727596688894712cad305986e6fc0f3c", sharedSecret: "iBvNoPVYwByqSfg6anjPpEQ2j051b3rt1Vmnb+z5doo=")
    private lazy var validAuthData = "{\"auth\":\"\(validAuth.auth)\",\"shared_secret\":\"\(validAuth.sharedSecret!)\"}"

    private let incorrectSharedSecretAuth = PusherAuth(auth: "636a81ba7e7b15725c00:3ee04892514e8a669dc5d30267221f16727596688894712cad305986e6fc0f3c", sharedSecret: "iBvNoPVYwByqSfg6anjPpEQ2j051b3rt1Vmnb+z5do0=")
    private lazy var incorrectSharedSecretAuthData = "{\"auth\":\"\(incorrectSharedSecretAuth.auth)\",\"shared_secret\":\"\(incorrectSharedSecretAuth.sharedSecret!)\"}"

    func configurePusherWithAuthMethod(authMethod: AuthMethod? = nil) -> (Pusher, MockWebSocket) {
        super.setUp()

        let authMethod = authMethod ?? AuthMethod.endpoint(authEndpoint: authEndpointURL)

        let options = PusherClientOptions(
            authMethod: authMethod,
            autoReconnect: false
        )
        let pusher = Pusher(key: "testKey123", options: options)
        let socket = MockWebSocket()
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        return (pusher, socket)
    }
    
    func testPrivateEncryptedChannelMessageDecrypted() {
        let (pusher, socket) = configurePusherWithAuthMethod()
        
        // connect to the channel
        let channel = subscribeToChannel(authData: validAuthData, pusher: pusher)
        
        // prepare a message
        let exp = expectation(description: "the channel should receive a message.")
        
        let dataPayload = """
        {
            "nonce": "4sVYwy4j/8dCcjyxtPCWyk19GaaViaW9",
            "ciphertext": "/GMESnFGlbNn01BuBjp31XYa3i9vZsGKR8fgR9EDhXKx3lzGiUD501A="
        }
        """
        
        // listen for messages to the eventName
        channel.bind(eventName: eventName, eventCallback: { (event: PusherEvent) in
            XCTAssertEqual(event.data, "{\"message\":\"hello world\"}");
            exp.fulfill()
        })
        
        // send the message
        socket.delegate?.didReceive(event: .text(createMessagePayload(dataPayload: dataPayload)),
                                    client: socket)
        
        // wait for message to be received
        waitForExpectations(timeout: 1)
    }
    
    func testShouldRetryAuth() {
        let (pusher, socket) = configurePusherWithAuthMethod()

        // connect with an incorrect shared secret
        let channel = subscribeToChannel(authData: incorrectSharedSecretAuthData, pusher: pusher)
        
        // next authorizer should return a valid shared secret
        mockAuthResponse(jsonData: validAuthData, pusher: pusher)
        
        // prepare a message
        let exp = expectation(description: "the channel should receive a message.")
        
        let dataPayload = """
        {
            "nonce": "4sVYwy4j/8dCcjyxtPCWyk19GaaViaW9",
            "ciphertext": "/GMESnFGlbNn01BuBjp31XYa3i9vZsGKR8fgR9EDhXKx3lzGiUD501A="
        }
        """
        
        // listen to messages on eventname
        channel.bind(eventName: eventName, eventCallback: { (event: PusherEvent) in
            XCTAssertEqual(event.data, "{\"message\":\"hello world\"}");
            exp.fulfill()
        })
        
        // send the message
        socket.delegate?.didReceive(event: .text(createMessagePayload(dataPayload: dataPayload)),
                                    client: socket)
        
        // wait for the message to be received
        waitForExpectations(timeout: 1)
    }
    
    func testIncorrectSharedSecretShouldNotifyFailedToDecrypt() {
        let (pusher, socket) = configurePusherWithAuthMethod()

        // connect with an incorrect shared secret
        let _ = subscribeToChannel(authData: incorrectSharedSecretAuthData, pusher: pusher)
        
        // prepare a message
        let dataPayload = """
        {
            "nonce": "4sVYwy4j/8dCcjyxtPCWyk19GaaViaW9",
            "ciphertext": "/GMESnFGlbNn01BuBjp31XYa3i9vZsGKR8fgR9EDhXKx3lzGiUD501A="
        }
        """
        
        // set up a delegate to listen for failedToDecryptEvent
        let errorDelegate = DummyErrorDelegate()
        errorDelegate.expectation = expectation(description: "the message should fail to decrypt")
        errorDelegate.channelName = channelName
        
        pusher.delegate = errorDelegate
        
        // send the message
        socket.delegate?.didReceive(event: .text(createMessagePayload(dataPayload: dataPayload)),
                                    client: socket)
        
        waitForExpectations(timeout: 1)
    }
    
    func testTwoEventsReceivedOnlySecondRetryIsCorrect() {
        let (pusher, socket) = configurePusherWithAuthMethod()

        // connect with an incorrect shared secret
        let channel = subscribeToChannel(authData: incorrectSharedSecretAuthData, pusher: pusher)
        
        // prepare a message
        let dataPayload = """
        {
            "nonce": "4sVYwy4j/8dCcjyxtPCWyk19GaaViaW9",
            "ciphertext": "/GMESnFGlbNn01BuBjp31XYa3i9vZsGKR8fgR9EDhXKx3lzGiUD501A="
        }
        """
        
        // set up a delegate to listen for failedToDecryptEvent
        let errorDelegate = DummyErrorDelegate()
        errorDelegate.expectation = expectation(description: "the message should fail to decrypt")
        errorDelegate.channelName = channelName
        
        pusher.delegate = errorDelegate
        
        // send the message
        socket.delegate?.didReceive(event: .text(createMessagePayload(dataPayload: dataPayload)),
                                    client: socket)
        
        waitForExpectations(timeout: 1)
        
        // ensure the next event has a valid shared secret
        mockAuthResponse(jsonData: validAuthData, pusher: pusher)
        
        let exp = expectation(description: "second event should be decrypted")
        
        // listen for the messages
        channel.bind(eventName: eventName, eventCallback: { (event: PusherEvent) in
            XCTAssertEqual(event.data, "{\"message\":\"hello world\"}");
            exp.fulfill()
        })
        
        // send the second message
        socket.delegate?.didReceive(event: .text(createMessagePayload(dataPayload: dataPayload)),
                                    client: socket)
        
        waitForExpectations(timeout: 1)
    }
    
    func testTwoEventsReceivedBothFailDecryption() {
        let (pusher, socket) = configurePusherWithAuthMethod()

        // connect with an incorrect shared secret
        let _ = subscribeToChannel(authData: incorrectSharedSecretAuthData, pusher: pusher)
        
        // prepare a message
        let dataPayload = """
        {
            "nonce": "4sVYwy4j/8dCcjyxtPCWyk19GaaViaW9",
            "ciphertext": "/GMESnFGlbNn01BuBjp31XYa3i9vZsGKR8fgR9EDhXKx3lzGiUD501A="
        }
        """
        
        // set up a delegate to listen for failedToDecryptEvent
        let errorDelegate = DummyErrorDelegate()
        errorDelegate.expectation = expectation(description: "the message should fail to decrypt")
        errorDelegate.channelName = channelName
        
        pusher.delegate = errorDelegate
        
        // send the message
        socket.delegate?.didReceive(event: .text(createMessagePayload(dataPayload: dataPayload)),
                                    client: socket)
        
        waitForExpectations(timeout: 1)
        
        // set a new expectation for the error delegate for the second event
        errorDelegate.expectation = expectation(description: "second event should fail to decrpyt too.")
        
        // send a second message
        socket.delegate?.didReceive(event: .text(createMessagePayload(dataPayload: dataPayload)),
                                    client: socket)
        
        waitForExpectations(timeout: 1)
    }

    func authorizerReponseSequence(_ authSequence: [PusherAuth]){
        let (pusher, socket) = configurePusherWithAuthMethod(authMethod: AuthMethod.authorizer(authorizer: TestAuthorizer(authSequence)))
        pusher.connect()

        let subscriptionExp = expectation(description: "should subscribe to channel")
        let channel = pusher.subscribe(channelName)
        channel.bind(eventName: "pusher:subscription_succeeded", eventCallback: { (event: PusherEvent) in
            subscriptionExp.fulfill()
        })
        waitForExpectations(timeout: 1)

        // prepare a message
        let exp = expectation(description: "the channel should receive a message.")

        let dataPayload = """
        {
            "nonce": "4sVYwy4j/8dCcjyxtPCWyk19GaaViaW9",
            "ciphertext": "/GMESnFGlbNn01BuBjp31XYa3i9vZsGKR8fgR9EDhXKx3lzGiUD501A="
        }
        """

        // listen for messages to the eventName
        channel.bind(eventName: eventName, eventCallback: { (event: PusherEvent) in
            XCTAssertEqual(event.data, "{\"message\":\"hello world\"}");
            exp.fulfill()
        })

        // send the message
        socket.delegate?.didReceive(event: .text(createMessagePayload(dataPayload: dataPayload)),
                                    client: socket)

        // wait for message to be received
        waitForExpectations(timeout: 1)
    }

    func testInitialLoadKeyAuthorizerAuthMethod(){
        authorizerReponseSequence([validAuth])
    }

    func testReloadKeyAuthorizerAuthMethod(){
        authorizerReponseSequence([incorrectSharedSecretAuth, validAuth])
    }

    func testInitialLoadKeyRequestBuilder(){
        let (pusher, socket) = configurePusherWithAuthMethod(authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: TestAuthRequestBuilder()))
        
        // connect with an incorrect shared secret
        let channel = subscribeToChannel(authData: validAuthData, pusher: pusher)

        // prepare a message
        let exp = expectation(description: "the channel should receive a message.")

        let dataPayload = """
        {
            "nonce": "4sVYwy4j/8dCcjyxtPCWyk19GaaViaW9",
            "ciphertext": "/GMESnFGlbNn01BuBjp31XYa3i9vZsGKR8fgR9EDhXKx3lzGiUD501A="
        }
        """

        // listen to messages on eventname
        channel.bind(eventName: eventName, eventCallback: { (event: PusherEvent) in
            XCTAssertEqual(event.data, "{\"message\":\"hello world\"}");
            exp.fulfill()
        })

        // send the message
        socket.delegate?.didReceive(event: .text(createMessagePayload(dataPayload: dataPayload)),
                                    client: socket)

        // wait for the message to be received
        waitForExpectations(timeout: 1)
    }

    func testReloadKeyRequestBuilder(){
        let (pusher, socket) = configurePusherWithAuthMethod(authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: TestAuthRequestBuilder()))

        // connect with an incorrect shared secret
        let channel = subscribeToChannel(authData: incorrectSharedSecretAuthData, pusher: pusher)

        // next authorizer should return a valid shared secret
        mockAuthResponse(jsonData: validAuthData, pusher: pusher)

        // prepare a message
        let exp = expectation(description: "the channel should receive a message.")

        let dataPayload = """
        {
            "nonce": "4sVYwy4j/8dCcjyxtPCWyk19GaaViaW9",
            "ciphertext": "/GMESnFGlbNn01BuBjp31XYa3i9vZsGKR8fgR9EDhXKx3lzGiUD501A="
        }
        """

        // listen to messages on eventname
        channel.bind(eventName: eventName, eventCallback: { (event: PusherEvent) in
            XCTAssertEqual(event.data, "{\"message\":\"hello world\"}");
            exp.fulfill()
        })

        // send the message
        socket.delegate?.didReceive(event: .text(createMessagePayload(dataPayload: dataPayload)),
                                    client: socket)

        // wait for the message to be received
        waitForExpectations(timeout: 1)
    }
    
    // utility method to ensure you're subscribed to a channel
    // option to pass authData to simulate a valid/invalid shared secret
    private func subscribeToChannel(authData: String, pusher: Pusher) -> PusherChannel {
        
        // set up a connection delegate with an expectation to be subscribed
        let dummyDelegate = DummySubscriptionDelegate()
        dummyDelegate.expectation =  expectation(description: "the channel should be subscribed to successfully")
        dummyDelegate.channelName = channelName
        pusher.delegate = dummyDelegate
        
        // send the provided auth data when the auth endpoint is hit
        mockAuthResponse(jsonData: authData, pusher: pusher)
        
        // assert we aren't connected before we connect
        let channel = pusher.subscribe(channelName)
        XCTAssertFalse(channel.subscribed, "the channel should not be subscribed...yet")
        
        // connect and wait for the expectation to be fulfilled
        pusher.connect()
        waitForExpectations(timeout: 0.5)
        
        return channel
    }
    
    // PusherDelegate that handles the expectation that a subscription event has occurred
    class DummySubscriptionDelegate: PusherDelegate {
        var expectation: XCTestExpectation? = nil
        var channelName: String? = nil
        
        func subscribedToChannel(name: String) {
            if name == channelName {
                // only fulfill if the channel connected is actually the channel we cared about
                expectation?.fulfill()
            }
        }
    }

    class TestAuthorizer: Authorizer {
        var authReponseSequence: [PusherAuth]
        public init(_ authReponseSequence: [PusherAuth]){
            self.authReponseSequence = authReponseSequence
        }
        func fetchAuthValue(socketID: String, channelName: String, completionHandler: @escaping (PusherAuth?) -> ()) {
            completionHandler(authReponseSequence.removeFirst())
        }
    }

    class TestAuthRequestBuilder: AuthRequestBuilderProtocol {
        func requestFor(socketID: String, channelName: String) -> URLRequest? {
            var request = URLRequest(url: URL(string: "http://localhost:3030")!)
            request.httpMethod = "POST"
            request.httpBody = "channel_name=\(channelName)&socket_id=\(socketID)".data(using: String.Encoding.utf8)
            return request
        }
    }
    
    class DummyErrorDelegate: PusherDelegate {
        var expectation: XCTestExpectation? = nil
        var channelName: String? = nil
        
        func failedToDecryptEvent(eventName: String, channelName: String, data: String?) {
            if channelName == self.channelName {
                expectation?.fulfill()
            }
        }
    }
    
    // utility method to mock an authorizor response with the jsonData provided
    func mockAuthResponse(jsonData: String, pusher: Pusher) {
        let urlResponse = HTTPURLResponse(
            url: URL(string: "\(authEndpointURL)?channel_name=\(channelName)&socket_id=45481.3166671")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil)
        MockSession.mockResponse = (data: jsonData.data(using: String.Encoding.utf8, allowLossyConversion: false)!,
                                    urlResponse: urlResponse,
                                    error: nil)
        pusher.connection.URLSession = MockSession.shared
    }
    
    // utility method to create a pusher message with the provided datapayload
    private func createMessagePayload(dataPayload: String) -> String {
        return """
        {
        "event": "\(eventName)",
        "channel": "\(channelName)",
        "data": \(dataPayload.removing(.whitespacesAndNewlines).escaped)
        }
        """
    }
}
