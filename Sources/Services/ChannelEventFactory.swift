import Foundation

// MARK: - Types

typealias ChannelEventPayload = [String: Any]

struct ChannelEventFactory: EventFactory {

    // MARK: - Event factory

    func makeEvent(fromJSON json: ChannelEventPayload,
                   withDecryptionKey decryptionKey: String? = nil) throws -> PusherEvent {
        guard let eventName = json[Constants.JSONKeys.event] as? String else {
            throw EventError.invalidFormat
        }

        let channelName = json[Constants.JSONKeys.channel] as? String
        let data = try self.data(fromJSON: json,
                                 eventName: eventName,
                                 channelName: channelName, decryptionKey: decryptionKey)
        let userId = json[Constants.JSONKeys.userId] as? String

        return PusherEvent(eventName: eventName, channelName: channelName, data: data, userId: userId, raw: json)
    }

    // MARK: - Private methods

    private func data(fromJSON json: ChannelEventPayload,
                      eventName: String,
                      channelName: String?,
                      decryptionKey: String?) throws -> String? {
        let data = json[Constants.JSONKeys.data] as? String

        if PusherChannel.decryptsMessage(name: channelName, eventName: eventName) {
            return try Crypto.decrypt(data: data, decryptionKey: decryptionKey)
        } else {
            return data
        }
    }
}
