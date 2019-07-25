import Foundation

public struct PusherEvent {
    internal let payload: [String:Any]

    // According to Channels protocol, there is always an event https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol#events
    public let event: String
    public let channel: String?
    public let data: Any?

    public let userId: String?

    init(eventName: String, payload: [String:Any], jsonize: Bool){
        // Parse the data if necessary
        if jsonize, let strongData = payload["data"] as? String {
            self.data = PusherParser.getEventDataJSON(from: strongData)
        }else{
            self.data = payload["data"]
        }

        self.event = eventName
        self.channel = payload["channel"] as! String?
        self.userId = payload["user_id"] as! String?

        // Replace the event name (so pusher_internal:subscription_succeeded can be mapped to pusher:subscription_succeeded)
        var payloadCopy = payload
        payloadCopy["event"] = eventName

        self.payload = payloadCopy
    }

    public func getProperty(name: String) -> Any?{
        return payload[name]
    }
}
