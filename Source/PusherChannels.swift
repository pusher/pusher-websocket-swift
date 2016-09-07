//
//  PusherGlobalChannel.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

open class PusherChannels {
    open var channels = [String: PusherChannel]()

    /**
        Create a new PusherChannel, which is returned, and add it to the PusherChannels list
        of channels

        - parameter name:            The name of the channel to create
        - parameter connection:      The connection associated with the channel being created
        - parameter onMemberAdded:   A function that will be called with information about the
                                     member who has just joined the presence channel
        - parameter onMemberRemoved: A function that will be called with information about the
                                     member who has just left the presence channel

        - returns: A new PusherChannel instance
    */
    internal func add(
        name: String,
        connection: PusherConnection,
        onMemberAdded: ((PresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((PresenceChannelMember) -> ())? = nil) -> PusherChannel {
            if let channel = self.channels[name] {
                return channel
            } else {
                var newChannel: PusherChannel
                if PusherChannelType.isPresenceChannel(name: name) {
                    newChannel = PresencePusherChannel(
                        name: name,
                        connection: connection,
                        onMemberAdded: onMemberAdded,
                        onMemberRemoved: onMemberRemoved
                    )
                } else {
                    newChannel = PusherChannel(name: name, connection: connection)
                }
                self.channels[name] = newChannel
                return newChannel
            }
    }

    /**
        Remove the PusherChannel with the given channelName from the channels list

        - parameter name: The name of the channel to remove
    */
    internal func remove(name: String) {
        self.channels.removeValue(forKey: name)
    }

    /**
        Return the PusherChannel with the given channelName from the channels list, if it exists

        - parameter name: The name of the channel to return

        - returns: A PusherChannel instance, if a channel with the given name existed, otherwise nil
    */
    internal func find(name: String) -> PusherChannel? {
        return self.channels[name]
    }
}
