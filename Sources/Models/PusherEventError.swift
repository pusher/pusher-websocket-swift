import Foundation

enum PusherEventError: Error {

    case invalidFormat
    case invalidDecryptionKey
    case invalidEncryptedData
}
