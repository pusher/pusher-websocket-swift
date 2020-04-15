import XCTest

#if WITH_ENCRYPTION
    @testable import PusherSwiftWithEncryption
#else
    @testable import PusherSwift
#endif

class PrivateEncryptedChannelTests: XCTestCase {
    
    var pusher: Pusher!
    var socket: MockWebSocket!
    var options: PusherClientOptions!
    var stubber: StubberForMocks!
    
    override func setUp() {
        super.setUp()
        
        options = PusherClientOptions(
            authMethod: .inline(secret: "secret"),
            autoReconnect: false
        )
        pusher = Pusher(key: "key", options: options)
        socket = MockWebSocket()
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
        stubber = StubberForMocks()
    }
    
    func testPrivateEncryptedChannelInitialises() {
        pusher.connection.userDataFetcher = { () -> PusherPresenceChannelMember in
            return PusherPresenceChannelMember(userId: "123")
        }

        pusher.connect()
        let chan = pusher.subscribe("private-encrypted-channel") as? PusherPr
        
        chan.
        pusher.connect()
        
    }
    
    // onMessage -> message decrypted
    
    // onMessageRaisesExceptionWhenFailingToDecryptTwice
    
    // onMessageRetriesDecryptionOnce
    
    // twoEventsReceivedWithSecondRetryCorrect
    
    // twoEventsReceivedWithIncorrectSharedSecret
    
}
