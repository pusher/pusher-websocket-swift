//
//  PusherPresenceChannel.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

public typealias PusherUserInfoObject = Dictionary<String, AnyObject>

public class PresencePusherChannel: PusherChannel {
    public var members: [PresenceChannelMember]
    public var onMemberAdded: ((PresenceChannelMember) -> ())?
    public var onMemberRemoved: ((PresenceChannelMember) -> ())?
    public var myId: String? = nil

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
        for the presence channel and call onMemberAdded function, if provided

        - parameter memberJSON: A dictionary representing the member that has joined
                                the presence channel
    */
    internal func addMember(memberJSON: Dictionary<String, AnyObject>) {
        let member: PresenceChannelMember

        if let userId = memberJSON["user_id"] as? String {
            if let userInfo = memberJSON["user_info"] as? PusherUserInfoObject {
                member = PresenceChannelMember(userId: userId, userInfo: userInfo)

            } else {
                member = PresenceChannelMember(userId: userId)
            }
        } else {
            if let userInfo = memberJSON["user_info"] as? PusherUserInfoObject {
                member = PresenceChannelMember(userId: String(memberJSON["user_id"]), userInfo: userInfo)
            } else {
                member = PresenceChannelMember(userId: String(memberJSON["user_id"]))
            }
        }
        members.append(member)
        self.onMemberAdded?(member)
    }

    /**
        Add information about the members that are already subscribed to the presence channel to
        the members object of the presence channel

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

    /**
        Set the value of myId to the value of the user_id returned as part of the authorization
        of the subscription to the channel

        - parameter channelData: The channel data obtained from authorization of the subscription
                                to the channel
    */
    internal func setMyId(channelData: String) {
        if let channelDataObject = parseChannelData(channelData), userId = channelDataObject["user_id"] {
            self.myId = String(userId)
        }
    }

    /**
        Parse a string to extract the channel data object from it

        - parameter string: The channel data string received as part of authorization

        - returns: A dictionary of channel data
    */
    private func parseChannelData(channelData: String) -> Dictionary<String, AnyObject>? {
        let data = (channelData as NSString).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)

        do {
            if let jsonData = data, jsonObject = try NSJSONSerialization.JSONObjectWithData(jsonData, options: []) as? Dictionary<String, AnyObject> {
                return jsonObject
            } else {
                print("Unable to parse string: \(channelData)")
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }


    /**
        Returns the PresenceChannelMember object for the given user id

        - parameter string: The user id of the PresenceChannelMember for whom you want
                            the PresenceChannelMember object

        - returns: The PresenceChannelMember object for the given user id
    */
    public func findMember(userId: String) -> PresenceChannelMember? {
        return self.members.filter({ $0.userId == userId }).first
    }

    /**
        Returns the connected user's PresenceChannelMember object

        - returns: The connected user's PresenceChannelMember object
    */
    public func me() -> PresenceChannelMember? {
        if let id = self.myId {
            return findMember(id)
        } else {
            return nil
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
