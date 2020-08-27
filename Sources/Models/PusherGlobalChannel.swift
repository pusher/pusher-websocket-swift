import Foundation

@objcMembers
@objc open class GlobalChannel: PusherChannel {
    open var globalCallbacks: [String: (PusherEvent) -> Void] = [:]
    open var globalLegacyCallbacks: [String: (Any?) -> Void] = [:]

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

        - parameter event: The event received from the websocket
    */
    internal func handleGlobalEvent(event: PusherEvent) {
        for (_, callback) in self.globalCallbacks {
            callback(event.copy() as! PusherEvent)
        }
    }

    /**
     Calls the appropriate legacy callbacks for the given event name in the scope of the global channel

     - parameter event: The JSON object received from the websocket
     */
    internal func handleGlobalEventLegacy(event: [String: Any]) {
        for (_, callback) in self.globalLegacyCallbacks {
            callback(event)
        }
    }


    /**
        Binds a callback to the global channel

        - parameter callback:  The function to call when a message is received

        - returns: A unique callbackId that can be used to unbind the callback at a later time
    */
    internal func bind(_ callback: @escaping (PusherEvent) -> Void) -> String {
        let randomId = UUID().uuidString
        self.globalCallbacks[randomId] = callback
        return randomId
    }

    /**
     Binds a callback to the global channel

     - parameter callback:  The function to call when a message is received

     - returns: A unique callbackId that can be used to unbind the callback at a later time
     */
    internal func bindLegacy(_ callback: @escaping (Any?) -> Void) -> String {
        let randomId = UUID().uuidString
        self.globalLegacyCallbacks[randomId] = callback
        return randomId
    }

    /**
        Unbinds the callback with the given callbackId from the global channel

        - parameter callbackId: The unique callbackId string used to identify which callback to unbind
    */
    internal func unbind(callbackId: String) {
        globalCallbacks.removeValue(forKey: callbackId)
        globalLegacyCallbacks.removeValue(forKey: callbackId)
    }

    /**
        Unbinds all callbacks from the channel
    */
    override open func unbindAll() {
        globalCallbacks = [:]
        globalLegacyCallbacks = [:]
    }
}
