import Foundation

struct PusherEncryptionHelpers {

    public static func shouldDecryptMessage(eventName: String, channelName: String?) -> Bool {
        return isEncryptedChannel(channelName: channelName) && !isPusherSystemEvent(eventName: eventName)
    }

    public static func isEncryptedChannel(channelName: String?) -> Bool {
        return channelName?.starts(with: "\(Constants.ChannelTypes.privateEncrypted)-") ?? false
    }

    public static func isPusherSystemEvent(eventName: String) -> Bool {
        return eventName.starts(with: "\(Constants.EventTypes.pusher):")
            || eventName.starts(with: "\(Constants.EventTypes.pusherInternal):")
    }
}
