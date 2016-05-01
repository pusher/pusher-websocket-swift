//
//  PusherGlobalChannel.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

public class GlobalChannel: PusherChannel {
    public var globalCallbacks: [String: (AnyObject?) -> Void] = [:]

    /**
        Initializes a new GlobalChannel instance

        - parameter connection: The connection associated with the global channel

        - returns: A new GlobalChannel instance
    */
    init(connection: PusherConnection) {
        super.init(name: "pusher_global_internal_channel", connection: connection)
    }

    /**
        Calls the appropriate callbacks for the given eventName in the scope of the global channel

        - parameter channelName: The name of the channel that the received message was triggered to
        - parameter eventName:   The name of the received event
        - parameter eventdata:   The data associated with the received message
    */
    internal func handleEvent(channelName: String, eventName: String, eventData: String) {
        for (_, callback) in self.globalCallbacks {
            callback(["channel": channelName, "event": eventName, "data": eventData])
        }
    }

    /**
        Binds a callback to the global channel

        - parameter callback:  The function to call when a message is received

        - returns: A unique callbackId that can be used to unbind the callback at a later time
    */
    internal func bind(callback: (AnyObject?) -> Void) -> String {
        let randomId = NSUUID().UUIDString
        self.globalCallbacks[randomId] = callback
        return randomId
    }

    /**
        Unbinds the callback with the given callbackId from the global channel

        - parameter callbackId: The unique callbackId string used to identify which callback to unbind
    */
    internal func unbind(callbackId: String) {
        globalCallbacks.removeValueForKey(callbackId)
    }

    /**
        Unbinds all callbacks from the channel
    */
    override public func unbindAll() {
        globalCallbacks = [:]
    }
}