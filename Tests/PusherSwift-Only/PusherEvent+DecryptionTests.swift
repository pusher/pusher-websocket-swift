@testable import PusherSwift
import XCTest

class PusherEventDecryptionTests: XCTestCase {

    let eventFactory = PusherConcreteEventFactory()
    
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

        let sut = try? eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "test-event")
            XCTAssertEqual(sut.channelName, "my-channel")
            XCTAssertEqual(sut.data, dataPayload)
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
        
        let sut = try? eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "test-event")
            XCTAssertEqual(sut.channelName, "my-channel")
            XCTAssertEqual(sut.data, dataPayload)
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
        
        let sut = try? eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "pusher:event")
            XCTAssertEqual(sut.channelName, "private-encrypted-channel")
            XCTAssertEqual(sut.data, dataPayload)
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
        
        let sut = try? eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "pusher:event")
            XCTAssertEqual(sut.channelName, "private-encrypted-channel")
            XCTAssertEqual(sut.data, dataPayload)
        }
    }
    
    func test_init_encryptedChannelAndUserEventAndUnencryptedPayload_returnsWithUnalteredPayload() {
        
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
        
        let sut = try? eventFactory.makeEvent(fromJSON: jsonDict)

        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "user-event")
            XCTAssertEqual(sut.channelName, "private-encrypted-channel")
            XCTAssertEqual(sut.data, dataPayload)
        }
    }

    /*
    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadAndValidKey_returnsWithUnalteredPayload() {
        
        let keyProvider = PusherKeyProvider(decryptionKey: "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs=")
        
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
        
        let sut = PusherEvent(jsonObject: jsonDict, keyProvider: keyProvider)
        
        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "user-event")
            XCTAssertEqual(sut.channelName, "private-encrypted-channel")
            XCTAssertEqual(sut.data, dataPayload)
        }
    }
    
    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadButBadKey_returnsWithUnalteredPayload() {
        
        let keyProvider = PusherKeyProvider(decryptionKey: "00000000000000000000000000000000000000000000")
        
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
        
        let sut = PusherEvent(jsonObject: jsonDict, keyProvider: keyProvider)
        
        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "user-event")
            XCTAssertEqual(sut.channelName, "private-encrypted-channel")
            XCTAssertEqual(sut.data, dataPayload)
        }
    }
    
    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadButBadNonce_returnsWithUnalteredPayload() {
        
        let keyProvider = PusherKeyProvider(decryptionKey: "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs=")
        
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
        
        let sut = PusherEvent(jsonObject: jsonDict, keyProvider: keyProvider)
        
        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "user-event")
            XCTAssertEqual(sut.channelName, "private-encrypted-channel")
            XCTAssertEqual(sut.data, dataPayload)
        }
    }
    
    func test_init_encryptedChannelAndUserEventAndEncryptedPayloadButBadCiphertext_returnsWithUnalteredPayload() {
        
        let keyProvider = PusherKeyProvider(decryptionKey: "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs=")
        
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
        
        let sut = PusherEvent(jsonObject: jsonDict, keyProvider: keyProvider)
        
        XCTAssertNotNil(sut) { sut in
            XCTAssertEqual(sut.eventName, "user-event")
            XCTAssertEqual(sut.channelName, "private-encrypted-channel")
            XCTAssertEqual(sut.data, dataPayload)
        }
    }

 */
    
}
