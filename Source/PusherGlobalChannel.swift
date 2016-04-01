//
//  PusherGlobalChannel.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

public class GlobalChannel: PusherChannel {
    public var globalCallbacks: [String: (AnyObject?) -> Void] = [:]
    
    init(connection: PusherConnection) {
        super.init(name: "pusher_global_internal_channel", connection: connection)
    }
    
    internal func handleEvent(channelName: String, eventName: String, eventData: String) {
        for (_, callback) in self.globalCallbacks {
            callback(["channel": channelName, "event": eventName, "data": eventData])
        }
    }
    
    internal func bind(callback: (AnyObject?) -> Void) -> String {
        let randomId = NSUUID().UUIDString
        self.globalCallbacks[randomId] = callback
        return randomId
    }
    
    internal func unbind(callbackId: String) {
        globalCallbacks.removeValueForKey(callbackId)
    }
    
    override public func unbindAll() {
        globalCallbacks = [:]
    }
}