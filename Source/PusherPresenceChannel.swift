//
//  PusherPresenceChannel.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

public class PresencePusherChannel: PusherChannel {
    public var members: [PresenceChannelMember]
    public var onMemberAdded: ((PresenceChannelMember) -> ())?
    public var onMemberRemoved: ((PresenceChannelMember) -> ())?

    /**
        Initializes a new PresencePusherChannel with a given name, conenction, and optional
        member added and member removed handler functions

        - parameter name:            The name of the channel
        - parameter connection:      The connection that this channel is relevant to
        - parameter onMemberAdded:   A function that will be called with information about the
                                     member who has just joined the presence channel
        - parameter onMemberRemoved: A function that will be called with information about the
                                     member who has just left the presence channel

        - returns: A new PresencePusherChannel instance
    */
    init(name: String, connection: PusherConnection, onMemberAdded: ((PresenceChannelMember) -> ())? = nil, onMemberRemoved: ((PresenceChannelMember) -> ())? = nil) {
        self.members = []
        self.onMemberAdded = onMemberAdded
        self.onMemberRemoved = onMemberRemoved
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
        Add information about the members that are already subscribed to the presence channel to
        the members object of the presence channel and call onMemberAdded function, if provided

        - parameter memberHash: A dictionary representing the members that were already
                                subscribed to the presence channel
    */
    internal func addExistingMembers(memberHash: Dictionary<String, AnyObject>) {
        for (userId, userInfo) in memberHash {
            let member: PresenceChannelMember
            if let userInfo = userInfo as? PusherUserInfoObject {
                member = PresenceChannelMember(userId: userId, userInfo: userInfo)
            } else {
                member = PresenceChannelMember(userId: userId)
            }
            self.members.append(member)
            self.onMemberAdded?(member)
        }
    }

    /**
        Remove information about the member that has just left from the members object
        for the presence channel and call onMemberRemoved function, if provided

        - parameter memberJSON: A dictionary representing the member that has left the
                                presence channel
    */
    internal func removeMember(memberJSON: Dictionary<String, AnyObject>) {
        let id: String

        if let userId = memberJSON["user_id"] as? String {
            id = userId
        } else {
            id = String(memberJSON["user_id"])
        }

        if let index = self.members.indexOf({ $0.userId == id }) {
            let member = self.members[index]
            self.members.removeAtIndex(index)
            self.onMemberRemoved?(member)
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
