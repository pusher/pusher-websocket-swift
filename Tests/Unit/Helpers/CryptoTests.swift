import XCTest

@testable import PusherSwift

class CryptoTests: XCTestCase {

    private let testMessage = "{\"user\":\"my user data\"}"
    private let testSecret = "mysecret"

    func testHMACGeneratorGeneratesCorrectMAC() {
        let digest = Crypto.generateSHA256HMAC(secret: testSecret, message: testMessage)

        let expectedDigest = "7705bb9a7934fe4ceee2325e23750f35752899448c2fe5b064d93326c98fd5b3"
        XCTAssertEqual(digest, expectedDigest)
    }

    func testHMACGeneratorEmptySecret() {
        let digest = Crypto.generateSHA256HMAC(secret: "", message: testMessage)

        let expectedDigest = "a31926f3c0e20c8fd6174ac08c0057708590b6a6bb081a04560ea60b4500738a"
        XCTAssertEqual(digest, expectedDigest)
    }

    func testHMACGeneratorEmptyMessage() {
        let digest = Crypto.generateSHA256HMAC(secret: testSecret, message: "")

        let expectedDigest = "9074a74de0f34ece3f046403ae88d2eea400281da0ed6ebfa76c949016fa672d"
        XCTAssertEqual(digest, expectedDigest)
    }
}
