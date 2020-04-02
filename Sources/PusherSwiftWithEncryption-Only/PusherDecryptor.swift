import Sodium

class PusherDecryptor {
    
    private struct EncryptedData: Decodable {
        var nonce: String
        var ciphertext: String
    }
    
    private static let sodium = Sodium()
    
    static func decrypt(data dataAsString: String?, keyProvider: PusherKeyProviding?) -> String? {
        
        guard
            let dataAsString = dataAsString,
            let keyProvider = keyProvider,
            let dataAsData = dataAsString.data(using: .utf8),
            let encryptedData = try? JSONDecoder().decode(EncryptedData.self, from: dataAsData),
            let cipherText = Data(base64Encoded: encryptedData.ciphertext),
            let secretKey = Data(base64Encoded: keyProvider.decryptionKey),
            let nonce = Data(base64Encoded: encryptedData.nonce),
            let decryptedData = sodium.secretBox.open(authenticatedCipherText: Bytes(cipherText), secretKey: Bytes(secretKey), nonce: Bytes(nonce)),
            let decryptedString = String(bytes: decryptedData, encoding: .utf8) else {
                return nil
        }
    
        return decryptedString
    }
    
}
