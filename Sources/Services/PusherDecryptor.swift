import Foundation
import TweetNacl

class PusherDecryptor {

    private struct EncryptedData: Decodable {
        let nonce: String
        let ciphertext: String

    }

    static func decrypt(data: String?, decryptionKey: String?) throws -> String? {
        guard let data = data else {
            return nil
        }

        guard let decryptionKey = decryptionKey else {
            throw PusherEventError.invalidDecryptionKey
        }

        let encryptedData = try self.encryptedData(fromData: data)
        let cipherText = try self.decodedCipherText(fromEncryptedData: encryptedData)
        let nonce = try self.decodedNonce(fromEncryptedData: encryptedData)
        let secretKey = try self.decodedDecryptionKey(fromDecryptionKey: decryptionKey)

        guard let decryptedData = try? NaclSecretBox.open(box: cipherText,
                                                          nonce: nonce,
                                                          key: secretKey),
            let decryptedString = String(bytes: decryptedData, encoding: .utf8) else {
                throw PusherEventError.invalidDecryptionKey
        }

        return decryptedString
    }

    private static func encryptedData(fromData data: String) throws -> EncryptedData {
        guard let encodedData = data.data(using: .utf8),
            let encryptedData = try? JSONDecoder().decode(EncryptedData.self, from: encodedData) else {
                throw PusherEventError.invalidEncryptedData
        }

        return encryptedData
    }

    private static func decodedCipherText(fromEncryptedData encryptedData: EncryptedData) throws -> Data {
        guard let decodedCipherText = Data(base64Encoded: encryptedData.ciphertext) else {
            throw PusherEventError.invalidEncryptedData
        }

        return decodedCipherText
    }

    private static func decodedNonce(fromEncryptedData encryptedData: EncryptedData) throws -> Data {
        guard let decodedNonce = Data(base64Encoded: encryptedData.nonce) else {
            throw PusherEventError.invalidEncryptedData
        }

        return decodedNonce
    }

    private static func decodedDecryptionKey(fromDecryptionKey decryptionKey: String) throws -> Data {
        guard let decodedDecryptionKey = Data(base64Encoded: decryptionKey) else {
            throw PusherEventError.invalidDecryptionKey
        }

        return decodedDecryptionKey
    }
}
