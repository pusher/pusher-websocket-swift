import Foundation

@objcMembers
open class PusherEvent: NSObject, NSCopying {
    /// The JSON payload received from the websocket
    internal let payload: [String:Any]

    // According to Channels protocol, there is always an event https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol#events
    /// The name of the event
    public var eventName: String { return payload["event"] as! String }
    /// The name of the channel that the event is associated with, e.g. "my-channel". Not present in events without an associated channel, e.g. "pusher:error" events relating to the connection
    public var channelName: String? { return payload["channel"] as? String }
    /// The data payload of the event
    public var data: String? { return payload["data"] as? String }
    /// The ID of the user who triggered the event. Only present in client event on presence channels
    public var userId: String? { return payload["user_id"] as? String }

    private var json: [String:Any]?
    public lazy var jsonData: [String:Any]? = getJSON();

    internal init?(payload: [String:Any]){
        if !(payload["event"] is String){
            return nil
        }

        if let json = payload["data"] as? [String:Any] {
            self.json = json
        }

        self.payload = payload
    }

    internal convenience init(eventName: String, event: PusherEvent){
        var payload = event.payload
        payload["event"] = eventName
        self.init(payload: payload)!
    }

    /**
     Returns unparsed properties from the event JSON payload

     - parameter name: The name of the property to be returned

     - returns: The named property, if present
     */
    public func getProperty(name: String) -> Any? {
        return payload[name]
    }

    private func getJSON() -> [String: Any]? {
        if self.json == nil, let data = self.data {
            self.json = PusherParser.getPusherEventJSON(from: data)
        }
        return self.json
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        // TODO: copy parsed JSON?
        return PusherEvent(payload: self.payload)!
    }
}
