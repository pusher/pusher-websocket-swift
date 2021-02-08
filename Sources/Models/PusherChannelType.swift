import Foundation

public enum PusherChannelType {
    case `private`
    case presence
    case normal

    public init(name: String) {
        self = Self.type(forName: name)
    }

    public static func type(forName name: String) -> PusherChannelType {
        if name.components(separatedBy: "-")[0] == Constants.ChannelTypes.presence {
            return .presence
        } else if name.components(separatedBy: "-")[0] == Constants.ChannelTypes.private {
            return .private
        } else {
            return .normal
        }
    }

    public static func isPresenceChannel(name: String) -> Bool {
        return PusherChannelType(name: name) == .presence
    }
}
