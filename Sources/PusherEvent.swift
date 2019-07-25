import Foundation

public struct PusherEvent {
    /// The JSON payload received from the websocket
    internal let payload: [String:Any]

    // According to Channels protocol, there is always an event https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol#events
    /// The name of the event
    public let event: String
    /// The name of the channel that the event was received on. Not present in `pusher:error` events
    public let channel: String?
    /// The data payload of the event
    public let data: Any?

    /// The Id of the user who triggered the event. Only present in client events.
    public let userId: String?

    /**
     Initializes a Pusher event

     - parameter eventName: The name of the event. This will override the event name in the payload
     - parameter payload:   The JSON payload received from the websocket
     - parameter jsonize:   Determines whether an attempt will be made to parse the data parameter to JSON

     - returns: A new Pusher event
     */
    internal init(eventName: String, payload: [String:Any], jsonize: Bool){
        // Parse the data if necessary
        if jsonize, let strongData = payload["data"] as? String {
            self.data = PusherParser.getEventDataJSON(from: strongData)
        }else{
            self.data = payload["data"]
        }

        self.channel = payload["channel"] as? String
        self.userId = payload["user_id"] as? String
        self.event = eventName

        // Replace the event name (so pusher_internal:subscription_succeeded can be mapped to pusher:subscription_succeeded)
        var payloadCopy = payload
        payloadCopy["event"] = eventName

        self.payload = payloadCopy
    }

    /**
     Returns unparsed properties from the event JSON payload

     - parameter name: The name of the property to be returned

     - returns: The named property, if present
     */
    public func getProperty(name: String) -> Any?{
        return payload[name]
    }
}
