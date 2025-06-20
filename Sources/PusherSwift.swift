import Foundation
import NWWebSocket

let PROTOCOL = 7
let VERSION = "10.1.6"
// swiftlint:disable:next identifier_name
let CLIENT_NAME = "pusher-websocket-swift"

@objcMembers
@objc open class Pusher: NSObject {
    public let connection: PusherConnection
    open weak var delegate: PusherDelegate? {
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
        let urlString = URL.channelsSocketUrl(key: key, options: options)
        let wsOptions = NWWebSocket.defaultOptions
        wsOptions.setSubprotocols(["pusher-channels-protocol-\(PROTOCOL)"])
        let ws = NWWebSocket(url: URL(string: urlString)!, options: wsOptions)
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
        onMemberAdded: ((PusherPresenceChannelMember) -> Void)? = nil,
        onMemberRemoved: ((PusherPresenceChannelMember) -> Void)? = nil,
        onSubscriptionCountChanged: ((Int) -> Void)? = nil
    ) -> PusherChannel {

        let isEncryptedChannel = PusherChannel.isEncrypted(name: channelName)

        if isEncryptedChannel && auth != nil {
            Logger.shared.warning(for: .authValueOnSubscriptionNotSupported)
        }

        return self.connection.subscribe(
            channelName: channelName,
            auth: auth,
            onMemberAdded: onMemberAdded,
            onMemberRemoved: onMemberRemoved,
            onSubscriptionCountChanged: onSubscriptionCountChanged
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
        onMemberAdded: ((PusherPresenceChannelMember) -> Void)? = nil,
        onMemberRemoved: ((PusherPresenceChannelMember) -> Void)? = nil,
        onSubscriptionCountChanged: ((Int) -> Void)? = nil
    ) -> PusherPresenceChannel {
        return self.connection.subscribeToPresenceChannel(
            channelName: channelName,
            auth: auth,
            onMemberAdded: onMemberAdded,
            onMemberRemoved: onMemberRemoved,
            onSubscriptionCountChanged: onSubscriptionCountChanged
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
