//
//  PusherConnection.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

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
    public weak var stateChangeDelegate: ConnectionStateChangeDelegate?

    public lazy var reachability: Reachability? = {
        let reachability = try? Reachability.reachabilityForInternetConnection()
        reachability?.whenReachable = { [unowned self] reachability in
            if self.connectionState == .Disconnected {
                self.socket.connect()
            }
        }
        reachability?.whenUnreachable = { [unowned self] reachability in
            print("Network unreachable")
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
    public init(key: String, socket: WebSocket, url: String, options: PusherClientOptions, URLSession: NSURLSession = NSURLSession.sharedSession()) {
        self.url = url
        self.key = key
        self.options = options
        self.URLSession = URLSession
        self.socket = socket
        self.socket.delegate = self
    }

    /**
        Initializes a new PusherChannel with a given name

        - parameter channelName: The name of the channel

        - returns: A new PusherChannel instance
    */
    internal func subscribe(channelName: String) -> PusherChannel {
        let newChannel = channels.add(channelName, connection: self)
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
    public func sendEvent(event: String, data: AnyObject, channelName: String? = nil) {
        if event.componentsSeparatedByString("-")[0] == "client" {
            sendClientEvent(event, data: data, channelName: channelName)
        } else {
            self.socket.writeString(JSONStringify(["event": event, "data": data]))
        }
    }

    /**
        Sends a client event with the given event, data, and channel name

        - parameter event:       The name of the event
        - parameter data:        The data to be stringified and sent
        - parameter channelName: The name of the channel
    */
    private func sendClientEvent(event: String, data: AnyObject, channelName: String?) {
        if let cName = channelName {
            if isPresenceChannel(cName) || isPrivateChannel(cName) {
                self.socket.writeString(JSONStringify(["event": event, "data": data, "channel": cName]))
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
    public func connect() {
        if self.connectionState == .Connected {
            return
        } else {
            updateConnectionState(.Connecting)
            self.socket.connect()
            if let reconnect = self.options.autoReconnect where reconnect {
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
        self.stateChangeDelegate?.connectionChange(self.connectionState, new: newState)
        self.connectionState = newState
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
            if isPresenceChannel(channelName) {
                if let presChan = self.channels.find(channelName) as? PresencePusherChannel {
                    if let data = json["data"] as? String, dataJSON = getPusherEventJSONFromString(data) {
                        if let presenceData = dataJSON["presence"] as? Dictionary<String, AnyObject>, presenceHash = presenceData["hash"] as? Dictionary<String, AnyObject> {
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
                updateConnectionState(.Connected)
                self.socketId = socketId

                for (_, channel) in self.channels.channels {
                    if !channel.subscribed {
                        if !self.authorize(channel) {
                            print("Unable to subscribe to channel: \(channel.name)")
                        }
                    }
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
        Parse a string to extract Pusher event information from it

        - parameter string: The string received over the websocket connection containing
                            Pusher event information

        - returns: A dictionary of Pusher-relevant event data
    */
    public func getPusherEventJSONFromString(string: String) -> Dictionary<String, AnyObject>? {
        let data = (string as NSString).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)

        do {
            if let jsonData = data, jsonObject = try NSJSONSerialization.JSONObjectWithData(jsonData, options: []) as? Dictionary<String, AnyObject> {
                return jsonObject
            } else {
                // TODO: Move below
                print("Unable to parse string from WebSocket: \(string)")
            }
        } catch let error as NSError {
            print(error.localizedDescription)
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
    public func handleEvent(eventName: String, jsonObject: Dictionary<String,AnyObject>) {
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
    private func callGlobalCallbacks(eventName: String, jsonObject: Dictionary<String,AnyObject>) {
        if let channelName = jsonObject["channel"] as? String, eData =  jsonObject["data"] as? String {
            if let globalChannel = self.globalChannel {
                globalChannel.handleEvent(channelName, eventName: eventName, eventData: eData)
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
        if !isPresenceChannel(channel.name) && !isPrivateChannel(channel.name) {
            subscribeToNormalChannel(channel)
        } else if let endpoint = self.options.authEndpoint where self.options.authMethod == .Endpoint {
            if let socket = self.socketId {
                sendAuthorisationRequest(endpoint, socket: socket, channel: channel, callback: callback)
            } else {
                print("socketId value not found. You may not be connected.")
                return false
            }
        } else if let secret = self.options.secret where self.options.authMethod == .Internal {
            var msg = ""
            var channelData = ""
            if isPresenceChannel(channel.name) {
                channelData = getUserDataJSON()
                msg = "\(self.socketId!):\(channel.name):\(channelData)"
            } else {
                msg = "\(self.socketId!):\(channel.name)"
            }

            var secretBuff = [UInt8]()
            secretBuff += secret.utf8

            var msgBuff = [UInt8]()
            msgBuff += msg.utf8

            if let hmac = try? Authenticator.HMAC(key: secretBuff, variant: .sha256).authenticate(msgBuff) {
                let signature = NSData.withBytes(hmac).toHexString()
                let auth = "\(self.key):\(signature)".lowercaseString

                if isPrivateChannel(channel.name) {
                    self.handlePrivateChannelAuth(auth, channel: channel, callback: callback)
                } else {
                    self.handlePresenceChannelAuth(auth, channel: channel, channelData: channelData, callback: callback)
                }
            }
        } else {
            print("Authentication method required for private / presence channels but none provided.")
            return false
        }
        return true
    }

    /**
        Calls the provided userDataFetcher function, if provided, otherwise will
        use the socketId as the user_id and return that stringified

        - returns: A JSON stringified user data object
    */
    private func getUserDataJSON() -> String {
        if let userDataFetcher = self.options.userDataFetcher {
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
        Send authentication request to the authEndpoint specified

        - parameter endpoint: The authEndpoint to which the request will be made
        - parameter socket:   The socketId of the connection's websocket
        - parameter channel:  The PusherChannel to authenticate subsciption for
        - parameter callback: An optional callback to be passed along to relevant auth handlers
    */
    private func sendAuthorisationRequest(endpoint: String, socket: String, channel: PusherChannel, callback: ((Dictionary<String, String>?) -> Void)? = nil) {
        var request = NSMutableURLRequest(URL: NSURL(string: endpoint)!)
        request.HTTPMethod = "POST"
        request.HTTPBody = "socket_id=\(socket)&channel_name=\(channel.name)".dataUsingEncoding(NSUTF8StringEncoding)

        if let handler = self.options.authRequestCustomizer {
            request = handler(request)
        }

        let task = URLSession.dataTaskWithRequest(request, completionHandler: { data, response, error in
            if error != nil {
                print("Error authorizing channel [\(channel.name)]: \(error)")
            }
            if let httpResponse = response as? NSHTTPURLResponse where (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {

                do {
                    if let json = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? Dictionary<String, AnyObject> {
                        self.handleAuthResponse(json, channel: channel, callback: callback)
                    }
                } catch {
                    print("Error authorizing channel [\(channel.name)]")
                }

            } else {
                if let d = data {
                    print ("Error authorizing channel [\(channel.name)]: \(String(data: d, encoding: NSUTF8StringEncoding))")
                } else {
                    print("Error authorizing channel [\(channel.name)]")
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
    private func handleAuthResponse(json: Dictionary<String, AnyObject>, channel: PusherChannel, callback: ((Dictionary<String, String>?) -> Void)? = nil) {
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
    private func handlePresenceChannelAuth(auth: String, channel: PusherChannel, channelData: String, callback: ((Dictionary<String, String>?) -> Void)? = nil) {
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
    private func handlePrivateChannelAuth(auth: String, channel: PusherChannel, callback: ((Dictionary<String, String>?) -> Void)? = nil) {
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
}

public protocol ConnectionStateChangeDelegate: class {
    func connectionChange(old: ConnectionState, new: ConnectionState)
}