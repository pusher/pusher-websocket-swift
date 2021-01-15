import Foundation
import CommonCrypto

struct PusherCrypto {

    /**
        Generates a SHA256 HMAC digest of the message using the secret

        - returns: The hex encoded MAC string
    */
     static func generateSHA256HMAC(secret: String, message: String) -> String {
        let secretData = Data(secret.utf8)
        let messageData = Data(message.utf8)

        let algorithm = CCHmacAlgorithm(kCCHmacAlgSHA256)
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)

        var digest = Data(count: digestLength)

        digest.withUnsafeMutableBytes { (digestBytes: UnsafeMutableRawBufferPointer) in
            secretData.withUnsafeBytes { (secretBytes: UnsafeRawBufferPointer) in
                messageData.withUnsafeBytes { (messageBytes: UnsafeRawBufferPointer) in
                    CCHmac(algorithm,
                           secretBytes.baseAddress,
                           secretData.count,
                           messageBytes.baseAddress,
                           messageData.count,
                           digestBytes.baseAddress)
                }
            }
        }

        // Data to hex string
        let signature = digest
            .map { String(format: "%02x", $0) }
            .joined()

        return signature
    }
}
