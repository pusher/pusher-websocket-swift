import Foundation

@objcMembers
open class PusherEvent: NSObject, NSCopying {
    /// The JSON object received from the websocket
    @nonobjc internal let raw: [String: Any]

    // According to Channels protocol, there is always an event https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol#events
    /// The name of the event.
    public var eventName: String { return raw["event"] as! String }
    /// The name of the channel that the event was triggered on. Not present in events without an associated channel, e.g. "pusher:error" events relating to the connection.
    public var channelName: String? { return raw["channel"] as? String }
    /// The data that was passed when the event was triggered.
    public var data: String? { return raw["data"] as? String }
    /// The ID of the user who triggered the event. Only present in client event on presence channels.
    public var userId: String? { return raw["user_id"] as? String }

    @nonobjc internal init?(jsonObject: [String: Any]) {
        // Every event must have a name
        if !(jsonObject["event"] is String) {
            return nil
        }
        self.raw = jsonObject
    }

    /**
     Parse the data payload to a JSON object

     - returns: The JSON as Swift data types
    */
    @nonobjc internal func dataToJSONObject() -> Any? {
        guard let data = data else {
            return nil
        }
        // Parse or return nil if we can't parse
        return PusherParser.getEventDataJSON(from: data)
    }

    /**
     A helper function for accessing raw properties from the websocket event. Data
     returned by this function should not be considered stable and it is recommended
     that you use the properties of the `PusherEvent` instance instead e.g.
     `eventName`, `channelName` etc.

     - parameter key: The key of the property to be returned

     - returns: The property, if present
     */
    public func property(withKey key: String) -> Any? {
        return raw[key]
    }

    /**
     Creates a copy of the `PusherEvent` with an updated event name. This is useful
     when translating `pusher_internal:` events to `pusher:` events.

     - parameter eventName: The name of the new event

     - returns: The new `PusherEvent`
     */
    @nonobjc internal func copy(withEventName eventName: String) -> PusherEvent {
        var jsonObject = self.raw
        jsonObject["event"] = eventName
        return PusherEvent(jsonObject: jsonObject)!
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        return PusherEvent(jsonObject: self.raw)!
    }
}
