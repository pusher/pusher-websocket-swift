@testable import PusherSwiftWithEncryption
import XCTest

class PrivateEncryptedChannelTests: XCTestCase {
    
    var pusher: Pusher!
    var socket: MockWebSocket!
    
    private let channelName = "private-encrypted-channel"
    
    private let validAuthData = "{\"auth\":\"636a81ba7e7b15725c00:3ee04892514e8a669dc5d30267221f16727596688894712cad305986e6fc0f3c\",\"shared_secret\":\"iBvNoPVYwByqSfg6anjPpEQ2j051b3rt1Vmnb+z5doo=\"}"
    .data(using: String.Encoding.utf8, allowLossyConversion: false)!
    
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
    
    class DummySubscriptionDelegate: PusherDelegate {
        var expectation: XCTestExpectation? = nil
        var channelName: String? = nil
        
        func subscribedToChannel(name: String) {
            if name == channelName {
                expectation?.fulfill()
            }
        }
    }
    
    private func subscribeToChannel() -> PusherChannel {
        
        let dummyDelegate = DummySubscriptionDelegate()
        dummyDelegate.expectation =  expectation(description: "the channel should be subscribed to successfully")
        dummyDelegate.channelName = channelName
        pusher.delegate = dummyDelegate
        
        if case .endpoint(authEndpoint: let authEndpoint) = pusher.connection.options.authMethod {
            mockAuth(authEndpoint: authEndpoint,
                     jsonData: validAuthData)
        }
        
        let channel = pusher.subscribe(channelName)
        XCTAssertFalse(channel.subscribed, "the channel should not be subscribed...yet")
        pusher.connect()
        
        waitForExpectations(timeout: 0.5)
        
        return channel
    }
    
    
    func mockAuth(authEndpoint: String, jsonData: Data) {
        
        let urlResponse = HTTPURLResponse(
            url: URL(string: "\(authEndpoint)?channel_name=\(channelName)&socket_id=45481.3166671")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil)
        MockSession.mockResponse = (data: jsonData,
                                    urlResponse: urlResponse,
                                    error: nil)
        pusher.connection.URLSession = MockSession.shared
    }
    
    func testPrivateEncryptedChannelMessageDecrypted() {
    
        let channel = subscribeToChannel()
        
        // send a message
        let exp = expectation(description: "the channel should receive a message.")
        
        let dataPayload = """
        {
            "nonce": "4sVYwy4j/8dCcjyxtPCWyk19GaaViaW9",
            "ciphertext": "/GMESnFGlbNn01BuBjp31XYa3i9vZsGKR8fgR9EDhXKx3lzGiUD501A="
        }
        """.removing(.whitespacesAndNewlines)
        
        let message = """
        {
        "event": "my-event",
        "channel": "private-encrypted-channel",
        "data": \(dataPayload.escaped)
        }
        """
        
        channel.bind(eventName: "my-event", eventCallback: { (event: PusherEvent) in
            XCTAssertEqual(event.data, "{\"message\":\"hello world\"}");
            exp.fulfill()
        })
        
        socket.delegate?.websocketDidReceiveMessage(socket: socket, text: message)
        waitForExpectations(timeout: 1)
    }
    s
    
    // onMessageRaisesExceptionWhenFailingToDecryptTwice
    
    // onMessageRetriesDecryptionOnce
    
    // twoEventsReceivedWithSecondRetryCorrect
    
    // twoEventsReceivedWithIncorrectSharedSecret
    
}
