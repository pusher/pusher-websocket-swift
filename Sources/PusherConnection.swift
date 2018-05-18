import Foundation
import Reachability
import Starscream
import CryptoSwift

public typealias PusherEventJSON = [String: AnyObject]

@objcMembers
@objc open class PusherConnection: NSObject {
    open let url: String
    open let key: String
    open var options: PusherClientOptions
    open var globalChannel: GlobalChannel!
    open var socketId: String?
    open var connectionState = ConnectionState.disconnected
    open var channels = PusherChannels()
    open var socket: WebSocket!
    open var URLSession: Foundation.URLSession
    open var userDataFetcher: (() -> PusherPresenceChannelMember)?
    open var reconnectAttemptsMax: Int? = nil
    open var reconnectAttempts: Int = 0
    open var maxReconnectGapInSeconds: Double? = 120
    open weak var delegate: PusherDelegate?
    open var pongResponseTimeoutInterval: TimeInterval = 30
    open var activityTimeoutInterval: TimeInterval
    var reconnectTimer: Timer? = nil
    var pongResponseTimeoutTimer: Timer? = nil
    var activityTimeoutTimer: Timer? = nil
    var intentionalDisconnect: Bool = false

    var socketConnected: Bool = false {
        didSet {
            setConnectionStateToConnectedAndAttemptSubscriptions()
        }
    }
    var connectionEstablishedMessageReceived: Bool = false {
        didSet {
            setConnectionStateToConnectedAndAttemptSubscriptions()
        }
    }

    open lazy var reachability: Reachability? = {
        let reachability = Reachability.init()
        reachability?.whenReachable = { [weak self] reachability in
            guard self != nil else {
                print("Your Pusher instance has probably become deallocated. See https://github.com/pusher/pusher-websocket-swift/issues/109 for more information")
                return
            }

            self!.delegate?.debugLog?(message: "[PUSHER DEBUG] Network reachable")

            switch self!.connectionState {
            case .disconnecting, .connecting, .reconnecting:
                // If in one of these states then part of the connection, reconnection, or explicit
                // disconnection process is underway, so do nothing
                return
            case .disconnected:
                // If already disconnected then reset connection and try to reconnect, provided the
                // state isn't disconnected because of an intentional disconnection
                if !self!.intentionalDisconnect { self!.resetConnectionAndAttemptReconnect() }
                return
            case .connected:
                // If already connected then we assume that there was a missed network event that
                // led to a bad connection so we move to the disconnected state and then attempt
                // reconnection
                self!.delegate?.debugLog?(
                    message: "[PUSHER DEBUG] Connection state is \(self!.connectionState.stringValue()) but received network reachability change so going to call attemptReconnect"
                )
                self!.resetConnectionAndAttemptReconnect()
                return
            }
        }
        reachability?.whenUnreachable = { [weak self] reachability in
            guard self != nil else {
                print("Your Pusher instance has probably become deallocated. See https://github.com/pusher/pusher-websocket-swift/issues/109 for more information")
                return
            }

            self!.delegate?.debugLog?(message: "[PUSHER DEBUG] Network unreachable")
            self!.resetConnectionAndAttemptReconnect()
        }
        return reachability
    }()

    /**
        Initializes a new PusherConnection with an app key, websocket, URL, options and URLSession

        - parameter key:        The Pusher app key
        - parameter socket:     The websocket object
        - parameter url:        The URL the connection is made to
        - parameter options:    A PusherClientOptions instance containing all of the user-speficied
                                client options
        - parameter URLSession: An NSURLSession instance for the connection to use for making
                                authentication requests

        - returns: A new PusherConnection instance
    */
    public init(
        key: String,
        socket: WebSocket,
        url: String,
        options: PusherClientOptions,
        URLSession: Foundation.URLSession = Foundation.URLSession.shared
    ) {
        self.url = url
        self.key = key
        self.options = options
        self.URLSession = URLSession
        self.socket = socket
        self.activityTimeoutInterval = options.activityTimeout ?? 60
        super.init()
        self.socket.delegate = self
        self.socket.pongDelegate = self
    }

    deinit {
        self.reconnectTimer?.invalidate()
        self.activityTimeoutTimer?.invalidate()
        self.pongResponseTimeoutTimer?.invalidate()
    }

