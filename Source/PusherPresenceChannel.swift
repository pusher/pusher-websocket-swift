//
//  PusherPresenceChannel.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

public class PresencePusherChannel: PusherChannel {
    public var members: [PresenceChannelMember]
    
    override init(name: String, connection: PusherConnection) {
        self.members = []
        super.init(name: name, connection: connection)
    }
    
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
    
    internal func addExistingMembers(memberHash: Dictionary<String, AnyObject>) {
        for (userId, userInfo) in memberHash {
            if let userInfo = userInfo as? PusherUserInfoObject {
                self.members.append(PresenceChannelMember(userId: userId, userInfo: userInfo))
            } else {
                self.members.append(PresenceChannelMember(userId: userId))
            }
        }
    }
    
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
