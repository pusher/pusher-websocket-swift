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

    /**
        Initializes a new PusherChannel with a given name and conenction

        - parameter name:       The name of the channel
        - parameter connection: The connection that this channel is relevant to

        - returns: A new PusherChannel instance
    */
    public init(name: String, connection: PusherConnection) {
        self.name = name
        self.connection = connection
    }

    /**
        Binds a callback to a given event name, scoped to the PusherChannel the function is
        called on

        - parameter eventName: The name of the event to bind to
        - parameter callback:  The function to call when a message is received with the relevant
                               channel and event names

        - returns: A unique callbackId that can be used to unbind the callback at a later time
    */
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

    /**
        Unbinds the callback with the given callbackId from the given eventName, in the scope
        of the channel being acted upon

        - parameter eventName:  The name of the event from which to unbind
        - parameter callbackId: The unique callbackId string used to identify which callback to unbind
    */
    public func unbind(eventName: String, callbackId: String) {
        if let eventSpecificHandlers = self.eventHandlers[eventName] {
            self.eventHandlers[eventName] = eventSpecificHandlers.filter({ $0.id != callbackId })
        }
    }

    /**
        Unbinds all callbacks from the channel
    */
    public func unbindAll() {
        self.eventHandlers = [:]
    }

    /**
        Unbinds all callbacks for the given eventName from the channel

        - parameter eventName:  The name of the event from which to unbind
    */
    public func unbindAllForEventName(eventName: String) {
        self.eventHandlers[eventName] = []
    }

    /**
        Calls the appropriate callbacks for the given eventName in the scope of the acted upon channel

        - parameter eventName: The name of the received event
        - parameter eventdata: The data associated with the received message
    */
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

    /**
        If subscribed, immediately call the connection to trigger a client event with the given
        eventName and data, otherwise queue it up to be triggered upon successful subscription

        - parameter eventName: The name of the event to trigger
        - parameter data:      The data to be sent as the message payload
    */
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
