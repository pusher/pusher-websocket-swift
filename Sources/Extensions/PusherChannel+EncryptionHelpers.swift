import Foundation

extension PusherChannel {

    /// Determines whether or not a message should be decrypted, based on channel and event attributes.
    /// - Parameters:
    ///   - name: The name of the channel.
    ///   - eventName: The name of the event received on the channel.
    /// - Returns: A `Bool` indicating whether the message should be decrypted or not.
    static func decryptsMessage(name: String?, eventName: String) -> Bool {
        return isEncrypted(name: name) && !isSystemEvent(eventName: eventName)
    }

    /// Determines if a channel is a private encrypted or not, based on its name.
    /// - Parameter name: The name of the channel.
    /// - Returns: A `Bool` indicating whether the channel is encrypted or not.
    static func isEncrypted(name: String?) -> Bool {
        return name?.starts(with: "\(Constants.ChannelTypes.privateEncrypted)-") ?? false
    }

    /// Determines if an event is a system event or not, based on its name.
    /// - Parameter eventName: The name of the event.
    /// - Returns: A `Bool` indicating whether the event is a system event or not.
    private static func isSystemEvent(eventName: String) -> Bool {
        return eventName.starts(with: "\(Constants.EventTypes.pusher):")
            || eventName.starts(with: "\(Constants.EventTypes.pusherInternal):")
    }
}
