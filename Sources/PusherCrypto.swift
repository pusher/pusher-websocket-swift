import Foundation
import CommonCrypto

struct PusherCrypto {

    /**
        Generates a SHA256 HMAC digest of the message using the secret

        - returns: The hex encoded MAC string
    */
     static func generateSHA256HMAC(secret: String, message: String) -> String {
        guard let secret = secret.cString(using: .utf8), let message = message.cString(using: .utf8) else {
            return ""
        }

        let algorithm = CCHmacAlgorithm(kCCHmacAlgSHA256)
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: digestLength)

        CCHmac(algorithm, secret, secret.count - 1, message, message.count - 1, &digest)

        // Data to hex string
        let signature = digest
            .map { String(format: "%02x", $0) }
            .joined()

        return signature
    }
}
