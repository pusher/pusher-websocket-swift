import Foundation

protocol PusherKeyProvider: AnyObject {
    func decryptionKey(forChannelName channelName: String) -> String?
    func setDecryptionKey(_ decryptionKey: String, forChannelName channelName: String)
    func clearDecryptionKey(forChannelName channelName: String)
}

// MARK: - Concrete implementation

class PusherConcreteKeyProvider: PusherKeyProvider {

    // MARK: - Properties

    private var decryptionKeys: [String : String] = [:]

    // MARK: - Key provider

    func decryptionKey(forChannelName channelName: String) -> String? {
        return self.decryptionKeys[channelName]
    }

    func setDecryptionKey(_ decryptionKey: String, forChannelName channelName: String) {
        self.decryptionKeys[channelName] = decryptionKey
    }

    func clearDecryptionKey(forChannelName channelName: String) {
        self.decryptionKeys.removeValue(forKey: channelName)
    }
}
