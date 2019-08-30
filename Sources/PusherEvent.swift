import Foundation

@objcMembers
open class PusherEvent: NSObject, NSCopying {
    /// The JSON object received from the websocket
    internal let raw: [String:Any]

    // According to Channels protocol, there is always an event https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol#events
    /// The name of the event
    public var eventName: String { return raw["event"] as! String }
    /// The name of the channel that the event is associated with, e.g. "my-channel". Not present in events without an associated channel, e.g. "pusher:error" events relating to the connection
    public var channelName: String? { return raw["channel"] as? String }
    /// The data payload of the event
    public var data: String? { return raw["data"] as? String }
    /// The ID of the user who triggered the event. Only present in client event on presence channels
    public var userId: String? { return raw["user_id"] as? String }

    internal init?(jsonObject: [String:Any]){
        // Every event must have a name
        if !(jsonObject["event"] is String){
            return nil
        }
        self.raw = jsonObject
    }

    internal convenience init(eventName: String, event: PusherEvent){
        var jsonObject = event.raw
        jsonObject["event"] = eventName
        self.init(jsonObject: jsonObject)!
    }

    /// Parse the data payload to a JSON object, or return it without parsing if it's already a JSON object
    internal func dataToJSONObject() -> Any? {
        if let dataString = raw["data"] as? String {
            // Parse or return nil if we can't parse
            return PusherParser.getEventDataJSON(from: dataString)
        }else{
            // If not a string then it's either already a JSON object or nil
            return raw["data"];
        }
    }

    /**
     Returns unparsed properties from the event JSON payload

     - parameter name: The name of the property to be returned

     - returns: The named property, if present
     */
    public func getProperty(name: String) -> Any? {
        return raw[name]
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        return PusherEvent(jsonObject: self.raw)!
    }
}
