import Foundation

protocol PusherKeyProvider: AnyObject {
    func decryptionKey(forChannelName channelName: String) -> String?
    func setDecryptionKey(_ decryptionKey: String, forChannelName channelName: String)
    func clearDecryptionKey(forChannelName channelName: String)
}

// MARK: - Concrete implementation

class PusherConcreteKeyProvider: PusherKeyProvider {

    private var queue = DispatchQueue(label: "com.pusher.pusherswift-key-provider-\(UUID().uuidString)")

    // MARK: - Properties

    private var decryptionKeys: [String : String] = [:]

    // MARK: - Key provider

    func decryptionKey(forChannelName channelName: String) -> String? {
        return queue.sync {
            return self.decryptionKeys[channelName]
        }
    }

    func setDecryptionKey(_ decryptionKey: String, forChannelName channelName: String) {
        queue.sync {
            self.decryptionKeys[channelName] = decryptionKey
        }
    }

    func clearDecryptionKey(forChannelName channelName: String) {
        queue.sync {
            _ = self.decryptionKeys.removeValue(forKey: channelName)
        }
    }
}
