import Foundation

@objcMembers
open class PusherEvent: NSObject, NSCopying {
    /// The JSON payload received from the websocket
    internal let payload: [String:Any]

    // According to Channels protocol, there is always an event https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol#events
    /// The name of the event
    public let eventName: String
    /// The name of the channel that the event is associated with, e.g. "my-channel". Not present in events without an associated channel, e.g. "pusher:error" events relating to the connection
    public let channelName: String?
    /// The data payload of the event
    public let data: Any?

    /// The ID of the user who triggered the event. Only present in client event on presence channels
    public let userId: String?

    /**
     Initializes a Pusher event

     - parameter eventName: The name of the event. This will override the event name in the payload
     - parameter payload:   The JSON payload received from the websocket
     - parameter jsonize:   Determines whether an attempt will be made to parse the data property to JSON

     - returns: A new Pusher event
     */
    internal init(eventName: String, payload: [String:Any], jsonize: Bool) {
        // Parse the data if necessary
        if jsonize, let strongData = payload["data"] as? String {
            self.data = PusherParser.getEventDataJSON(from: strongData)
        }else{
            self.data = payload["data"]
        }

        self.channelName = payload["channel"] as? String
        self.userId = payload["user_id"] as? String
        self.eventName = eventName

        // Replace the event name (so pusher_internal:subscription_succeeded can be mapped to pusher:subscription_succeeded)
        var payloadCopy = payload
        payloadCopy["event"] = eventName

        self.payload = payloadCopy
    }

    /**
     Initializes a Pusher event

     - parameter eventName:   The name of the event
     - parameter channelName: The name of the channel
     - parameter userId:      The ID of the user who triggered the event
     - parameter data:        The data payload of the event
     - parameter payload:     The JSON payload received from the websocket

     - returns: A new Pusher event
     */
    internal init(
        eventName: String,
        channelName: String?,
        userId: String?,
        data: Any?,
        payload: [String:Any]
    ){
        self.eventName = eventName
        self.channelName = channelName
        self.userId = userId
        self.data = data
        self.payload = payload
    }

    /**
     Returns unparsed properties from the event JSON payload

     - parameter name: The name of the property to be returned

     - returns: The named property, if present
     */
    public func getProperty(name: String) -> Any?{
        return payload[name]
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        return PusherEvent(eventName: self.eventName, channelName: self.channelName, userId: self.userId, data: self.data, payload: self.payload)
    }
}
