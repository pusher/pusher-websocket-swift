//
//  PusherChannel.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

public class PusherChannel {
    public var eventHandlers: [String: [EventHandler]] = [:]
    public var subscribed = false
    public let name: String
    public let connection: PusherConnection
    public var unsentEvents = [PusherEvent]()
    
    public init(name: String, connection: PusherConnection) {
        self.name = name
        self.connection = connection
    }
    
    public func bind(eventName: String, callback: (AnyObject?) -> Void) -> String {
        let randomId = NSUUID().UUIDString
        let eventHandler = EventHandler(id: randomId, callback: callback)
        if self.eventHandlers[eventName] != nil {
            self.eventHandlers[eventName]?.append(eventHandler)
        } else {
            self.eventHandlers[eventName] = [eventHandler]
        }
        return randomId
    }
    
    public func unbind(eventName: String, callbackId: String) {
        if let eventSpecificHandlers = self.eventHandlers[eventName] {
            self.eventHandlers[eventName] = eventSpecificHandlers.filter({ $0.id != callbackId })
        }
    }
    
    public func unbindAll() {
        self.eventHandlers = [:]
    }
    
    public func unbindAllForEventName(eventName: String) {
        self.eventHandlers[eventName] = []
    }
    
    public func handleEvent(eventName: String, eventData: String) {
        if let eventHandlerArray = self.eventHandlers[eventName] {
            if let _ = connection.options.attemptToReturnJSONObject {
                for eventHandler in eventHandlerArray {
                    eventHandler.callback(connection.getEventDataJSONFromString(eventData))
                }
            } else {
                for eventHandler in eventHandlerArray {
                    eventHandler.callback(eventData)
                }
            }
        }
    }
    
    public func trigger(eventName: String, data: AnyObject) {
        if subscribed {
            self.connection.sendEvent(eventName, data: data, channelName: self.name)
        } else {
            unsentEvents.insert(PusherEvent(name: eventName, data: data), atIndex: 0)
        }
    }
}

public struct EventHandler {
    let id: String
    let callback: (AnyObject?) -> Void
}

public struct PusherEvent {
    public let name: String
    public let data: AnyObject
}
