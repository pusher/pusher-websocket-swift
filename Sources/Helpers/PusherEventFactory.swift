import Foundation

protocol PusherEventFactory {

    func makeEvent(fromJSON json: PusherEventPayload, withDecryptionKey decryptionKey: String?) throws -> PusherEvent

}

// MARK: - Concrete implementation

struct PusherConcreteEventFactory: PusherEventFactory {

    // MARK: - Event factory

    func makeEvent(fromJSON json: PusherEventPayload,
                   withDecryptionKey decryptionKey: String? = nil) throws -> PusherEvent {
        guard let eventName = json[Constants.JSONKeys.event] as? String else {
            throw PusherEventError.invalidFormat
        }

        let channelName = json[Constants.JSONKeys.channel] as? String
        let data = try self.data(fromJSON: json,
                                 eventName: eventName,
                                 channelName: channelName, decryptionKey: decryptionKey)
        let userId = json[Constants.JSONKeys.userId] as? String

        return PusherEvent(eventName: eventName, channelName: channelName, data: data, userId: userId, raw: json)
    }

    // MARK: - Private methods

    private func data(fromJSON json: PusherEventPayload,
                      eventName: String,
                      channelName: String?,
                      decryptionKey: String?) throws -> String? {
        let data = json[Constants.JSONKeys.data] as? String

        if PusherEncryptionHelpers.shouldDecryptMessage(eventName: eventName, channelName: channelName) {
            return try PusherDecryptor.decrypt(data: data, decryptionKey: decryptionKey)
        } else {
            return data
        }
    }
}

// MARK: - Types

typealias PusherEventPayload = [String: Any]

// MARK: - Error handling

enum PusherEventError: Error {

    case invalidFormat
    case invalidDecryptionKey
    case invalidEncryptedData

}
