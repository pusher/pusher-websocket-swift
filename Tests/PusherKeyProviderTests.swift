import XCTest

#if WITH_ENCRYPTION
    @testable import PusherSwiftWithEncryption
#else
    @testable import PusherSwift
#endif

class PusherKeyProviderTests: XCTestCase {

    var keyProvider: PusherKeyProvider!

    override func setUp() {
        keyProvider = PusherConcreteKeyProvider()
    }

    func testSettingAndRetrievingKey() {
        let decryptionKey = "abcde12345"
        let channelName = "my-channel"
        keyProvider.setDecryptionKey(decryptionKey, forChannelName: channelName)

        let returnedKey = keyProvider.decryptionKey(forChannelName: channelName)

        XCTAssertEqual(returnedKey, decryptionKey)
    }

    func testUpdatingKey() {
        let decryptionKey1 = "abcde12345"
        let decryptionKey2 = "fghijkl12345"
        let channelName = "my-channel"

        keyProvider.setDecryptionKey(decryptionKey1, forChannelName: channelName)
        let returnedKey1 = keyProvider.decryptionKey(forChannelName: channelName)
        XCTAssertEqual(returnedKey1, decryptionKey1)

        keyProvider.setDecryptionKey(decryptionKey2, forChannelName: channelName)
        let returnedKey2 = keyProvider.decryptionKey(forChannelName: channelName)
        XCTAssertEqual(returnedKey2, decryptionKey2)
    }

    func testClearingKey() {
        let decryptionKey = "abcde12345"
        let channelName = "my-channel"

        keyProvider.setDecryptionKey(decryptionKey, forChannelName: channelName)
        let returnedKey1 = keyProvider.decryptionKey(forChannelName: channelName)
        XCTAssertEqual(returnedKey1, decryptionKey)

        keyProvider.clearDecryptionKey(forChannelName: channelName)
        let returnedKey2 = keyProvider.decryptionKey(forChannelName: channelName)
        XCTAssertNil(returnedKey2)
    }

}
