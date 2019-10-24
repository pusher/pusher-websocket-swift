import Foundation
import Starscream

let PROTOCOL = 7
let VERSION = "7.2.0"
let CLIENT_NAME = "pusher-websocket-swift"

@objcMembers
@objc open class Pusher: NSObject {
    public let connection: PusherConnection
    open weak var delegate: PusherDelegate? = nil {
        willSet {
            self.connection.delegate = newValue
        }
    }
    private let key: String

    /**
        Initializes the Pusher client with an app key and any appropriate options.

        - parameter key:          The Pusher app key
        - parameter options:      An optional collection of options

        - returns: A new Pusher client instance
    */
    public init(key: String, options: PusherClientOptions = PusherClientOptions()) {
        self.key = key
        let urlString = constructUrl(key: key, options: options)
        let ws = WebSocket(url: URL(string: urlString)!)
        connection = PusherConnection(key: key, socket: ws, url: urlString, options: options)
        connection.createGlobalChannel()
    }

    /**
        Subscribes the client to a new channel

        - parameter channelName:     The name of the channel to subscribe to
        - parameter auth:            A PusherAuth value if subscription is being made to an
                                     authenticated channel without using the default auth methods
        - parameter onMemberAdded:   A function that will be called with information about the
                                     member who has just joined the presence channel
        - parameter onMemberRemoved: A function that will be called with information about the
                                     member who has just left the presence channel

        - returns: A new PusherChannel instance
    */
    open func subscribe(
        _ channelName: String,
        auth: PusherAuth? = nil,
        onMemberAdded: ((PusherPresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((PusherPresenceChannelMember) -> ())? = nil
    ) -> PusherChannel {
        return self.connection.subscribe(
            channelName: channelName,
            auth: auth,
            onMemberAdded: onMemberAdded,
            onMemberRemoved: onMemberRemoved
        )
    }

    /**
        Subscribes the client to a new presence channel. Use this instead of the subscribe
        function when you want a presence channel object to be returned instead of just a
        generic channel object (which you can then cast)

        - parameter channelName:     The name of the channel to subscribe to
        - parameter auth:            A PusherAuth value if subscription is being made to an
                                     authenticated channel without using the default auth methods
        - parameter onMemberAdded:   A function that will be called with information about the
                                     member who has just joined the presence channel
        - parameter onMemberRemoved: A function that will be called with information about the
                                     member who has just left the presence channel

        - returns: A new PusherPresenceChannel instance
    */
    open func subscribeToPresenceChannel(
        channelName: String,
        auth: PusherAuth? = nil,
        onMemberAdded: ((PusherPresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((PusherPresenceChannelMember) -> ())? = nil
    ) -> PusherPresenceChannel {
        return self.connection.subscribeToPresenceChannel(
            channelName: channelName,
            auth: auth,
            onMemberAdded: onMemberAdded,
            onMemberRemoved: onMemberRemoved
        )
    }

    /**
        Unsubscribes the client from a given channel

        - parameter channelName: The name of the channel to unsubscribe from
    */
    open func unsubscribe(_ channelName: String) {
        self.connection.unsubscribe(channelName: channelName)
    }

    /**
        Unsubscribes the client from all channels
    */
    open func unsubscribeAll() {
        self.connection.unsubscribeAll()
    }

    /**
        Binds the client's global channel to all events

        - parameter callback: The function to call when a new event is received. The callback
                              receives the event's data payload

        - returns: A unique string that can be used to unbind the callback from the client
    */
    @discardableResult open func bind(_ callback: @escaping (Any?) -> Void) -> String {
        return self.connection.addLegacyCallbackToGlobalChannel(callback)
    }

    /**
     Binds the client's global channel to all events

     - parameter eventCallback: The function to call when a new event is received. The callback
                                receives a PusherEvent, containing the event's data payload and
                                other properties.

     - returns: A unique string that can be used to unbind the callback from the client
     */
    @discardableResult open func bind(eventCallback: @escaping (PusherEvent) -> Void) -> String {
        return self.connection.addCallbackToGlobalChannel(eventCallback)
    }

    /**
        Unbinds the client from its global channel

        - parameter callbackId: The unique callbackId string used to identify which callback
                                to unbind
    */
    open func unbind(callbackId: String) {
        self.connection.removeCallbackFromGlobalChannel(callbackId: callbackId)
    }

    /**
        Unbinds the client from all global callbacks
    */
    open func unbindAll() {
        self.connection.removeAllCallbacksFromGlobalChannel()
    }

    /**
        Disconnects the client's connection
    */
    open func disconnect() {
        self.connection.disconnect()
    }

    /**
        Initiates a connection attempt using the client's existing connection details
    */
    open func connect() {
        self.connection.connect()
    }
}

/**
    Creates a valid URL that can be used in a connection attempt

    - parameter key:     The app key to be inserted into the URL
    - parameter options: The collection of options needed to correctly construct the URL

    - returns: The constructed URL ready to use in a connection attempt
*/
func constructUrl(key: String, options: PusherClientOptions) -> String {
    var url = ""

    if options.encrypted {
        url = "wss://\(options.host):\(options.port)/app/\(key)"
    } else {
        url = "ws://\(options.host):\(options.port)/app/\(key)"
    }
    return "\(url)?client=\(CLIENT_NAME)&version=\(VERSION)&protocol=\(PROTOCOL)"
}
