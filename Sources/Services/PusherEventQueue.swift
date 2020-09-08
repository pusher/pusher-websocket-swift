import Foundation

protocol PusherEventQueue {

    var delegate: PusherEventQueueDelegate? { get set }

    func enqueue(json: PusherEventPayload)

}

// MARK: - Concrete implementation

class PusherConcreteEventQueue: PusherEventQueue {

    // MARK: - Properties

    private let eventFactory: PusherEventFactory
    private let channels: PusherChannels
    private var queue = DispatchQueue(label: "com.pusher.pusherswift-event-queue-\(UUID().uuidString)")

    weak var delegate: PusherEventQueueDelegate?

    // MARK: - Initializers

    init(eventFactory: PusherEventFactory, channels: PusherChannels) {
        self.eventFactory = eventFactory
        self.channels = channels
    }

    // MARK: - Event queue
    public func enqueue(json: PusherEventPayload) {
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

    private func processEventWithRetries(json: PusherEventPayload, channel: PusherChannel?) {
        do {
            try self.processEvent(json: json, channel: channel)
        } catch PusherEventError.invalidDecryptionKey {
            // Reload decryption key if we could not decrypt the payload due to the key
            // Only events on encrypted channels throw this error, which have a channel
            if let channel = channel {
                self.delegate?.eventQueue(self, reloadDecryptionKeySyncForChannel: channel)
                do {
                    try self.processEvent(json: json, channel: channel)
                } catch {
                    self.delegate?.eventQueue(self,
                                              didFailToDecryptEventWithPayload: json,
                                              forChannelName: channel.name)
                }
            }
        } catch PusherEventError.invalidEncryptedData {
            // If there was a problem with the payload, e.g. nonce missing, then we cannot retry
            if let channelName = channel?.name {
                self.delegate?.eventQueue(self, didFailToDecryptEventWithPayload: json, forChannelName: channelName)
            }
        } catch {
            self.delegate?.eventQueue(self, didReceiveInvalidEventWithPayload: json)
        }
    }

    private func processEvent(json: PusherEventPayload, channel: PusherChannel? = nil) throws {
        let event = try self.eventFactory.makeEvent(fromJSON: json, withDecryptionKey: channel?.decryptionKey)
        self.delegate?.eventQueue(self, didReceiveEvent: event, forChannelName: channel?.name)
    }
}

// MARK: - Delegate

protocol PusherEventQueueDelegate: AnyObject {

    func eventQueue(_ eventQueue: PusherEventQueue,
                    didReceiveEvent event: PusherEvent,
                    forChannelName channelName: String?)
    func eventQueue(_ eventQueue: PusherEventQueue,
                    didFailToDecryptEventWithPayload payload: PusherEventPayload,
                    forChannelName channelName: String)
    func eventQueue(_ eventQueue: PusherEventQueue,
                    didReceiveInvalidEventWithPayload payload: PusherEventPayload)
    func eventQueue(_ eventQueue: PusherEventQueue,
                    reloadDecryptionKeySyncForChannel channel: PusherChannel)

}
