import Foundation

@objc public extension Pusher {
    func subscribe(channelName: String) -> PusherChannel {
        return self.subscribe(channelName, onMemberAdded: nil, onMemberRemoved: nil)
    }

    func subscribe(
        channelName: String,
        onMemberAdded: ((PusherPresenceChannelMember) -> Void)? = nil,
        onMemberRemoved: ((PusherPresenceChannelMember) -> Void)? = nil
    ) -> PusherChannel {
        return self.subscribe(channelName, auth: nil, onMemberAdded: onMemberAdded, onMemberRemoved: onMemberRemoved)
    }

    func subscribeToPresenceChannel(channelName: String) -> PusherPresenceChannel {
        return self.subscribeToPresenceChannel(channelName: channelName,
                                               auth: nil,
                                               onMemberAdded: nil,
                                               onMemberRemoved: nil)
    }

    func subscribeToPresenceChannel(
        channelName: String,
        onMemberAdded: ((PusherPresenceChannelMember) -> Void)? = nil,
        onMemberRemoved: ((PusherPresenceChannelMember) -> Void)? = nil
    ) -> PusherPresenceChannel {
        return self.subscribeToPresenceChannel(channelName: channelName,
                                               auth: nil,
                                               onMemberAdded: onMemberAdded,
                                               onMemberRemoved: onMemberRemoved)
    }

    convenience init(withAppKey key: String, options: PusherClientOptions) {
        self.init(key: key, options: options)
    }

    convenience init(withKey key: String) {
        self.init(key: key)
    }
}
