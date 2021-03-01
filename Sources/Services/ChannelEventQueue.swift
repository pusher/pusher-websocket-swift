import Foundation

class ChannelEventQueue: EventQueue {

    // MARK: - Properties

    private let eventFactory: EventFactory
    private let channels: PusherChannels
    private var queue = DispatchQueue(label: "com.pusher.pusherswift-event-queue-\(UUID().uuidString)")

    weak var delegate: EventQueueDelegate?

    // MARK: - Initializers

    init(eventFactory: EventFactory, channels: PusherChannels) {
        self.eventFactory = eventFactory
        self.channels = channels
    }

    // MARK: - Event queue
    public func enqueue(json: ChannelEventPayload) {
        var channel: PusherChannel?

        // If this event is for a particular channel, find the channel
        if let channelName = json[Constants.JSONKeys.channel] as? String {
            channel = channels.find(name: channelName)
            if channel == nil {
                // If we can't find the channel then we have unsubscribed, drop the event
                return
            }
        }

        queue.async {
            self.processEventWithRetries(json: json, channel: channel)
        }
    }

    // MARK: - Private methods

    private func processEventWithRetries(json: ChannelEventPayload, channel: PusherChannel?) {
        do {
            try self.processEvent(json: json, channel: channel)
        } catch EventError.invalidDecryptionKey {
            // Reload decryption key if we could not decrypt the payload due to the key
            // Only events on encrypted channels throw this error, which have a channel
            guard let channel = channel else {
                return
            }

            self.delegate?.eventQueue(self, reloadDecryptionKeySyncForChannel: channel)
            do {
                try self.processEvent(json: json, channel: channel)
            } catch {
                self.delegate?.eventQueue(self,
                                          didFailToDecryptEventWithPayload: json,
                                          forChannelName: channel.name)
            }
        } catch EventError.invalidEncryptedData {
            // If there was a problem with the payload, e.g. nonce missing, then we cannot retry
            guard let channelName = channel?.name else {
                return
            }

            self.delegate?.eventQueue(self, didFailToDecryptEventWithPayload: json, forChannelName: channelName)
        } catch {
            self.delegate?.eventQueue(self, didReceiveInvalidEventWithPayload: json)
        }
    }

    private func processEvent(json: ChannelEventPayload, channel: PusherChannel? = nil) throws {
        let event = try self.eventFactory.makeEvent(fromJSON: json, withDecryptionKey: channel?.decryptionKey)
        self.delegate?.eventQueue(self, didReceiveEvent: event, forChannelName: channel?.name)
    }
}
