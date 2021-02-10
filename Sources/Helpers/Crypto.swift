import CommonCrypto
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

    /// Determines whether or not a message should be decrypted, based on event and channel attributes.
    /// - Parameters:
    ///   - eventName: The name of the event.
    ///   - channelName: The name of the channel associated with the event.
    /// - Returns: A `Bool` indicating whether the message should be decrypted or not.
    public static func shouldDecryptMessage(eventName: String, channelName: String?) -> Bool {
        return isEncryptedChannel(channelName: channelName) && !isPusherSystemEvent(eventName: eventName)
    }

    /// Determines if a data sent over a channel are encrypted or not.
    /// - Parameter channelName: The name of the channel.
    /// - Returns: A `Bool` indicating whether the channel is encrypted or not.
    public static func isEncryptedChannel(channelName: String?) -> Bool {
        return channelName?.starts(with: "\(Constants.ChannelTypes.privateEncrypted)-") ?? false
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

    private static func isPusherSystemEvent(eventName: String) -> Bool {
        return eventName.starts(with: "\(Constants.EventTypes.pusher):")
            || eventName.starts(with: "\(Constants.EventTypes.pusherInternal):")
    }
}
