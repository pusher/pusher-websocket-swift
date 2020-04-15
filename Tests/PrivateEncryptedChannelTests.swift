import XCTest

#if WITH_ENCRYPTION
    @testable import PusherSwiftWithEncryption
#else
    @testable import PusherSwift
#endif

class PrivateEncryptedChannelTests: XCTestCase {
    
    var pusher: Pusher!
    var socket: MockWebSocket!
    
    private let channelName = "private-encrypted-channel"
    
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
    
    func testPrivateEncryptedChannelIsSubscribedTo() {
        
        let dummyDelegate = DummySubscriptionDelegate()
        dummyDelegate.expectation =  expectation(description: "the channel should be subscribed to successfully")
        dummyDelegate.channelName = channelName
        pusher.delegate = dummyDelegate
        
        if case .endpoint(authEndpoint: let authEndpoint) = pusher.connection.options.authMethod {
            let jsonData = "{\"auth\":\"testKey123:12345678gfder78ikjbg\"}".data(using: String.Encoding.utf8, allowLossyConversion: false)!
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
        
        let chan = pusher.subscribe(channelName)
        XCTAssertFalse(chan.subscribed, "the channel should not be subscribed...yet")
        pusher.connect()
        waitForExpectations(timeout: 0.5)
    }
    
    // onMessage -> message decrypted
    
    // onMessageRaisesExceptionWhenFailingToDecryptTwice
    
    // onMessageRetriesDecryptionOnce
    
    // twoEventsReceivedWithSecondRetryCorrect
    
    // twoEventsReceivedWithIncorrectSharedSecret
    
}
