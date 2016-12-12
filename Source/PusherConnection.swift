//
//  PusherConnection.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

public typealias PusherEventJSON = [String : AnyObject]
public typealias PusherUserData = PresenceChannelMember

public class PusherConnection {
    public let url: String
    public let key: String
    public var options: PusherClientOptions
    public var globalChannel: GlobalChannel!
    public var socketId: String?
    public var connectionState = ConnectionState.Disconnected
    public var channels = PusherChannels()
    public var socket: WebSocket!
    public var URLSession: NSURLSession
    public var userDataFetcher: (() -> PusherUserData)?
    public var debugLogger: ((String) -> ())?
    public weak var stateChangeDelegate: ConnectionStateChangeDelegate?
    public var reconnectAttemptsMax: Int? = 6
    public var reconnectAttempts: Int = 0
    public var maxReconnectGapInSeconds: Double? = nil
    internal var reconnectTimer: NSTimer? = nil

    public var socketConnected: Bool = false {
        didSet {
            updateConnectionStateAndAttemptSubscriptions()
        }
    }
    public var connectionEstablishedMessageReceived: Bool = false {
        didSet {
            updateConnectionStateAndAttemptSubscriptions()
        }
    }

    public lazy var reachability: Reachability? = {
        let reachability = try? Reachability.reachabilityForInternetConnection()
        reachability?.whenReachable = { [unowned self] reachability in
            self.debugLogger?("[PUSHER DEBUG] Network reachable")
            if self.connectionState == .Disconnected || self.connectionState == .ReconnectingWhenNetworkBecomesReachable {
                self.attemptReconnect()
            }
        }
        reachability?.whenUnreachable = { [unowned self] reachability in
            self.debugLogger?("[PUSHER DEBUG] Network unreachable")
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
        URLSession: NSURLSession = NSURLSession.sharedSession()) {
            self.url = url
            self.key = key
            self.options = options
            self.URLSession = URLSession
            self.socket = socket
            self.socket.delegate = self
    }

    /**
        Initializes a new PusherChannel with a given name

        - parameter channelName:     The name of the channel
        - parameter onMemberAdded:   A function that will be called with information about the
                                     member who has just joined the presence channel
        - parameter onMemberRemoved: A function that will be called with information about the
                                     member who has just left the presence channel

        - returns: A new PusherChannel instance
    */
    internal func subscribe(
        channelName: String,
        onMemberAdded: ((PresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((PresenceChannelMember) -> ())? = nil) -> PusherChannel {
            let newChannel = channels.add(channelName, connection: self, onMemberAdded: onMemberAdded, onMemberRemoved: onMemberRemoved)
            if self.connectionState == .Connected {
                if !self.authorize(newChannel) {
                    print("Unable to subscribe to channel: \(newChannel.name)")
                }
            }
            return newChannel
    }

    /**
        Unsubscribes from a PusherChannel with a given name

        - parameter channelName: The name of the channel
    */
    internal func unsubscribe(channelName: String) {
        if let chan = self.channels.find(channelName) where chan.subscribed {
            self.sendEvent("pusher:unsubscribe",
                           data: [
                            "channel": channelName
                ]
            )
            self.channels.remove(channelName)
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
    public func sendEvent(event: String, data: AnyObject, channel: PusherChannel? = nil) {
        if event.componentsSeparatedByString("-")[0] == "client" {
            sendClientEvent(event, data: data, channel: channel)
        } else {
            let dataString = JSONStringify(["event": event, "data": data])
            self.debugLogger?("[PUSHER DEBUG] sendEvent \(dataString)")
            self.socket.writeString(dataString)
        }
    }

    /**
        Sends a client event with the given event, data, and channel name

        - parameter event:       The name of the event
        - parameter data:        The data to be stringified and sent
        - parameter channelName: The name of the channel
    */
    private func sendClientEvent(event: String, data: AnyObject, channel: PusherChannel?) {
        if let channel = channel {
            if channel.type == .Presence || channel.type == .Private {
                let dataString = JSONStringify(["event": event, "data": data, "channel": channel.name])
                self.debugLogger?("[PUSHER DEBUG] sendClientEvent \(dataString)")
                self.socket.writeString(dataString)
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
    private func JSONStringify(value: AnyObject) -> String {
        if NSJSONSerialization.isValidJSONObject(value) {
            do {
                let data = try NSJSONSerialization.dataWithJSONObject(value, options: [])
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string as String
                }
            } catch _ {
            }
        }
        return ""
    }

    /**
        Disconnects the websocket
    */
    public func disconnect() {
        if self.connectionState == .Connected {
            self.reachability?.stopNotifier()
            updateConnectionState(.Disconnecting)
            self.socket.disconnect()
        }
    }

    /**
        Establish a websocket connection
    */
    @objc public func connect() {
        if self.connectionState == .Connected {
            return
        } else {
            updateConnectionState(.Connecting)
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
    internal func addCallbackToGlobalChannel(callback: (AnyObject?) -> Void) -> String {
        return globalChannel.bind(callback)
    }

    /**
        Remove the callback with id of callbackId from the connection's global channel

        - parameter callbackId: The unique string representing the callback to be removed
    */
    internal func removeCallbackFromGlobalChannel(callbackId: String) {
        globalChannel.unbind(callbackId)
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
    internal func updateConnectionState(newState: ConnectionState) {
        let oldState = self.connectionState
        self.connectionState = newState
        self.stateChangeDelegate?.connectionChange(oldState, new: newState)
    }

    /**
        Update connection state and attempt subscriptions to unsubscribed channels
    */
    private func updateConnectionStateAndAttemptSubscriptions() {
        if self.connectionEstablishedMessageReceived && self.socketConnected && self.connectionState != .Connected {
            updateConnectionState(.Connected)
            attemptSubscriptionsToUnsubscribedChannels()
        }
    }

    /**
        Handle setting channel state and triggering unsent client events, if applicable,
        upon receiving a successful subscription event

        - parameter json: The PusherEventJSON containing successful subscription data
    */
    private func handleSubscriptionSucceededEvent(json: PusherEventJSON) {
        if let channelName = json["channel"] as? String, chan = self.channels.find(channelName) {
            chan.subscribed = true
            if let eData = json["data"] as? String {
                callGlobalCallbacks("pusher:subscription_succeeded", jsonObject: json)
                chan.handleEvent("pusher:subscription_succeeded", eventData: eData)
            }
            if PusherChannelType.isPresenceChannel(name: channelName) {
                if let presChan = self.channels.find(channelName) as? PresencePusherChannel {
                    if let data = json["data"] as? String, dataJSON = getPusherEventJSONFromString(data) {
                        if let presenceData = dataJSON["presence"] as? [String : AnyObject],
                               presenceHash = presenceData["hash"] as? [String : AnyObject] {
                                    presChan.addExistingMembers(presenceHash)
                        }
                    }
                }
            }
            while chan.unsentEvents.count > 0 {
                if let pusherEvent = chan.unsentEvents.popLast() {
                    chan.trigger(pusherEvent.name, data: pusherEvent.data)
                }
            }
        }
    }

    /**
        Handle setting connection state and making subscriptions that couldn't be
        attempted while the connection was not in a connected state

        - parameter json: The PusherEventJSON containing connection established data
    */
    private func handleConnectionEstablishedEvent(json: PusherEventJSON) {
        if let data = json["data"] as? String {
            if let connectionData = getPusherEventJSONFromString(data), socketId = connectionData["socket_id"] as? String {
                self.socketId = socketId

                self.reconnectAttempts = 0
                self.reconnectTimer?.invalidate()

                self.connectionEstablishedMessageReceived = true
            }
        }
    }

    /**
        Attempts to make subscriptions that couldn't be attempted while the
        connection was not in a connected state
    */
    private func attemptSubscriptionsToUnsubscribedChannels() {
        for (_, channel) in self.channels.channels {
            if !channel.subscribed {
                if !self.authorize(channel) {
                    print("Unable to subscribe to channel: \(channel.name)")
                }
            }
        }
    }

    /**
        Handle a new member subscribing to a presence channel

        - parameter json: The PusherEventJSON containing the member data
    */
    private func handleMemberAddedEvent(json: PusherEventJSON) {
        if let data = json["data"] as? String {
            if let channelName = json["channel"] as? String, chan = self.channels.find(channelName) as? PresencePusherChannel {
                if let memberJSON = getPusherEventJSONFromString(data) {
                    chan.addMember(memberJSON)
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
    private func handleMemberRemovedEvent(json: PusherEventJSON) {
        if let data = json["data"] as? String {
            if let channelName = json["channel"] as? String, chan = self.channels.find(channelName) as? PresencePusherChannel {
                if let memberJSON = getPusherEventJSONFromString(data) {
                    chan.removeMember(memberJSON)
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
    private func handleAuthorizationErrorEvent(channelName: String, data: String?) {
        let eventName = "pusher:subscription_error"
        let json = [
            "event": eventName,
            "channel": channelName,
            "data": data ?? ""
        ]
        dispatch_async(dispatch_get_main_queue()) {
            self.handleEvent(eventName, jsonObject: json)
        }
    }

    /**
        Parse a string to extract Pusher event information from it

        - parameter string: The string received over the websocket connection containing
                            Pusher event information

        - returns: A dictionary of Pusher-relevant event data
    */
    public func getPusherEventJSONFromString(string: String) -> [String : AnyObject]? {
        let data = (string as NSString).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)

        do {
            if let jsonData = data, jsonObject = try NSJSONSerialization.JSONObjectWithData(jsonData, options: []) as? [String : AnyObject] {
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
    public func getEventDataJSONFromString(string: String) -> AnyObject {
        let data = (string as NSString).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)

        do {
            if let jsonData = data, jsonObject: AnyObject = try NSJSONSerialization.JSONObjectWithData(jsonData, options: []) {
                return jsonObject
            } else {
                print("Returning data string instead because unable to parse string as JSON - check that your JSON is valid.")
            }
        } catch let error as NSError {
            print("Returning data string instead because unable to parse string as JSON - check that your JSON is valid.")
            print(error.localizedDescription)
        }
        return string
    }

    /**
        Handles incoming events and passes them on to be handled by the appropriate function

        - parameter eventName:  The name of the incoming event
        - parameter jsonObject: The event-specific data related to the incoming event
    */
    public func handleEvent(eventName: String, jsonObject: [String : AnyObject]) {
        switch eventName {
        case "pusher_internal:subscription_succeeded":
            handleSubscriptionSucceededEvent(jsonObject)
        case "pusher:connection_established":
            handleConnectionEstablishedEvent(jsonObject)
        case "pusher_internal:member_added":
            handleMemberAddedEvent(jsonObject)
        case "pusher_internal:member_removed":
            handleMemberRemovedEvent(jsonObject)
        default:
            callGlobalCallbacks(eventName, jsonObject: jsonObject)
            if let channelName = jsonObject["channel"] as? String, internalChannel = self.channels.find(channelName) {
                if let eName = jsonObject["event"] as? String, eData = jsonObject["data"] as? String {
                    internalChannel.handleEvent(eName, eventData: eData)
                }
            }
        }
    }

    /**
        Call any global callbacks

        - parameter eventName:  The name of the incoming event
        - parameter jsonObject: The event-specific data related to the incoming event
    */
    private func callGlobalCallbacks(eventName: String, jsonObject: [String : AnyObject]) {
        if let globalChannel = self.globalChannel {
            if let eData =  jsonObject["data"] as? String {
                let channelName = jsonObject["channel"] as! String?
                globalChannel.handleEvent(channelName, eventName: eventName, eventData: eData)
            } else if let eData =  jsonObject["data"] as? [String: AnyObject] {
                globalChannel.handleErrorEvent(eventName, eventData: eData)
            }
    }
    }

    /**
        Uses the appropriate authentication method to authenticate subscriptions to private and
        presence channels

        - parameter channel:  The PusherChannel to authenticate
        - parameter callback: An optional callback to be passed along to relevant auth handlers

        - returns: A Bool indicating whether or not the authentication request was made
                   successfully
    */
    private func authorize(channel: PusherChannel, callback: ((Dictionary<String, String>?) -> Void)? = nil) -> Bool {
        if channel.type != .Presence && channel.type != .Private {
            subscribeToNormalChannel(channel)
            return true
        } else {
            if let socketID = self.socketId {
                switch self.options.authMethod {
                    case .NoMethod:
                        print("Authentication method required for private / presence channels but none provided.")
                        return false
                    case .Endpoint(authEndpoint: let authEndpoint):
                        let request = requestForAuthEndpoint(authEndpoint, socketID: socketID, channel: channel)
                        sendAuthorisationRequest(request, channel: channel, callback: callback)
                        return true
                    case .AuthRequestBuilder(authRequestBuilder: let builder):
                        let request = builder.requestFor(socketID, channel: channel)
                        sendAuthorisationRequest(request, channel: channel, callback: callback)
                        return true
                    case .Internal(secret: let secret):
                        var msg = ""
                        var channelData = ""
                        if channel.type == .Presence {
                            channelData = getUserDataJSON()
                            msg = "\(self.socketId!):\(channel.name):\(channelData)"
                        } else {
                            msg = "\(self.socketId!):\(channel.name)"
                        }

                        let secretBuff: [UInt8] = Array(secret.utf8)
                        let msgBuff: [UInt8] = Array(msg.utf8)

                        if let hmac = try? Authenticator.HMAC(key: secretBuff, variant: .sha256).authenticate(msgBuff) {
                            let signature = NSData.withBytes(hmac).toHexString()
                            let auth = "\(self.key):\(signature)".lowercaseString

                            if channel.type == .Private {
                                self.handlePrivateChannelAuth(auth, channel: channel, callback: callback)
                            } else {
                                self.handlePresenceChannelAuth(auth, channel: channel, channelData: channelData, callback: callback)
                            }
                        }

                        return true
                }
            } else {
                print("socketId value not found. You may not be connected.")
                return false
            }
        }
    }

    /**
        Calls the provided userDataFetcher function, if provided, otherwise will
        use the socketId as the user_id and return that stringified

        - returns: A JSON stringified user data object
    */
    private func getUserDataJSON() -> String {
        if let userDataFetcher = self.userDataFetcher {
            let userData = userDataFetcher()
            if let userInfo: AnyObject = userData.userInfo {
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
    private func subscribeToNormalChannel(channel: PusherChannel) {
        self.sendEvent(
            "pusher:subscribe",
            data: [
                "channel": channel.name
            ]
        )
    }

    /**
     Creates an authentication request for the given authEndpoint

        - parameter endpoint: The authEndpoint to which the request will be made
        - parameter socketID: The socketId of the connection's websocket
        - parameter channel:  The PusherChannel to authenticate subsciption for

        - returns: NSURLRequest object to be used by the function making the auth request
    */
    private func requestForAuthEndpoint(endpoint: String, socketID: String, channel: PusherChannel) -> NSURLRequest {
        let request = NSMutableURLRequest(URL: NSURL(string: endpoint)!)
        request.HTTPMethod = "POST"
        request.HTTPBody = "socket_id=\(socketID)&channel_name=\(channel.name)".dataUsingEncoding(NSUTF8StringEncoding)

        return request
    }

    /**
        Send authentication request to the authEndpoint specified

        - parameter request:  The request to send
        - parameter channel:  The PusherChannel to authenticate subsciption for
        - parameter callback: An optional callback to be passed along to relevant auth handlers
    */
    private func sendAuthorisationRequest(request: NSURLRequest, channel: PusherChannel, callback: (([String : String]?) -> Void)? = nil) {
        let task = URLSession.dataTaskWithRequest(request, completionHandler: { data, response, error in
            if let error = error {
                print("Error authorizing channel [\(channel.name)]: \(error)")
                self.handleAuthorizationErrorEvent(channel.name, data: error.domain)
            }
            if let httpResponse = response as? NSHTTPURLResponse where (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                do {
                    if let json = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [String : AnyObject] {
                        self.handleAuthResponse(json, channel: channel, callback: callback)
                    }
                } catch {
                    print("Error authorizing channel [\(channel.name)]")
                    self.handleAuthorizationErrorEvent(channel.name, data: nil)
                }
            } else {
                if let d = data {
                    let dataString = String(data: d, encoding: NSUTF8StringEncoding)
                    print ("Error authorizing channel [\(channel.name)]: \(dataString)")
                    self.handleAuthorizationErrorEvent(channel.name, data: dataString)
                } else {
                    print("Error authorizing channel [\(channel.name)]")
                    self.handleAuthorizationErrorEvent(channel.name, data: nil)
                }
            }
        })

        task.resume()
    }

    /**
        Handle authentication request response and call appropriate handle function

        - parameter json:     The auth response as a dictionary
        - parameter channel:  The PusherChannel to authenticate subsciption for
        - parameter callback: An optional callback to be passed along to relevant auth handlers
    */
    private func handleAuthResponse(
        json: [String : AnyObject],
        channel: PusherChannel,
        callback: (([String : String]?) -> Void)? = nil) {
            if let auth = json["auth"] as? String {
                if let channelData = json["channel_data"] as? String {
                    handlePresenceChannelAuth(auth, channel: channel, channelData: channelData, callback: callback)
                } else {
                    handlePrivateChannelAuth(auth, channel: channel, callback: callback)
                }
            }
    }

    /**
        Handle presence channel auth response and send subscribe message to Pusher API

        - parameter auth:        The auth string
        - parameter channel:     The PusherChannel to authenticate subsciption for
        - parameter channelData: The channelData to send along with the auth request
        - parameter callback:    An optional callback to be called with auth and channelData, if provided
    */
    private func handlePresenceChannelAuth(
        auth: String,
        channel: PusherChannel,
        channelData: String,
        callback: (([String : String]?) -> Void)? = nil) {
            (channel as? PresencePusherChannel)?.setMyId(channelData)

            if let cBack = callback {
                cBack(["auth": auth, "channel_data": channelData])
            } else {
                self.sendEvent(
                    "pusher:subscribe",
                    data: [
                        "channel": channel.name,
                        "auth": auth,
                        "channel_data": channelData
                    ]
                )
            }
    }

    /**
        Handle private channel auth response and send subscribe message to Pusher API

        - parameter auth:        The auth string
        - parameter channel:     The PusherChannel to authenticate subsciption for
        - parameter callback:    An optional callback to be called with auth and channelData, if provided
    */
    private func handlePrivateChannelAuth(
        auth: String,
        channel: PusherChannel,
        callback: (([String : String]?) -> Void)? = nil) {
            if let cBack = callback {
                cBack(["auth": auth])
            } else {
                self.sendEvent(
                    "pusher:subscribe",
                    data: [
                        "channel": channel.name,
                        "auth": auth
                    ]
                )
            }
    }
}

public enum ConnectionState {
    case Connecting
    case Connected
    case Disconnecting
    case Disconnected
    case Reconnecting
    case ReconnectingWhenNetworkBecomesReachable
}

public protocol ConnectionStateChangeDelegate: class {
    func connectionChange(old: ConnectionState, new: ConnectionState)
}
