@testable import PusherSwiftWithEncryption
import XCTest

class PusherEventFactoryDecryptionTests: XCTestCase {

    var eventFactory: PusherConcreteEventFactory!

    override func setUp() {
        eventFactory = PusherConcreteEventFactory()
    }
    
    // MARK: Encryption related tests
    
    func test_init_unencryptedChannelAndUnencryptedPayload_returnsWithUnalteredPayload() {
        
        let dataPayload = """
        {
            "test": "test string",
            "and": "another"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()
        
        let event = try? eventFactory.makeEvent(fromJSON: jsonDict)
        
        XCTAssertNotNil(event) { event in
            XCTAssertEqual(event.eventName, "test-event")
            XCTAssertEqual(event.channelName, "my-channel")
            XCTAssertEqual(event.data, dataPayload)
        }
        
    }
    
    func test_init_unencryptedChannelAndEncryptedPayload_returnsWithUnalteredPayload() {
        
        let dataPayload = """
        {
            "nonce": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm",
            "ciphertext": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "test-event",
            "channel": "my-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()
        
        let event = try? eventFactory.makeEvent(fromJSON: jsonDict)
        
        XCTAssertNotNil(event) { event in
            XCTAssertEqual(event.eventName, "test-event")
            XCTAssertEqual(event.channelName, "my-channel")
            XCTAssertEqual(event.data, dataPayload)
        }
        
    }
    
    func test_init_encryptedChannelAndPusherEventAndUnencryptedPayload_returnsWithUnalteredPayload() {
        
        let dataPayload = """
        {
            "test": "test string",
            "and": "another"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "pusher:event",
            "channel": "private-encrypted-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()
        
        let event = try? eventFactory.makeEvent(fromJSON: jsonDict)
        
        XCTAssertNotNil(event) { event in
            XCTAssertEqual(event.eventName, "pusher:event")
            XCTAssertEqual(event.channelName, "private-encrypted-channel")
            XCTAssertEqual(event.data, dataPayload)
        }
    }
    
    
    func test_init_encryptedChannelAndPusherEventAndEncryptedPayload_returnsWithUnalteredPayload() {
        
        let dataPayload = """
        {
            "nonce": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm",
            "ciphertext": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "pusher:event",
            "channel": "private-encrypted-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()
        
       let event = try? eventFactory.makeEvent(fromJSON: jsonDict)
        
        XCTAssertNotNil(event) { event in
            XCTAssertEqual(event.eventName, "pusher:event")
            XCTAssertEqual(event.channelName, "private-encrypted-channel")
            XCTAssertEqual(event.data, dataPayload)
        }
    }
    
    func test_init_encryptedChannelAndUserEventAndUnencryptedPayloadWithNoDecryptionKey_throwsInvalidFormat() {
        
        let dataPayload = """
        {
            "test": "test string",
            "and": "another"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "user-event",
            "channel": "private-encrypted-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()

        XCTAssertThrowsError(try eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: nil)) { (error) in
            XCTAssertEqual(error as? PusherEventError, PusherEventError.invalidDecryptionKey)
        }
    }

    func test_init_encryptedChannelAndUserEventAndUnencryptedPayloadWithDecryptionKey_throwsInvalidFormat() {
        let decryptionKey = "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs="

        let dataPayload = """
        {
            "test": "test string",
            "and": "another"
        }
        """.removing(.whitespacesAndNewlines)

        let jsonDict = """
        {
            "event": "user-event",
            "channel": "private-encrypted-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()

        XCTAssertThrowsError(try eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: decryptionKey)) { (error) in
            XCTAssertEqual(error as? PusherEventError, PusherEventError.invalidFormat)
        }
    }
    
    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadAndValidKey_returnsWithDecryptedPayload() {
        
        let decryptionKey = "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs="
        
        let dataPayload = """
        {
            "nonce": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm",
            "ciphertext": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "user-event",
            "channel": "private-encrypted-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()
        
        let event = try? eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: decryptionKey)
        
        let expectedDecryptedPayload = """
        {
            "name": "freddy",
            "message": "hello"
        }
        """.removing(.whitespacesAndNewlines)
        
        XCTAssertNotNil(event) { event in
            XCTAssertEqual(event.eventName, "user-event")
            XCTAssertEqual(event.channelName, "private-encrypted-channel")
            XCTAssertEqual(event.data, expectedDecryptedPayload)
        }
    }
    
    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadButBadKey_throwsInvalidDecryptionKey() {
        
        let decryptionKey = "00000000000000000000000000000000000000000000"
        
        let dataPayload = """
        {
            "nonce": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm",
            "ciphertext": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "user-event",
            "channel": "private-encrypted-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()


        XCTAssertThrowsError(try eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: decryptionKey)) { (error) in
            XCTAssertEqual(error as? PusherEventError, PusherEventError.invalidDecryptionKey)
        }
    }
    
    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadButBadNonce_throwsInvalidDecryptionKey() {
        
        let decryptionKey = "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs="
        
        let dataPayload = """
        {
            "nonce": "00000000000000000000000000000000",
            "ciphertext": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "user-event",
            "channel": "private-encrypted-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()

        XCTAssertThrowsError(try eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: decryptionKey)) { (error) in
            XCTAssertEqual(error as? PusherEventError, PusherEventError.invalidDecryptionKey)
        }
    }
    
    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadButBadCiphertext_throwsInvalidDecryptionKey() {
        
        let decryptionKey = "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs="
        
        let dataPayload = """
        {
            "nonce": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm",
            "ciphertext": "00000000000000000000000000000000000000000000000000000000000000000000"
        }
        """.removing(.whitespacesAndNewlines)
        
        let jsonDict = """
        {
            "event": "user-event",
            "channel": "private-encrypted-channel",
            "data": \(dataPayload.escaped)
        }
        """.toJsonDict()

        XCTAssertThrowsError(try eventFactory.makeEvent(fromJSON: jsonDict, withDecryptionKey: decryptionKey)) { (error) in
            XCTAssertEqual(error as? PusherEventError, PusherEventError.invalidDecryptionKey)
        }
    }
}
