import Foundation

protocol PusherEventQueue {
    
    var delegate: PusherEventQueueDelegate? { get set }

    func removeQueue(forChannelName channelName: String)
    func report(json: PusherEventPayload, forChannelName channelName: String?)
    
}

// MARK: - Concrete implementation

class ChannelQueue {
    var queue: [PusherEventPayload] = []
    var paused: Bool = false
}

class PusherConcreteEventQueue: PusherEventQueue {
    
    // MARK: - Properties
    
    private let eventFactory: PusherEventFactory
    private let keyProvider: PusherKeyProvider
    private var queues: [String : DispatchQueue]
    
    weak var delegate: PusherEventQueueDelegate?
    
    // MARK: - Initializers
    
    init(eventFactory: PusherEventFactory, keyProvider: PusherKeyProvider) {
        self.queues = [:]
        self.eventFactory = eventFactory
        self.keyProvider = keyProvider
    }
    
    // MARK: - Event queue

    func removeQueue(forChannelName channelName: String){
        self.queues.removeValue(forKey: channelName)
    }
    
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
        let channelQueue = self.queues[channelName] ?? DispatchQueue(label: "com.pusher.pusherswift-event-queue-\(UUID().uuidString)")
        self.queues[channelName] = channelQueue
        channelQueue.async {
            do {
                try self.processEvent(json: json, forChannelName: channelName)
            } catch PusherEventError.invalidDecryptionKey {
                self.delegate?.eventQueue(self, reloadDecryptionKeySyncForChannelName: channelName)
                do {
                    try self.processEvent(json: json, forChannelName: channelName)
                }catch {
                    print("Skipping event that could not be decrypted")
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
        DispatchQueue.main.async {
            self.delegate?.eventQueue(self, didReceiveEvent: event, forChannelName: channelName)
        }
    }
}

// MARK: - Delegate

protocol PusherEventQueueDelegate: AnyObject {
    
    func eventQueue(_ eventQueue: PusherEventQueue, didReceiveEvent event: PusherEvent, forChannelName channelName: String?)
    func eventQueue(_ eventQueue: PusherEventQueue, reloadDecryptionKeySyncForChannelName channelName: String)
    
}
