//
//  PusherPresenceChannel.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

public class PresencePusherChannel: PusherChannel {
    public var members: [PresenceChannelMember]

    /**
        Initializes a new PresencePusherChannel with a given name and conenction

        - parameter name:       The name of the channel
        - parameter connection: The connection that this channel is relevant to

        - returns: A new PresencePusherChannel instance
    */
    override init(name: String, connection: PusherConnection) {
        self.members = []
        super.init(name: name, connection: connection)
    }

    /**
        Add information about the member that has just joined to the members object
        for the presence channel

        - parameter memberJSON: A dictionary representing the member that has joined
                                the presence channel
    */
    internal func addMember(memberJSON: Dictionary<String, AnyObject>) {
        if let userId = memberJSON["user_id"] as? String {
            if let userInfo = memberJSON["user_info"] as? PusherUserInfoObject {
                members.append(PresenceChannelMember(userId: userId, userInfo: userInfo))
            } else {
                members.append(PresenceChannelMember(userId: userId))
            }
        } else if let userId = memberJSON["user_id"] as? Int {
            if let userInfo = memberJSON["user_info"] as? PusherUserInfoObject {
                members.append(PresenceChannelMember(userId: String(userId), userInfo: userInfo))
            } else {
                members.append(PresenceChannelMember(userId: String(userId)))
            }
        }
    }

    /**
        Add information about the members that are already subscribed to the presence channel
        to the members object of the presence channel

        - parameter memberHash: A dictionary representing the members that were already
                                subscribed to the presence channel
    */
    internal func addExistingMembers(memberHash: Dictionary<String, AnyObject>) {
        for (userId, userInfo) in memberHash {
            if let userInfo = userInfo as? PusherUserInfoObject {
                self.members.append(PresenceChannelMember(userId: userId, userInfo: userInfo))
            } else {
                self.members.append(PresenceChannelMember(userId: userId))
            }
        }
    }

    /**
        Remove information about the member that has just left from the members object
        for the presence channel

        - parameter memberJSON: A dictionary representing the member that has left the
                                presence channel
    */
    internal func removeMember(memberJSON: Dictionary<String, AnyObject>) {
        if let userId = memberJSON["user_id"] as? String {
            self.members = self.members.filter({ $0.userId != userId })
        } else if let userId = memberJSON["user_id"] as? Int {
            self.members = self.members.filter({ $0.userId != String(userId) })
        }
    }
}

public struct PresenceChannelMember {
    public let userId: String
    public let userInfo: AnyObject?

    public init(userId: String, userInfo: AnyObject? = nil) {
        self.userId = userId
        self.userInfo = userInfo
    }
}
