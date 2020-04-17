import Foundation

protocol PusherEventFactory {
    
    func makeEvent(fromJSON json: PusherEventPayload, withDecryptionKey decryptionKey: String?) throws -> PusherEvent
    
}

// MARK: - Concrete implementation

struct PusherConcreteEventFactory: PusherEventFactory {

    // MARK: - Event factory
    
    func makeEvent(fromJSON json: PusherEventPayload, withDecryptionKey decryptionKey: String? = nil) throws -> PusherEvent {
        guard let eventName = json["event"] as? String else {
            throw PusherEventError.invalidFormat
        }
        
        let channelName = json["channel"] as? String
        let data = try self.data(fromJSON: json, eventName: eventName, channelName: channelName, decryptionKey: decryptionKey)
        let userId = json["user_id"] as? String
        
        return PusherEvent(eventName: eventName, channelName: channelName, data: data, userId: userId, raw: json)
    }
    
    // MARK: - Private methods
    
    private func data(fromJSON json: PusherEventPayload, eventName: String, channelName: String?, decryptionKey: String?) throws -> String? {
        let data = json["data"] as? String
        
        if self.isEncryptedChannel(channelName: channelName) && !self.isPusherSystemEvent(eventName: eventName) {
            return try PusherDecryptor.decrypt(data: data, decryptionKey: decryptionKey)
        }
        else {
            return data
        }
    }
    
    private func isEncryptedChannel(channelName: String?) -> Bool {
        return channelName?.starts(with: "private-encrypted-") ?? false
    }
    
    private func isPusherSystemEvent(eventName: String) -> Bool {
        return eventName.starts(with: "pusher:") || eventName.starts(with: "pusher_internal:")
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
