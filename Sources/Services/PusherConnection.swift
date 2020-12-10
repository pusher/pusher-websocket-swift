import Foundation
import NWWebSocket

// swiftlint:disable file_length type_body_length

@objcMembers
@objc open class PusherConnection: NSObject {
    public let url: String
    public let key: String
    open var options: PusherClientOptions
    open var globalChannel: GlobalChannel!
    open var socketId: String?
    open var connectionState = ConnectionState.disconnected
    open var channels = PusherChannels()
    open var socket: NWWebSocket!
    open var URLSession: Foundation.URLSession
    open var userDataFetcher: (() -> PusherPresenceChannelMember)?
    open var reconnectAttemptsMax: Int?
    open var reconnectAttempts: Int = 0
    open var maxReconnectGapInSeconds: Double? = 120
    open weak var delegate: PusherDelegate?
    open var pongResponseTimeoutInterval: TimeInterval = 30
    open var activityTimeoutInterval: TimeInterval
    var reconnectTimer: Timer?
    var pongResponseTimeoutTimer: Timer?
    var activityTimeoutTimer: Timer?
    var intentionalDisconnect: Bool = false

    var eventQueue: PusherEventQueue
    var eventFactory: PusherEventFactory

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

    /**
        Initializes a new PusherConnection with an app key, websocket, URL, options and URLSession

        - parameter key:        The Pusher app key
        - parameter socket:     The websocket object
        - parameter url:        The URL the connection is made to
        - parameter options:    A PusherClientOptions instance containing all of the user-specified
                                client options
        - parameter URLSession: An NSURLSession instance for the connection to use for making
                                authentication requests

        - returns: A new PusherConnection instance
    */
    public init(
        key: String,
        socket: NWWebSocket,
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

        self.eventFactory = PusherConcreteEventFactory()
        self.eventQueue = PusherConcreteEventQueue(eventFactory: eventFactory, channels: channels)

        super.init()

        self.eventQueue.delegate = self
        self.socket.delegate = self
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
        onMemberAdded: ((PusherPresenceChannelMember) -> Void)? = nil,
        onMemberRemoved: ((PusherPresenceChannelMember) -> Void)? = nil
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
        onMemberAdded: ((PusherPresenceChannelMember) -> Void)? = nil,
        onMemberRemoved: ((PusherPresenceChannelMember) -> Void)? = nil
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
            self.sendEvent(event: Constants.Events.Pusher.unsubscribe,
                data: [
                    Constants.JSONKeys.channel: channelName
                ] as [String: Any]
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

        - parameter event:   The name of the event
        - parameter data:    The data to be stringified and sent
        - parameter channel: The name of the channel
    */
    open func sendEvent(event: String, data: Any, channel: PusherChannel? = nil) {
        if event.components(separatedBy: "-")[0] == Constants.EventTypes.client {
            sendClientEvent(event: event, data: data, channel: channel)
        } else {
            let dataString = JSONStringify([Constants.JSONKeys.event: event,
                                            Constants.JSONKeys.data: data])
            self.delegate?.debugLog?(message: PusherLogger.debug(for: .eventSent,
                                                                 context: dataString))
            self.socket.send(string: dataString)
        }
    }

    /**
        Sends a client event with the given event, data, and channel name

        - parameter event:   The name of the event
        - parameter data:    The data to be stringified and sent
        - parameter channel: The name of the channel
    */
    fileprivate func sendClientEvent(event: String, data: Any, channel: PusherChannel?) {
        if let channel = channel {
            if channel.type == .presence || channel.type == .private {
                let dataString = JSONStringify([Constants.JSONKeys.event: event,
                                                Constants.JSONKeys.data: data,
                                                Constants.JSONKeys.channel: channel.name] as [String: Any])
                self.delegate?.debugLog?(message: PusherLogger.debug(for: .clientEventSent,
                                                                     context: dataString))
                self.socket.send(string: dataString)
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
            updateConnectionState(to: .disconnecting)
            self.socket.disconnect()
        }
    }

    /**
        Establish a websocket connection
    */
    open func connect() {
        // reset the intentional disconnect state
        intentionalDisconnect = false

        if self.connectionState == .connected {
            return
        } else {
            updateConnectionState(to: .connecting)
            self.socket.connect()
        }
    }

    /**
        Instantiate a new GlobalChannel instance for the connection
    */
    internal func createGlobalChannel() {
        self.globalChannel = GlobalChannel(connection: self)
    }

    /**
        Add callback to the connection's global channel

        - parameter callback: The callback to be stored

        - returns: A callbackId that can be used to remove the callback from the connection
    */
    internal func addCallbackToGlobalChannel(_ callback: @escaping (PusherEvent) -> Void) -> String {
        return globalChannel.bind(callback)
    }

    /**
     Add legacy callback to the connection's global channel

     - parameter callback: The callback to be stored

     - returns: A callbackId that can be used to remove the callback from the connection
     */
    internal func addLegacyCallbackToGlobalChannel(_ callback: @escaping (Any?) -> Void) -> String {
        return globalChannel.bindLegacy(callback)
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
           self.connectionState != .connected {
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
        socket.ping()
        self.delegate?.debugLog?(message: PusherLogger.debug(for: .pingSent))
        self.setupPongResponseTimeoutTimer()
    }

    /**
        Schedule a timer that will fire if no pong response is received within the
        pongResponseTimeoutInterval
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
    fileprivate func handleSubscriptionSucceededEvent(event: PusherEvent) {
        if let channelName = event.channelName, let chan = self.channels.find(name: channelName) {
            chan.subscribed = true

            guard event.data != nil else {
                self.delegate?.debugLog?(message: PusherLogger.debug(for: .subscriptionSucceededNoDataInPayload))
                return
            }

            if PusherChannelType.isPresenceChannel(name: channelName) {
                if let presChan = self.channels.find(name: channelName) as? PusherPresenceChannel {
                    if let dataJSON = event.dataToJSONObject() as? [String: Any],
                        let presenceData = dataJSON[Constants.JSONKeys.presence] as? [String: AnyObject],
                        let presenceHash = presenceData[Constants.JSONKeys.hash] as? [String: AnyObject] {
                        presChan.addExistingMembers(memberHash: presenceHash)
                    }
                }
            }

            let subscriptionEvent = event.copy(withEventName: Constants.Events.Pusher.subscriptionSucceeded)
            callGlobalCallbacks(event: subscriptionEvent)
            chan.handleEvent(event: subscriptionEvent)

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

        - parameter event: The event to be processed
    */
    fileprivate func handleConnectionEstablishedEvent(event: PusherEvent) {
        if let connectionData = event.dataToJSONObject() as? [String: Any],
            let socketId = connectionData[Constants.JSONKeys.socketId] as? String {
            self.socketId = socketId
            self.delegate?.debugLog?(message: PusherLogger.debug(for: .connectionEstablished,
                                                                 context: socketId))
            self.reconnectAttempts = 0
            self.reconnectTimer?.invalidate()

            if options.activityTimeout == nil,
                let activityTimeoutFromServer = connectionData["activity_timeout"] as? TimeInterval {
                self.activityTimeoutInterval = activityTimeoutFromServer
            }

            self.connectionEstablishedMessageReceived = true
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

        - parameter event: The event to be processed
    */
    fileprivate func handleMemberAddedEvent(event: PusherEvent) {
        if let channelName = event.channelName,
            let chan = self.channels.find(name: channelName) as? PusherPresenceChannel {
            if let memberJSON = event.dataToJSONObject() as? [String: Any] {
                chan.addMember(memberJSON: memberJSON)
            } else {
                print("Unable to add member")
            }
        }
    }

    /**
        Handle a member unsubscribing from a presence channel

        - parameter event: The event to be processed
    */
    fileprivate func handleMemberRemovedEvent(event: PusherEvent) {
        if let channelName = event.channelName,
            let chan = self.channels.find(name: channelName) as? PusherPresenceChannel {
            if let memberJSON = event.dataToJSONObject() as? [String: Any] {
                chan.removeMember(memberJSON: memberJSON)
            } else {
                print("Unable to remove member")
            }
        }
    }

    /**
     Handles incoming error

     - parameter error: The incoming error to be processed
     */
    open func handleError(error: PusherError) {
        resetActivityTimeoutTimer()
        self.delegate?.receivedError?(error: error)
        self.globalChannel?.handleGlobalEventLegacy(event: error.raw)
    }

    /**
        Handle failure of our auth endpoint

        - parameter channelName: The name of channel for which authorization failed
        - parameter data:        The error returned by the auth endpoint
    */
    fileprivate func handleAuthorizationError(forChannel channelName: String, error: PusherAuthError) {
        let eventName = Constants.Events.Pusher.subscriptionError
        let json = [
            Constants.JSONKeys.event: eventName,
            Constants.JSONKeys.channel: channelName,
            Constants.JSONKeys.data: error.data ?? ""
        ]
        if let event = try? self.eventFactory.makeEvent(fromJSON: json, withDecryptionKey: nil) {
            DispatchQueue.main.async {
                // TODO: Consider removing in favour of exclusively using delegate
                self.handleEvent(event: event)
            }

            if let message = error.message {
                print(message)
            }
            self.delegate?.failedToSubscribeToChannel?(name: channelName,
                                                       response: error.response,
                                                       data: error.data,
                                                       error: error.error)
        }
    }

    /**
        Handles incoming events and passes them on to be handled by the appropriate function

        - parameter event: The incoming event to be processed
    */
    open func handleEvent(event: PusherEvent) {
        resetActivityTimeoutTimer()
        switch event.eventName {
        case Constants.Events.PusherInternal.subscriptionSucceeded:
            handleSubscriptionSucceededEvent(event: event)
        case Constants.Events.Pusher.connectionEstablished:
            handleConnectionEstablishedEvent(event: event)
        case Constants.Events.PusherInternal.memberAdded:
            handleMemberAddedEvent(event: event)
        case Constants.Events.PusherInternal.memberRemoved:
            handleMemberRemovedEvent(event: event)
        default:
            callGlobalCallbacks(event: event)
            if let channelName = event.channelName, let internalChannel = self.channels.find(name: channelName) {
                internalChannel.handleEvent(event: event)
            }
        }
    }

    /**
        Call any global callbacks

        - parameter event: The incoming event
    */
    fileprivate func callGlobalCallbacks(event: PusherEvent) {
        globalChannel?.handleGlobalEvent(event: event)
        globalChannel?.handleGlobalEventLegacy(event: event.raw)
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
                self.delegate?.debugLog?(message: PusherLogger.debug(for: .presenceChannelSubscriptionAttemptWithoutChannelData))
                return false
            }
            return true
        } else {
            return requestPusherAuthFromAuthMethod(channel: channel) { [weak self] pusherAuth, error in
                if let error = error {
                    self?.handleAuthorizationError(forChannel: channel.name, error: error)
                } else if let pusherAuth = pusherAuth {
                    self?.handleAuthInfo(pusherAuth: pusherAuth, channel: channel)
                }
            }
        }
    }

    fileprivate func requestPusherAuthFromAuthMethod(channel: PusherChannel,
                                                     completionHandler: @escaping (PusherAuth?, PusherAuthError?) -> Void) -> Bool {
        guard let socketId = self.socketId else {
            let message = "socketId value not found. You may not be connected."
            completionHandler(nil, PusherAuthError(kind: .notConnected, message: message))
            return false
        }

        switch self.options.authMethod {
        case .noMethod:
            let errorMessage = "Authentication method required for private / presence channels but none provided."
            let error = NSError(domain: "com.pusher.PusherSwift",
                                code: 0,
                                userInfo: [NSLocalizedFailureReasonErrorKey: errorMessage])
            completionHandler(nil, PusherAuthError(kind: .noMethod, message: errorMessage, error: error))
            return false
        case .endpoint(authEndpoint: let authEndpoint):
            let request = requestForAuthValue(from: authEndpoint, socketId: socketId, channelName: channel.name)
            sendAuthorizationRequest(request: request, channel: channel, completionHandler: completionHandler)
            return true
        case .authRequestBuilder(authRequestBuilder: let builder):
            if let request = builder.requestFor?(socketID: socketId, channelName: channel.name) {
                sendAuthorizationRequest(request: request, channel: channel, completionHandler: completionHandler)
                return true
            } else {
                let errorMessage = "Authentication request could not be built"
                let error = NSError(domain: "com.pusher.PusherSwift",
                                    code: 0,
                                    userInfo: [NSLocalizedFailureReasonErrorKey: errorMessage])
                completionHandler(nil, PusherAuthError(kind: .couldNotBuildRequest,
                                                       message: errorMessage,
                                                       error: error))
                return false
            }
        case .authorizer(authorizer: let authorizer):
            authorizer.fetchAuthValue(socketID: socketId, channelName: channel.name) { pusherAuth in
                if pusherAuth == nil {
                    print("Auth info passed to authorizer completionHandler was nil")
                }
                completionHandler(pusherAuth, nil)
            }
            return true
        case .inline(secret: let secret):
            var message = ""
            var channelData = ""
            if channel.type == .presence {
                channelData = getUserDataJSON()
                message = "\(self.socketId!):\(channel.name):\(channelData)"
            } else {
                message = "\(self.socketId!):\(channel.name)"
            }

            let signature = PusherCrypto.generateSHA256HMAC(secret: secret, message: message)
            let auth = "\(self.key):\(signature)".lowercased()

            var pusherAuth: PusherAuth

            if channel.type == .private {
                pusherAuth = PusherAuth(auth: auth)
            } else {
                pusherAuth = PusherAuth(auth: auth, channelData: channelData)
            }

            completionHandler(pusherAuth, nil)
            return true
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
                return JSONStringify([Constants.JSONKeys.userId: userData.userId,
                                      Constants.JSONKeys.userInfo: userInfo])
            } else {
                return JSONStringify([Constants.JSONKeys.userId: userData.userId])
            }
        } else {
            if let socketId = self.socketId {
                return JSONStringify([Constants.JSONKeys.userId: socketId])
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
            event: Constants.Events.Pusher.subscribe,
            data: [
                Constants.JSONKeys.channel: channel.name
            ]
        )
    }

    /**
     Creates an authentication request for the given authEndpoint

        - parameter endpoint: The authEndpoint to which the request will be made
        - parameter socketId: The socketId of the connection's websocket
        - parameter channel:  The PusherChannel to authenticate subscription for

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
        - parameter channel: The PusherChannel to authenticate subscription for
    */
    fileprivate func sendAuthorizationRequest(request: URLRequest,
                                              channel: PusherChannel,
                                              completionHandler: @escaping (PusherAuth?, PusherAuthError?) -> Void) {
        let task = URLSession.dataTask(with: request, completionHandler: { data, response, sessionError in
            if let error = sessionError {
                let message = "Error authorizing channel [\(channel.name)]: \(error)"
                completionHandler(nil, PusherAuthError(kind: .requestFailure,
                                                       message: message,
                                                       response: response,
                                                       error: error as NSError?))
                return
            }

            guard let data = data else {
                let message = "Error authorizing channel [\(channel.name)]"
                completionHandler(nil, PusherAuthError(kind: .invalidAuthResponse,
                                                       message: message,
                                                       response: response))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) else {
                let dataString = String(data: data, encoding: String.Encoding.utf8)
                let message = "Error authorizing channel [\(channel.name)]: \(String(describing: dataString))"
                completionHandler(nil, PusherAuthError(kind: .invalidAuthResponse,
                                                       message: message,
                                                       response: response,
                                                       data: dataString))
                return
            }

            guard let jsonObject = try? JSONSerialization.jsonObject(with: data,
                                                                     options: []),
                let json = jsonObject as? [String: AnyObject] else {
                let message = "Error authorizing channel [\(channel.name)]: Could not parse response from auth endpoint"
                completionHandler(nil, PusherAuthError(kind: .invalidAuthResponse,
                                                       message: message,
                                                       response: httpResponse))
                return
            }

            guard let auth = json[Constants.JSONKeys.auth] as? String else {
                let message = "Error authorizing channel [\(channel.name)]: No auth field in response"
                completionHandler(nil, PusherAuthError(kind: .invalidAuthResponse,
                                                       message: message,
                                                       response: httpResponse))
                return
            }

            let pusherAuth = PusherAuth(
                auth: auth,
                channelData: json[Constants.JSONKeys.channelData] as? String,
                sharedSecret: json[Constants.JSONKeys.sharedSecret] as? String
            )

            completionHandler(pusherAuth, nil)
        })

        task.resume()
    }

    /**
        Handle authorizer info and call appropriate handle function

        - parameter authString:  The auth response as a dictionary
        - parameter channelData: The channelData to send along with the auth request
        - parameter channel:     The PusherChannel to authorize the subscription for
    */
    fileprivate func handleAuthInfo(pusherAuth: PusherAuth, channel: PusherChannel) {
        if let decryptionKey = pusherAuth.sharedSecret {
            channel.decryptionKey = decryptionKey
        }

        if let channelData = pusherAuth.channelData {
            handlePresenceChannelAuth(authValue: pusherAuth.auth, channel: channel, channelData: channelData)
        } else {
            handlePrivateChannelAuth(authValue: pusherAuth.auth, channel: channel)
        }
    }

    /**
        Handle presence channel auth response and send subscribe message to Pusher API

        - parameter auth:        The auth string
        - parameter channel:     The PusherChannel to authorize subscription for
        - parameter channelData: The channelData to send along with the auth request
    */
    fileprivate func handlePresenceChannelAuth(
        authValue: String,
        channel: PusherChannel,
        channelData: String
    ) {
        (channel as? PusherPresenceChannel)?.setMyUserId(channelData: channelData)

        self.sendEvent(
            event: Constants.Events.Pusher.subscribe,
            data: [
                Constants.JSONKeys.channel: channel.name,
                Constants.JSONKeys.auth: authValue,
                Constants.JSONKeys.channelData: channelData
            ]
        )
    }

    /**
        Handle private channel auth response and send subscribe message to Pusher API

        - parameter auth:    The auth string
        - parameter channel: The PusherChannel to authenticate subscription for
    */
    fileprivate func handlePrivateChannelAuth(authValue auth: String, channel: PusherChannel) {
        self.sendEvent(
            event: Constants.Events.Pusher.subscribe,
            data: [
                Constants.JSONKeys.channel: channel.name,
                Constants.JSONKeys.auth: auth
            ]
        )
    }
}

extension PusherConnection: PusherEventQueueDelegate {
    func eventQueue(_ eventQueue: PusherEventQueue, didReceiveInvalidEventWithPayload payload: PusherEventPayload) {
        DispatchQueue.main.async {
            self.delegate?.debugLog?(message: PusherLogger.debug(for: .unableToHandleIncomingMessage,
                                                                 context: payload))
        }
    }

    func eventQueue(_ eventQueue: PusherEventQueue,
                    didFailToDecryptEventWithPayload payload: PusherEventPayload,
                    forChannelName channelName: String) {
        DispatchQueue.main.async {
            if let eventName = payload[Constants.JSONKeys.event] as? String {
                let data = payload[Constants.JSONKeys.data] as? String
                self.delegate?.failedToDecryptEvent?(eventName: eventName, channelName: channelName, data: data)
            }
            self.delegate?.debugLog?(message: PusherLogger.debug(for: .skippedEventAfterDecryptionFailure,
                                                                 context: channelName))
        }
    }

    func eventQueue(_ eventQueue: PusherEventQueue,
                    didReceiveEvent event: PusherEvent,
                    forChannelName channelName: String?) {
        DispatchQueue.main.async {
            self.handleEvent(event: event)
        }
    }

    /**
     Synchronously reloads the decryption key from the auth endpoint. This should be called from the event
     queue's dispatch queue. This method should NOT be called from the main thread as it will cause deadlock.

        - parameter eventQueue: The event queue that is requesting the reload
        - parameter channel:  The PusherChannel for which the key is being reloaded
    */
    func eventQueue(_ eventQueue: PusherEventQueue, reloadDecryptionKeySyncForChannel channel: PusherChannel) {
        let group = DispatchGroup()
        group.enter()
        // Schedule the loading of the key on the main thread
        DispatchQueue.main.async {
            _ = self.requestPusherAuthFromAuthMethod(channel: channel) { pusherAuth, error in
                if let pusherAuth = pusherAuth,
                    let decryptionKey = pusherAuth.sharedSecret,
                    error == nil {
                    channel.decryptionKey = decryptionKey
                } else {
                    channel.decryptionKey = nil
                }
                // Once we've updated the key, release the event queue thread to continue processing events
                group.leave()
            }
        }
        // Pause the event queue thread until we have the response from the auth endpoint
        group.wait()
    }
}

internal struct PusherAuthError: Error {
    enum Kind {
        case notConnected
        case noMethod
        case couldNotBuildRequest
        case invalidAuthResponse
        case requestFailure
    }

    let kind: Kind

    var message: String?

    var response: URLResponse?
    var data: String?
    var error: NSError?
}

@objc public class PusherAuth: NSObject {
    public let auth: String
    public let channelData: String?
    public let sharedSecret: String?

    public init(auth: String, channelData: String? = nil, sharedSecret: String? = nil) {
        self.auth = auth
        self.channelData = channelData
        self.sharedSecret = sharedSecret
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
        reconnecting: "reconnecting"
    ]

    public func stringValue() -> String {
        return ConnectionState.connectionStates[self]!
    }
}
