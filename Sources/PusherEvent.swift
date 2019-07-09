//
//  PusherEvent.swift
//  PusherSwift
//
//  Created by Tom Kemp on 11/07/2019.
//

import Foundation

// TODO: Should we go with PusherChannelsEvent or PusherEvent
public struct PusherEvent {
    internal let payload: [String:Any]

    // According to channels protocol, there is always an event https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol#events
    //TODO: change to 'name'? 'eventName' might be better, or should it match the socket value
    public let event: String
    public let channel: String?
    public let data: Any?
    public let userId: String?

    init(payload: [String:Any], eventName: String? = nil, jsonize: Bool){
        var payloadCopy = payload

        if let eventName = eventName {
            self.event = eventName
            payloadCopy["event"] = eventName
        }else{
            self.event = payloadCopy["event"] as! String
        }
        self.channel = payloadCopy["channel"] as! String?

        if jsonize, let strongData = payloadCopy["data"] as? String {
            self.data = PusherParser.getEventDataJSON(from: strongData)
        }else{
            self.data = payloadCopy["data"]
        }

        self.userId = payloadCopy["user_id"] as! String?
        self.payload = payloadCopy
    }

    // Is "data" metadata? getRaw maybe. The JSON won't be parsed as it stands
    // the word key is there twice?
    public func getKey(key: String) -> Any?{
        return payload[key]
    }
}
