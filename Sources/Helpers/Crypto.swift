import CryptoKit
import Foundation
import TweetNacl

struct Crypto {

    private struct EncryptedData: Decodable {
        let nonce: String
        let ciphertext: String
    }

    // MARK: - Public methods

    /// Generates a SHA256 HMAC digest of the message using the secret.
    /// - Parameters:
    ///   - secret: The secret key.
    ///   - message: The message.
    /// - Returns: The hex-encoded MAC string.
    static func generateSHA256HMAC(secret: String, message: String) -> String {
        let key = SymmetricKey(data: Data(secret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: key)

        return signature
            .map { String(format: "%02hhx", $0) }
            .joined()
    }

    /// Decrypts some data `String` using a key, according to the NaCl secret box algorithm.
    /// - Parameters:
    ///   - data: A JSON-encoded `String` of base64-encoded nonce and cypher text strings.
    ///   - decryptionKey: A base64-encoded decryption key `String`.
    /// - Throws: An `EventError` if the decryption operation fails for some reason.
    /// - Returns: The decrypted data `String`.
    static func decrypt(data: String?, decryptionKey: String?) throws -> String? {
        guard let data = data else {
            return nil
        }

        guard let decryptionKey = decryptionKey else {
            throw EventError.invalidDecryptionKey
        }

        let encryptedData = try self.encryptedData(fromData: data)
        let cipherText = try self.decodedCipherText(fromEncryptedData: encryptedData)
        let nonce = try self.decodedNonce(fromEncryptedData: encryptedData)
        let secretKey = try self.decodedDecryptionKey(fromDecryptionKey: decryptionKey)

        guard let decryptedData = try? NaclSecretBox.open(box: cipherText,
                                                          nonce: nonce,
                                                          key: secretKey),
              let decryptedString = String(bytes: decryptedData, encoding: .utf8) else {
            throw EventError.invalidDecryptionKey
        }

        return decryptedString
    }

    // MARK: - Private methods

    private static func encryptedData(fromData data: String) throws -> EncryptedData {
        guard let encodedData = data.data(using: .utf8),
              let encryptedData = try? JSONDecoder().decode(EncryptedData.self, from: encodedData) else {
            throw EventError.invalidEncryptedData
        }

        return encryptedData
    }

    private static func decodedCipherText(fromEncryptedData encryptedData: EncryptedData) throws -> Data {
        guard let decodedCipherText = Data(base64Encoded: encryptedData.ciphertext) else {
            throw EventError.invalidEncryptedData
        }

        return decodedCipherText
    }

    private static func decodedNonce(fromEncryptedData encryptedData: EncryptedData) throws -> Data {
        guard let decodedNonce = Data(base64Encoded: encryptedData.nonce) else {
            throw EventError.invalidEncryptedData
        }

        return decodedNonce
    }

    private static func decodedDecryptionKey(fromDecryptionKey decryptionKey: String) throws -> Data {
        guard let decodedDecryptionKey = Data(base64Encoded: decryptionKey) else {
            throw EventError.invalidDecryptionKey
        }

        return decodedDecryptionKey
    }
}
