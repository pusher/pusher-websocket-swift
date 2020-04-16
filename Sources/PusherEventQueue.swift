import Foundation

protocol PusherEventQueue {
    
    var delegate: PusherEventQueueDelegate? { get set }

    func enqueue(json: PusherEventPayload)
    
}

// MARK: - Concrete implementation

class PusherConcreteEventQueue: PusherEventQueue {
    
    // MARK: - Properties
    
    private let eventFactory: PusherEventFactory
    private let keyProvider: PusherKeyProvider
    private var queue = DispatchQueue(label: "com.pusher.pusherswift-event-queue-\(UUID().uuidString)")
    
    weak var delegate: PusherEventQueueDelegate?
    
    // MARK: - Initializers
    
    init(eventFactory: PusherEventFactory, keyProvider: PusherKeyProvider) {
        self.eventFactory = eventFactory
        self.keyProvider = keyProvider
    }
    
    // MARK: - Event queue

    public func enqueue(json: PusherEventPayload) {
        queue.async {
            let channelName = json["channel"] as? String
            do {
                try self.processEvent(json: json, forChannelName: channelName)
            } catch PusherEventError.invalidDecryptionKey {
                // Only events on encrypted channels throw this error, which have a channel name
                if let channelName = channelName {
                    self.delegate?.eventQueue(self, reloadDecryptionKeySyncForChannelName: channelName)
                    do {
                        try self.processEvent(json: json, forChannelName: channelName)
                    }catch {
                        self.delegate?.eventQueue(self, didFailToDecryptEventWithPayload: json, forChannelName: channelName)
                    }
                }
            } catch {
                self.delegate?.eventQueue(self, didReceiveInvalidEventWithPayload: json)
            }
        }
    }

    // MARK: - Private methods

    private func processEvent(json: PusherEventPayload, forChannelName channelName: String? = nil) throws {
        var decryptionKey: String? = nil
        if let channelName = channelName {
            decryptionKey = self.keyProvider.decryptionKey(forChannelName: channelName)
        }
        let event = try self.eventFactory.makeEvent(fromJSON: json, withDecryptionKey: decryptionKey)
        self.delegate?.eventQueue(self, didReceiveEvent: event, forChannelName: channelName)
    }
}

// MARK: - Delegate

protocol PusherEventQueueDelegate: AnyObject {
    
    func eventQueue(_ eventQueue: PusherEventQueue, didReceiveEvent event: PusherEvent, forChannelName channelName: String?)
    func eventQueue(_ eventQueue: PusherEventQueue, didFailToDecryptEventWithPayload payload: PusherEventPayload, forChannelName channelName: String)
    func eventQueue(_ eventQueue: PusherEventQueue, didReceiveInvalidEventWithPayload payload: PusherEventPayload)
    func eventQueue(_ eventQueue: PusherEventQueue, reloadDecryptionKeySyncForChannelName channelName: String)
    
}
