import Foundation

@objcMembers
@objc open class GlobalChannel: PusherChannel {
    open var globalCallbacks: [String : (Any?) -> Void] = [:]

    /**
        Initializes a new GlobalChannel instance

        - parameter connection: The connection associated with the global channel

        - returns: A new GlobalChannel instance
    */
    init(connection: PusherConnection) {
        super.init(name: "pusher_global_internal_channel", connection: connection)
    }

    /**
        Calls the appropriate callbacks for the given event name in the scope of the global channel

        - parameter name:        The name of the received event
        - parameter data:        The data associated with the received message
        - parameter channelName: The name of the channel that the received message was triggered
                                 to, if relevant
    */
    internal func handleEvent(name: String, data: String, channelName: String?) {
        for (_, callback) in self.globalCallbacks {
            if let channelName = channelName {
                callback(["channel": channelName, "event": name, "data": data] as [String: Any])
            } else {
                callback(["event": name, "data": data] as [String: Any])
            }
        }
    }

    /**
        Calls the appropriate callbacks for the given event name in the scope of the global channel

        - parameter name: The name of the received event
        - parameter data: The data associated with the received message
    */
    internal func handleErrorEvent(name: String, data: [String: AnyObject]) {
        for (_, callback) in self.globalCallbacks {
            callback(["event": name, "data": data])
        }
    }

    /**
        Binds a callback to the global channel

        - parameter callback:  The function to call when a message is received

        - returns: A unique callbackId that can be used to unbind the callback at a later time
    */
    internal func bind(_ callback: @escaping (Any?) -> Void) -> String {
        let randomId = UUID().uuidString
        self.globalCallbacks[randomId] = callback
        return randomId
    }

    /**
        Unbinds the callback with the given callbackId from the global channel

        - parameter callbackId: The unique callbackId string used to identify which callback to unbind
    */
    internal func unbind(callbackId: String) {
        globalCallbacks.removeValue(forKey: callbackId)
    }

    /**
        Unbinds all callbacks from the channel
    */
    override open func unbindAll() {
        globalCallbacks = [:]
    }
}
