import Foundation

protocol PusherEventQueue {
    
    var delegate: PusherEventQueueDelegate? { get set }

    func report(json: PusherEventPayload, forChannelName channelName: String?)
    
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
    func report(json: PusherEventPayload, forChannelName channelName: String?) {
        if let channelName = channelName {
            self.enqueue(json: json, forChannelName: channelName)
        }
        else {
            // Events with a missing channel name should never be encrypted, therefore we can ignore `invalidDecryptionKey` errors here.
            try? self.processEvent(json: json)
        }
    }
    
    // MARK: - Private methods
    
    private func enqueue(json: PusherEventPayload, forChannelName channelName: String) {
        queue.async {
            do {
                try self.processEvent(json: json, forChannelName: channelName)
            } catch PusherEventError.invalidDecryptionKey {
                self.delegate?.eventQueue(self, reloadDecryptionKeySyncForChannelName: channelName)
                do {
                    try self.processEvent(json: json, forChannelName: channelName)
                }catch {
                    self.delegate?.eventQueue(self, didFailToDecryptEventWithPayload: json, forChannelName: channelName)
                }
            } catch {}
        }
    }

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
    func eventQueue(_ eventQueue: PusherEventQueue, reloadDecryptionKeySyncForChannelName channelName: String)
    
}
