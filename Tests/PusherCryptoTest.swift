@testable
import PusherSwift
import XCTest

class PusherCryptoTest: XCTestCase {
    func testHMACGeneratorGeneratesCorrectMAC() {
        let secret = "mysecret"
        let message = "{\"user\":\"my user data\"}"

        let digest = PusherCrypto.generateSHA256HMAC(secret: secret, message: message)

        let expectedDigest = "7705bb9a7934fe4ceee2325e23750f35752899448c2fe5b064d93326c98fd5b3"
        XCTAssertEqual(digest, expectedDigest)
    }
}
