import Foundation

@objcMembers
open class PusherEvent: NSObject, NSCopying {

    /// The JSON object received from the websocket
    @nonobjc internal let raw: [String: Any]

    /// According to Channels protocol, there is always an event
    /// https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol#events
    /// The name of the event.
    public let eventName: String

    /// The name of the channel that the event was triggered on.
    /// Not present in events without an associated channel, e.g. "pusher:error" events relating to the connection.
    public let channelName: String?

    /// The data that was passed when the event was triggered.
    public let data: String?

    /// The ID of the user who triggered the event. Only present in client event on presence channels.
    public let userId: String?

    @nonobjc internal init(eventName: String,
                           channelName: String?,
                           data: String?,
                           userId: String?,
                           raw: [String: Any]) {
        self.eventName = eventName
        self.channelName = channelName
        self.data = data
        self.userId = userId
        self.raw = raw
    }

    /**
     Parse the data payload to a JSON object

     - returns: The JSON as Swift data types
    */
    @nonobjc internal func dataToJSONObject() -> Any? {
        guard let data = self.data else {
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
        return self.raw[key]
    }

    /**
     Creates a copy of the `PusherEvent` with an updated event name. This is useful
     when translating `pusher_internal:` events to `pusher:` events.

     - parameter eventName: The name of the new event

     - returns: The new `PusherEvent`
     */
    @nonobjc internal func copy(withEventName eventName: String) -> PusherEvent {
        var jsonObject = self.raw
        jsonObject[Constants.JSONKeys.event] = eventName
        return PusherEvent(eventName: eventName,
                           channelName: self.channelName,
                           data: self.data,
                           userId: self.userId,
                           raw: jsonObject)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        return PusherEvent(eventName: self.eventName,
                           channelName: self.channelName,
                           data: self.data,
                           userId: self.userId,
                           raw: self.raw)
    }

}
