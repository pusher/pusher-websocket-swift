import Foundation

enum EventError: Error {

    case invalidFormat
    case invalidDecryptionKey
    case invalidEncryptedData
}
