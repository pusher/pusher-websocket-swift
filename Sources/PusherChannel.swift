import Foundation

public enum PusherChannelType {
    case `private`
    case presence
    case normal

    public init(name: String) {
        self = Swift.type(of: self).type(forName: name)
    }

    public static func type(forName name: String) -> PusherChannelType {
        if (name.components(separatedBy: "-")[0] == "presence") {
            return .presence
        } else if (name.components(separatedBy: "-")[0] == "private") {
            return .private
        } else {
            return .normal
        }
    }

    public static func isPresenceChannel(name: String) -> Bool {
        return PusherChannelType(name: name) == .presence
    }
}

@objcMembers
open class PusherChannel: NSObject {
    open var eventHandlers: [String: [EventHandler]] = [:]
    open var subscribed = false
    public let name: String
    open weak var connection: PusherConnection?
    open var unsentEvents = [QueuedClientEvent]()
    public let type: PusherChannelType
    public var auth: PusherAuth?

    internal var shouldParseJSONForLegacyCallbacks: Bool {
        return connection?.options.attemptToReturnJSONObject ?? true
    }

    /**
        Initializes a new PusherChannel with a given name and conenction

        - parameter name:       The name of the channel
        - parameter connection: The connection that this channel is relevant to
        - parameter auth:       A PusherAuth value if subscription is being made to an
                                authenticated channel without using the default auth methods

        - returns: A new PusherChannel instance
    */
    public init(name: String, connection: PusherConnection, auth: PusherAuth? = nil) {
        self.name = name
        self.connection = connection
        self.auth = auth
        self.type = PusherChannelType(name: name)
    }

    /**
        Binds a callback to a given event name, scoped to the PusherChannel the function is
        called on

        - parameter eventName: The name of the event to bind to
        - parameter callback:  The function to call when a new event is received. The
                               callback receives the event's data payload

        - returns: A unique callbackId that can be used to unbind the callback at a later time
    */
    @discardableResult open func bind(eventName: String, callback: @escaping (Any?) -> Void) -> String {
        return bind(eventName: eventName, eventCallback: { [weak self] (event: PusherEvent) -> Void in
            guard let self = self else { return }
            // Mimic the old parsing behaviour for backwards compatibility
            let callbackData: Any?
            if self.shouldParseJSONForLegacyCallbacks {
                if let data = event.dataToJSONObject() {
                    // Parsed data
                    callbackData = data
                } else {
                    // Unparsed string if we couldn't parse
                    callbackData = event.data
                }
            } else {
                callbackData = event.raw["data"]
            }
            callback(callbackData)
        });
    }

    /**
     Binds a callback to a given event name, scoped to the PusherChannel the function is
     called on

     - parameter eventName:     The name of the event to bind to
     - parameter eventCallback: The function to call when a new event is received. The callback
                                receives a PusherEvent, containing the event's data payload and
                                other properties.

     - returns: A unique callbackId that can be used to unbind the callback at a later time
     */
    @discardableResult open func bind(eventName: String, eventCallback: @escaping (PusherEvent) -> Void) -> String {
        let randomId = UUID().uuidString
        let eventHandler = EventHandler(id: randomId, callback: eventCallback)
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
    open func unbind(eventName: String, callbackId: String) {
        if let eventSpecificHandlers = self.eventHandlers[eventName] {
            self.eventHandlers[eventName] = eventSpecificHandlers.filter({ $0.id != callbackId })
        }
    }

    /**
        Unbinds all callbacks from the channel
    */
    open func unbindAll() {
        self.eventHandlers = [:]
    }

    /**
        Unbinds all callbacks for the given eventName from the channel

        - parameter eventName:  The name of the event from which to unbind
    */
    open func unbindAll(forEventName eventName: String) {
        self.eventHandlers[eventName] = []
    }

    /**
        Calls the appropriate callbacks for the given eventName in the scope of the acted upon channel

        - parameter event: The event received from the websocket
    */
    open func handleEvent(event: PusherEvent) {
        if let eventHandlerArray = self.eventHandlers[event.eventName] {
            for eventHandler in eventHandlerArray {
                eventHandler.callback(event.copy() as! PusherEvent)
            }
        }
    }

    /**
        If subscribed, immediately call the connection to trigger a client event with the given
        eventName and data, otherwise queue it up to be triggered upon successful subscription

        - parameter eventName: The name of the event to trigger
        - parameter data:      The data to be sent as the message payload
    */
    open func trigger(eventName: String, data: Any) {
        if subscribed {
            connection?.sendEvent(event: eventName, data: data, channel: self)
        } else {
            unsentEvents.insert(QueuedClientEvent(name: eventName, data: data), at: 0)
        }
    }
}

public struct EventHandler {
    let id: String
    let callback: (PusherEvent) -> Void
}

public struct QueuedClientEvent {
    public let name: String
    public let data: Any
}