    /**
        Initializes a new PusherChannel with a given name

        - parameter channelName:     The name of the channel
        - parameter auth:            A PusherAuth value if subscription is being made to an
                                     authenticated channel without using the default auth methods
        - parameter onMemberAdded:   A function that will be called with information about the
                                     member who has just joined the presence channel
        - parameter onMemberRemoved: A function that will be called with information about the
                                     member who has just left the presence channel

        - returns: A new PusherChannel instance
    */
    internal func subscribe(
        channelName: String,
        auth: PusherAuth? = nil,
        onMemberAdded: ((PusherPresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((PusherPresenceChannelMember) -> ())? = nil
    ) -> PusherChannel {
            let newChannel = channels.add(
                name: channelName,
                connection: self,
                auth: auth,
                onMemberAdded: onMemberAdded,
                onMemberRemoved: onMemberRemoved
            )

            guard self.connectionState == .connected else { return newChannel }

            if !self.authorize(newChannel, auth: auth) {
                print("Unable to subscribe to channel: \(newChannel.name)")
            }

            return newChannel
    }

    /**
        Initializes a new PusherChannel with a given name

        - parameter channelName:     The name of the channel
        - parameter auth:            A PusherAuth value if subscription is being made to an
                                     authenticated channel without using the default auth methods
        - parameter onMemberAdded:   A function that will be called with information about the
        member who has just joined the presence channel
        - parameter onMemberRemoved: A function that will be called with information about the
        member who has just left the presence channel

        - returns: A new PusherChannel instance
    */
    internal func subscribeToPresenceChannel(
        channelName: String,
        auth: PusherAuth? = nil,
        onMemberAdded: ((PusherPresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((PusherPresenceChannelMember) -> ())? = nil
    ) -> PusherPresenceChannel {
        let newChannel = channels.addPresence(
            channelName: channelName,
            connection: self,
            auth: auth,
            onMemberAdded: onMemberAdded,
            onMemberRemoved: onMemberRemoved
        )

        guard self.connectionState == .connected else { return newChannel }

        if !self.authorize(newChannel, auth: auth) {
            print("Unable to subscribe to channel: \(newChannel.name)")
        }

        return newChannel
    }

    /**
        Unsubscribes from a PusherChannel with a given name

        - parameter channelName: The name of the channel
    */
    internal func unsubscribe(channelName: String) {
        if let chan = self.channels.find(name: channelName), chan.subscribed {
            self.sendEvent(event: "pusher:unsubscribe",
                data: [
                    "channel": channelName
                ] as [String : Any]
            )
            self.channels.remove(name: channelName)
        }
    }
    
    /**
        Unsubscribes from all PusherChannels
    */
    internal func unsubscribeAll() {
        for (_, channel) in channels.channels {
            unsubscribe(channelName: channel.name)
        }
    }

    /**
        Either writes a string directly to the websocket with the given event name
        and data, or calls a client event to be sent if the event is prefixed with
        "client"

        - parameter event:       The name of the event
        - parameter data:        The data to be stringified and sent
        - parameter channelName: The name of the channel
    */
    open func sendEvent(event: String, data: Any, channel: PusherChannel? = nil) {
        if event.components(separatedBy: "-")[0] == "client" {
            sendClientEvent(event: event, data: data, channel: channel)
        } else {
            let dataString = JSONStringify(["event": event, "data": data])
            self.delegate?.debugLog?(message: "[PUSHER DEBUG] sendEvent \(dataString)")
            self.socket.write(string: dataString)
        }
    }

    /**
        Sends a client event with the given event, data, and channel name

        - parameter event:       The name of the event
        - parameter data:        The data to be stringified and sent
        - parameter channelName: The name of the channel
    */
    fileprivate func sendClientEvent(event: String, data: Any, channel: PusherChannel?) {
        if let channel = channel {
            if channel.type == .presence || channel.type == .private {
                let dataString = JSONStringify(["event": event, "data": data, "channel": channel.name] as [String : Any])
                self.delegate?.debugLog?(message: "[PUSHER DEBUG] sendClientEvent \(dataString)")
                self.socket.write(string: dataString)
            } else {
                print("You must be subscribed to a private or presence channel to send client events")
            }
        }
    }

    /**
        JSON stringifies an object

        - parameter value: The value to be JSON stringified

        - returns: A JSON-stringified version of the value
    */
    fileprivate func JSONStringify(_ value: Any) -> String {
        if JSONSerialization.isValidJSONObject(value) {
            do {
                let data = try JSONSerialization.data(withJSONObject: value, options: [])
                let string = String(data: data, encoding: .utf8)
                if string != nil {
                    return string!
                }
            } catch _ {
            }
        }
        return ""
    }

    /**
        Disconnects the websocket
    */
    open func disconnect() {
        if self.connectionState == .connected {
            intentionalDisconnect = true
            self.reachability?.stopNotifier()
            updateConnectionState(to: .disconnecting)
            self.socket.disconnect()
        }
    }

    /**
        Establish a websocket connection
    */
    @objc open func connect() {
        // reset the intentional disconnect state
        intentionalDisconnect = false

        if self.connectionState == .connected {
            return
        } else {
            updateConnectionState(to: .connecting)
            self.socket.connect()
            if self.options.autoReconnect {
                // can call this multiple times and only one notifier will be started
                _ = try? reachability?.startNotifier()
            }
        }
    }

    /**
        Instantiate a new GloblalChannel instance for the connection
    */
    internal func createGlobalChannel() {
        self.globalChannel = GlobalChannel(connection: self)
    }

    /**
        Add callback to the connection's global channel

        - parameter callback: The callback to be stored

        - returns: A callbackId that can be used to remove the callback from the connection
    */
    internal func addCallbackToGlobalChannel(_ callback: @escaping (Any?) -> Void) -> String {
        return globalChannel.bind(callback)
    }

    /**
        Remove the callback with id of callbackId from the connection's global channel

        - parameter callbackId: The unique string representing the callback to be removed
    */
    internal func removeCallbackFromGlobalChannel(callbackId: String) {
        globalChannel.unbind(callbackId: callbackId)
    }

    /**
        Remove all callbacks from the connection's global channel
    */
    internal func removeAllCallbacksFromGlobalChannel() {
        globalChannel.unbindAll()
    }

    /**
        Set the connection state and call the stateChangeDelegate, if set

        - parameter newState: The new ConnectionState value
    */
    internal func updateConnectionState(to newState: ConnectionState) {
        let oldState = self.connectionState
        self.connectionState = newState
        self.delegate?.changedConnectionState?(from: oldState, to: newState)
    }

    /**
        Update connection state and attempt subscriptions to unsubscribed channels
    */
    fileprivate func setConnectionStateToConnectedAndAttemptSubscriptions() {
        if self.connectionEstablishedMessageReceived &&
           self.socketConnected &&
           self.connectionState != .connected
        {
            updateConnectionState(to: .connected)
            attemptSubscriptionsToUnsubscribedChannels()
        }
    }

    /**
        Set the connection state to disconnected, mark channels as unsubscribed,
        reset connection-related state to initial state, and initiate reconnect
        process
    */
    fileprivate func resetConnectionAndAttemptReconnect() {
        if connectionState != .disconnected {
            updateConnectionState(to: .disconnected)
        }

        for (_, channel) in self.channels.channels {
            channel.subscribed = false
        }

        cleanUpActivityAndPongResponseTimeoutTimers()

        socketConnected = false
        connectionEstablishedMessageReceived = false
        socketId = nil

        attemptReconnect()
    }

    /**
        Reset the activity timeout timer
    */
    func resetActivityTimeoutTimer() {
        cleanUpActivityAndPongResponseTimeoutTimers()
        establishActivityTimeoutTimer()
    }

    /**
        Clean up the activity timeout and pong response timers
    */
    func cleanUpActivityAndPongResponseTimeoutTimers() {
        activityTimeoutTimer?.invalidate()
        activityTimeoutTimer = nil
        pongResponseTimeoutTimer?.invalidate()
        pongResponseTimeoutTimer = nil
    }

    /**
        Schedule a timer to be fired if no activity occurs over the socket within
        the activityTimeoutInterval
    */
    fileprivate func establishActivityTimeoutTimer() {
        self.activityTimeoutTimer = Timer.scheduledTimer(
            timeInterval: self.activityTimeoutInterval,
            target: self,
            selector: #selector(self.sendPing),
            userInfo: nil,
            repeats: false
        )
    }

    /**
        Send a ping to the server
    */
    @objc fileprivate func sendPing() {
        socket.write(ping: Data()) {
            self.delegate?.debugLog?(message: "[PUSHER DEBUG] Ping sent")
            self.setupPongResponseTimeoutTimer()
        }
    }

    /**
        Schedule a timer that will fire if no pong response is received within the
        pongResponseTImeoutInterval
    */
    fileprivate func setupPongResponseTimeoutTimer() {
        pongResponseTimeoutTimer = Timer.scheduledTimer(
            timeInterval: pongResponseTimeoutInterval,
            target: self,
            selector: #selector(cleanupAfterNoPongResponse),
            userInfo: nil,
            repeats: false
        )
    }

    /**
        Invalidate the pongResponseTimeoutTimer and set connection state to disconnected
        as well as marking channels as unsubscribed
    */
    @objc fileprivate func cleanupAfterNoPongResponse() {
        pongResponseTimeoutTimer?.invalidate()
        pongResponseTimeoutTimer = nil
        resetConnectionAndAttemptReconnect()
    }

    /**
        Handle setting channel state and triggering unsent client events, if applicable,
        upon receiving a successful subscription event

        - parameter json: The PusherEventJSON containing successful subscription data
    */
    fileprivate func handleSubscriptionSucceededEvent(json: PusherEventJSON) {
        if let channelName = json["channel"] as? String, let chan = self.channels.find(name: channelName) {
            chan.subscribed = true

            guard let eventData = json["data"] as? String else {
                self.delegate?.debugLog?(message: "[PUSHER DEBUG] Subscription succeeded event received without data key in payload")
                return
            }

            if PusherChannelType.isPresenceChannel(name: channelName) {
                if let presChan = self.channels.find(name: channelName) as? PusherPresenceChannel {
                    if let dataJSON = getPusherEventJSON(from: eventData) {
                        if let presenceData = dataJSON["presence"] as? [String : AnyObject],
                           let presenceHash = presenceData["hash"] as? [String : AnyObject]
                        {
                            presChan.addExistingMembers(memberHash: presenceHash)
                        }
                    }
                }
            }

            callGlobalCallbacks(forEvent: "pusher:subscription_succeeded", jsonObject: json)
            chan.handleEvent(name: "pusher:subscription_succeeded", data: eventData)

            self.delegate?.subscribedToChannel?(name: channelName)

            chan.auth = nil

            while chan.unsentEvents.count > 0 {
                if let pusherEvent = chan.unsentEvents.popLast() {
                    chan.trigger(eventName: pusherEvent.name, data: pusherEvent.data)
                }
            }
        }
    }

    /**
        Handle setting connection state and making subscriptions that couldn't be
        attempted while the connection was not in a connected state

        - parameter json: The PusherEventJSON containing connection established data
    */
    fileprivate func handleConnectionEstablishedEvent(json: PusherEventJSON) {
        if let data = json["data"] as? String {
            if let connectionData = getPusherEventJSON(from: data),
               let socketId = connectionData["socket_id"] as? String
            {
                self.socketId = socketId
                self.delegate?.debugLog?(message: "[PUSHER DEBUG] Socket established with socket ID: \(socketId)")
                self.reconnectAttempts = 0
                self.reconnectTimer?.invalidate()

                if options.activityTimeout == nil, let activityTimeoutFromServer = connectionData["activity_timeout"] as? TimeInterval {
                    self.activityTimeoutInterval = activityTimeoutFromServer
                }

                self.connectionEstablishedMessageReceived = true
            }
        }
    }

    /**
        Attempts to make subscriptions that couldn't be attempted while the
        connection was not in a connected state
    */
    fileprivate func attemptSubscriptionsToUnsubscribedChannels() {
        for (_, channel) in self.channels.channels {
            if !self.authorize(channel, auth: channel.auth) {
                print("Unable to subscribe to channel: \(channel.name)")
            }
        }
    }

    /**
        Handle a new member subscribing to a presence channel

        - parameter json: The PusherEventJSON containing the member data
    */
    fileprivate func handleMemberAddedEvent(json: PusherEventJSON) {
        if let data = json["data"] as? String {
            if let channelName = json["channel"] as? String, let chan = self.channels.find(name: channelName) as? PusherPresenceChannel {
                if let memberJSON = getPusherEventJSON(from: data) {
                    chan.addMember(memberJSON: memberJSON)
                } else {
                    print("Unable to add member")
                }
            }
        }
    }

    /**
        Handle a member unsubscribing from a presence channel

        - parameter json: The PusherEventJSON containing the member data
    */
    fileprivate func handleMemberRemovedEvent(json: PusherEventJSON) {
        if let data = json["data"] as? String {
            if let channelName = json["channel"] as? String, let chan = self.channels.find(name: channelName) as? PusherPresenceChannel {
                if let memberJSON = getPusherEventJSON(from: data) {
                    chan.removeMember(memberJSON: memberJSON)
                } else {
                    print("Unable to remove member")
                }
            }
        }
    }

    /**
        Handle failure of our auth endpoint

        - parameter channelName: The name of channel for which authorization failed
        - parameter data:        The error returned by the auth endpoint
    */
    fileprivate func handleAuthorizationError(forChannel channelName: String, response: URLResponse?, data: String?, error: NSError?) {
        let eventName = "pusher:subscription_error"
        let json = [
            "event": eventName,
            "channel": channelName,
            "data": data ?? ""
        ]
        DispatchQueue.main.async {
            // TODO: Consider removing in favour of exclusively using delegate
            self.handleEvent(eventName: eventName, jsonObject: json as [String : AnyObject])
        }

        self.delegate?.failedToSubscribeToChannel?(name: channelName, response: response, data: data, error: error)
    }

    /**
        Parse a string to extract Pusher event information from it

        - parameter string: The string received over the websocket connection containing
                            Pusher event information

        - returns: A dictionary of Pusher-relevant event data
    */
    open func getPusherEventJSON(from string: String) -> [String : AnyObject]? {
        let data = (string as NSString).data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)

        do {
            if let jsonData = data, let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : AnyObject] {
                return jsonObject
            } else {
                print("Unable to parse string from WebSocket: \(string)")
            }
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
        return nil
    }

    /**
        Parse a string to extract Pusher event data from it

        - parameter string: The data string received as part of a Pusher message

        - returns: The object sent as the payload part of the Pusher message
    */
    open func getEventDataJSON(from string: String) -> Any {
        let data = (string as NSString).data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)

        do {
            if let jsonData = data, let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) {
                return jsonObject
            } else {
                print("Returning data string instead because unable to parse string as JSON - check that your JSON is valid.")
            }
        }
        return string
    }

    /**
        Handles incoming events and passes them on to be handled by the appropriate function

        - parameter eventName:  The name of the incoming event
        - parameter jsonObject: The event-specific data related to the incoming event
    */
    open func handleEvent(eventName: String, jsonObject: [String : AnyObject]) {
        resetActivityTimeoutTimer()
        switch eventName {
        case "pusher_internal:subscription_succeeded":
            handleSubscriptionSucceededEvent(json: jsonObject)
        case "pusher:connection_established":
            handleConnectionEstablishedEvent(json: jsonObject)
        case "pusher_internal:member_added":
            handleMemberAddedEvent(json: jsonObject)
        case "pusher_internal:member_removed":
            handleMemberRemovedEvent(json: jsonObject)
        default:
            callGlobalCallbacks(forEvent: eventName, jsonObject: jsonObject)
            if let channelName = jsonObject["channel"] as? String, let internalChannel = self.channels.find(name: channelName) {
                if let eName = jsonObject["event"] as? String, let eData = jsonObject["data"] as? String {
                    internalChannel.handleEvent(name: eName, data: eData)
                }
            }
        }
    }

    /**
        Call any global callbacks

        - parameter eventName:  The name of the incoming event
        - parameter jsonObject: The event-specific data related to the incoming event
    */
    fileprivate func callGlobalCallbacks(forEvent eventName: String, jsonObject: [String : AnyObject]) {
        if let globalChannel = self.globalChannel {
            if let eData =  jsonObject["data"] as? String {
                let channelName = jsonObject["channel"] as! String?
                globalChannel.handleEvent(name: eventName, data: eData, channelName: channelName)
            } else if let eData =  jsonObject["data"] as? [String: AnyObject] {
                globalChannel.handleErrorEvent(name: eventName, data: eData)
            }
        }
    }

    /**
        Uses the appropriate authentication method to authenticate subscriptions to private and
        presence channels

        - parameter channel: The PusherChannel to authenticate
        - parameter auth:    A PusherAuth value if subscription is being made to an
                             authenticated channel without using the default auth methods

        - returns: A Bool indicating whether or not the authentication request was made
                   successfully
    */
    fileprivate func authorize(_ channel: PusherChannel, auth: PusherAuth? = nil) -> Bool {
        if channel.type != .presence && channel.type != .private {
            subscribeToNormalChannel(channel)
            return true
        } else if let auth = auth {
            // Don't go through normal auth flow if auth value provided
            if channel.type == .private {
                self.handlePrivateChannelAuth(authValue: auth.auth, channel: channel)
            } else if let channelData = auth.channelData {
                self.handlePresenceChannelAuth(authValue: auth.auth, channel: channel, channelData: channelData)
            } else {
                self.delegate?.debugLog?(message: "[PUSHER DEBUG] Attempting to subscribe to presence channel but no channelData value provided")
                return false
            }

            return true
        } else {
            guard let socketId = self.socketId else {
                print("socketId value not found. You may not be connected.")
                return false
            }

            switch self.options.authMethod {
            case .noMethod:
                let errorMessage = "Authentication method required for private / presence channels but none provided."
                let error = NSError(domain: "com.pusher.PusherSwift", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey: errorMessage])

                print(errorMessage)

                handleAuthorizationError(forChannel: channel.name, response: nil, data: nil, error: error)

                return false
            case .endpoint(authEndpoint: let authEndpoint):
                let request = requestForAuthValue(from: authEndpoint, socketId: socketId, channelName: channel.name)
                sendAuthorisationRequest(request: request, channel: channel)
                return true
            case .authRequestBuilder(authRequestBuilder: let builder):
                if let request = builder.requestFor?(socketID: socketId, channelName: channel.name) {
                    sendAuthorisationRequest(request: request, channel: channel)

                    return true
                } else {
                    let errorMessage = "Authentication request could not be built"
                    let error = NSError(domain: "com.pusher.PusherSwift", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey: errorMessage])

                    handleAuthorizationError(forChannel: channel.name, response: nil, data: nil, error: error)

                    return false
                }
            case .authorizer(authorizer: let authorizer):
                authorizer.fetchAuthValue(socketID: socketId, channelName: channel.name) { authInfo in
                    guard let authInfo = authInfo else {
                        print("Auth info passed to authorizer completionHandler was nil so channel subscription failed")
                        return
                    }

                    self.handleAuthInfo(authString: authInfo.auth, channelData: authInfo.channelData, channel: channel)
                }

                return true
            case .inline(secret: let secret):
                var msg = ""
                var channelData = ""
                if channel.type == .presence {
                    channelData = getUserDataJSON()
                    msg = "\(self.socketId!):\(channel.name):\(channelData)"
                } else {
                    msg = "\(self.socketId!):\(channel.name)"
                }

                let secretBuff: [UInt8] = Array(secret.utf8)
                let msgBuff: [UInt8] = Array(msg.utf8)

                if let hmac = try? HMAC(key: secretBuff, variant: .sha256).authenticate(msgBuff) {
                    let signature = Data(bytes: hmac).toHexString()
                    let auth = "\(self.key):\(signature)".lowercased()

                    if channel.type == .private {
                        self.handlePrivateChannelAuth(authValue: auth, channel: channel)
                    } else {
                        self.handlePresenceChannelAuth(authValue: auth, channel: channel, channelData: channelData)
                    }
                }

                return true
            }
        }
    }

    /**
        Calls the provided userDataFetcher function, if provided, otherwise will
        use the socketId as the user_id and return that stringified

        - returns: A JSON stringified user data object
    */
    fileprivate func getUserDataJSON() -> String {
        if let userDataFetcher = self.userDataFetcher {
            let userData = userDataFetcher()
            if let userInfo: Any = userData.userInfo {
                return JSONStringify(["user_id": userData.userId, "user_info": userInfo])
            } else {
                return JSONStringify(["user_id": userData.userId])
            }
        } else {
            if let socketId = self.socketId {
                return JSONStringify(["user_id": socketId])
            } else {
                print("Authentication failed. You may not be connected")
                return ""
            }
        }
    }

    /**
        Send subscription event for subscribing to a public channel

        - parameter channel:  The PusherChannel to subscribe to
    */
    fileprivate func subscribeToNormalChannel(_ channel: PusherChannel) {
        self.sendEvent(
            event: "pusher:subscribe",
            data: [
                "channel": channel.name
            ]
        )
    }

    /**
     Creates an authentication request for the given authEndpoint

        - parameter endpoint: The authEndpoint to which the request will be made
        - parameter socketId: The socketId of the connection's websocket
        - parameter channel:  The PusherChannel to authenticate subsciption for

        - returns: URLRequest object to be used by the function making the auth request
    */
    fileprivate func requestForAuthValue(from endpoint: String, socketId: String, channelName: String) -> URLRequest {
        let allowedCharacterSet = CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[] ").inverted
        let encodedChannelName = channelName.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? channelName

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.httpBody = "socket_id=\(socketId)&channel_name=\(encodedChannelName)".data(using: String.Encoding.utf8)

        return request
    }

    /**
        Send authentication request to the authEndpoint specified

        - parameter request: The request to send
        - parameter channel: The PusherChannel to authenticate subsciption for
    */
    fileprivate func sendAuthorisationRequest(request: URLRequest, channel: PusherChannel) {
        let task = URLSession.dataTask(with: request, completionHandler: { data, response, sessionError in
            if let error = sessionError {
                print("Error authorizing channel [\(channel.name)]: \(error)")
                self.handleAuthorizationError(forChannel: channel.name, response: response, data: nil, error: error as NSError?)
                return
            }

            guard let data = data else {
                print("Error authorizing channel [\(channel.name)]")
                self.handleAuthorizationError(forChannel: channel.name, response: response, data: nil, error: nil)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) else {
                let dataString = String(data: data, encoding: String.Encoding.utf8)
                print ("Error authorizing channel [\(channel.name)]: \(String(describing: dataString))")
                self.handleAuthorizationError(forChannel: channel.name, response: response, data: dataString, error: nil)
                return
            }

            guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []), let json = jsonObject as? [String: AnyObject] else {
                print("Error authorizing channel [\(channel.name)]")
                self.handleAuthorizationError(forChannel: channel.name, response: httpResponse, data: nil, error: nil)
                return
            }

            self.handleAuthResponse(json: json, channel: channel)
        })

        task.resume()
    }

    /**
        Handle authorizer request response and call appropriate handle function

        - parameter json:    The auth response as a dictionary
        - parameter channel: The PusherChannel to authorize subsciption for
    */
    fileprivate func handleAuthResponse(
        json: [String: AnyObject],
        channel: PusherChannel
    ) {
        if let auth = json["auth"] as? String {
            handleAuthInfo(
                authString: auth,
                channelData: json["channel_data"] as? String,
                channel: channel
            )
        }
    }

    /**
        Handle authorizer info and call appropriate handle function

        - parameter authString:  The auth response as a dictionary
        - parameter channelData: The channelData to send along with the auth request
        - parameter channel:     The PusherChannel to authorize the subsciption for
    */
    fileprivate func handleAuthInfo(authString: String, channelData: String?, channel: PusherChannel) {
        if let channelData = channelData {
            handlePresenceChannelAuth(authValue: authString, channel: channel, channelData: channelData)
        } else {
            handlePrivateChannelAuth(authValue: authString, channel: channel)
        }
    }

    /**
        Handle presence channel auth response and send subscribe message to Pusher API

        - parameter auth:        The auth string
        - parameter channel:     The PusherChannel to authorize subsciption for
        - parameter channelData: The channelData to send along with the auth request
    */
    fileprivate func handlePresenceChannelAuth(
        authValue: String,
        channel: PusherChannel,
        channelData: String
    ) {
        (channel as? PusherPresenceChannel)?.setMyUserId(channelData: channelData)

        self.sendEvent(
            event: "pusher:subscribe",
            data: [
                "channel": channel.name,
                "auth": authValue,
                "channel_data": channelData
            ]
        )
    }

    /**
        Handle private channel auth response and send subscribe message to Pusher API

        - parameter auth:    The auth string
        - parameter channel: The PusherChannel to authenticate subsciption for
    */
    fileprivate func handlePrivateChannelAuth(authValue auth: String, channel: PusherChannel) {
        self.sendEvent(
            event: "pusher:subscribe",
            data: [
                "channel": channel.name,
                "auth": auth
            ]
        )
    }
}

@objc public class PusherAuth: NSObject {
    public let auth: String
    public let channelData: String?

    public init(auth: String, channelData: String? = nil) {
        self.auth = auth
        self.channelData = channelData
    }
}

@objc public enum ConnectionState: Int {
    case connecting
    case connected
    case disconnecting
    case disconnected
    case reconnecting

    static let connectionStates = [
        connecting: "connecting",
        connected: "connected",
        disconnecting: "disconnecting",
        disconnected: "disconnected",
        reconnecting: "reconnecting",
    ]

    public func stringValue() -> String {
        return ConnectionState.connectionStates[self]!
    }
}
