@testable import PusherSwiftWithEncryption
import XCTest

class PrivateEncryptedChannelTests: XCTestCase {
    
    var pusher: Pusher!
    var socket: MockWebSocket!
    
    private let channelName = "private-encrypted-channel"
    private let eventName = "my-event"
    
    private let validAuthData = "{\"auth\":\"636a81ba7e7b15725c00:3ee04892514e8a669dc5d30267221f16727596688894712cad305986e6fc0f3c\",\"shared_secret\":\"iBvNoPVYwByqSfg6anjPpEQ2j051b3rt1Vmnb+z5doo=\"}"
    
    private let incorrectSharedSecretAuthData = "{\"auth\":\"636a81ba7e7b15725c00:3ee04892514e8a669dc5d30267221f16727596688894712cad305986e6fc0f3c\",\"shared_secret\":\"iBvNoPVYwByqSfg6anjPpEQ2j051b3rt1Vmnb+z5do0=\"}"
    
    override func setUp() {
        super.setUp()
        
        let options = PusherClientOptions(
            authMethod: AuthMethod.endpoint(authEndpoint: "http://localhost:3030"),
            autoReconnect: false
        )
        pusher = Pusher(key: "testKey123", options: options)
        socket = MockWebSocket()
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
    }
    
    func testPrivateEncryptedChannelMessageDecrypted() {
        
        // connect to the channel
        let channel = subscribeToChannel(authData: validAuthData)
        
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
        socket.delegate?.websocketDidReceiveMessage(
            socket: socket, text: createMessagePayload(dataPayload: dataPayload))
        
        // wait for message to be received
        waitForExpectations(timeout: 1)
    }
    
    func testShouldRetryAuth() {
        
        // connect with an incorrect shared secret
        let channel = subscribeToChannel(authData: incorrectSharedSecretAuthData)
        
        // next authorizer should return a valid shared secret
        mockAuthResponse(jsonData: validAuthData)
        
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
        socket.delegate?.websocketDidReceiveMessage(
            socket: socket, text: createMessagePayload(dataPayload: dataPayload))
        
        // wait for the message to be received
        waitForExpectations(timeout: 1)
    }
    
    //  test incorrect shared secret should raise some sort of notice
    
    // twoEventsReceivedWithSecondRetryCorrect
    
    // twoEventsReceivedWithIncorrectSharedSecret
    
    // utility method to ensure you're subscribed to a channel
    // option to pass authData to simulate a valid/invalid shared secret
    private func subscribeToChannel(authData: String) -> PusherChannel {
        
        // set up a connection delegate with an expectation to be subscribed
        let dummyDelegate = DummySubscriptionDelegate()
        dummyDelegate.expectation =  expectation(description: "the channel should be subscribed to successfully")
        dummyDelegate.channelName = channelName
        pusher.delegate = dummyDelegate
        
        // send the provided auth data when the auth endpoint is hit
        mockAuthResponse(jsonData: authData)
        
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
    
    // utility method to mock an authorizor response with the jsonData provided
    func mockAuthResponse(jsonData: String) {
        if case .endpoint(authEndpoint: let authEndpoint) = pusher.connection.options.authMethod {
            let urlResponse = HTTPURLResponse(
                url: URL(string: "\(authEndpoint)?channel_name=\(channelName)&socket_id=45481.3166671")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil)
            MockSession.mockResponse = (data: jsosnData.data(using: String.Encoding.utf8, allowLossyConversion: false)!,
                                        urlResponse: urlResponse,
                                        error: nil)
            pusher.connection.URLSession = MockSession.shared
        }
        
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
