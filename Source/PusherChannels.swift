//
//  PusherGlobalChannel.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

public class PusherChannels {
    public var channels = [String: PusherChannel]()
    
    internal func add(channelName: String, connection: PusherConnection) -> PusherChannel {
        if let channel = self.channels[channelName] {
            return channel
        } else {
            var newChannel: PusherChannel
            if isPresenceChannel(channelName) {
                newChannel = PresencePusherChannel(name: channelName, connection: connection)
            } else {
                newChannel = PusherChannel(name: channelName, connection: connection)
            }
            self.channels[channelName] = newChannel
            return newChannel
        }
    }
    
    internal func remove(channelName: String) {
        self.channels.removeValueForKey(channelName)
    }
    
    internal func find(channelName: String) -> PusherChannel? {
        return self.channels[channelName]
    }
}