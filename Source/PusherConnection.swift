//
//  PusherConnection.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

import Starscream
import ReachabilitySwift
import CryptoSwift

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
    
    public init(key: String, socket: WebSocket, url: String, options: PusherClientOptions, URLSession: NSURLSession = NSURLSession.sharedSession()) {
        self.url = url
        self.key = key
        self.options = options
        self.URLSession = URLSession
        self.socket = socket
        self.socket.delegate = self
    }
    
    internal func subscribe(channelName: String) -> PusherChannel {
        let newChannel = channels.add(channelName, connection: self)
        if self.connectionState == .Connected {
            if !self.authorize(newChannel) {
                print("Unable to subscribe to channel: \(newChannel.name)")
            }
        }
        return newChannel
    }
    
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
    
    public func sendEvent(event: String, data: AnyObject, channelName: String? = nil) {
        if event.componentsSeparatedByString("-")[0] == "client" {
            sendClientEvent(event, data: data, channelName: channelName)
        } else {
            self.socket.writeString(JSONStringify(["event": event, "data": data]))
        }
    }
    
    private func sendClientEvent(event: String, data: AnyObject, channelName: String?) {
        if let cName = channelName {
            if isPresenceChannel(cName) || isPrivateChannel(cName) {
                self.socket.writeString(JSONStringify(["event": event, "data": data, "channel": cName]))
            } else {
                print("You must be subscribed to a private or presence channel to send client events")
            }
        }
    }
    
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
    
    public func disconnect() {
        if self.connectionState == .Connected {
            self.reachability?.stopNotifier()
            updateConnectionState(.Disconnecting)
            self.socket.disconnect()
        }
    }
    
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
    
    internal func createGlobalChannel() {
        self.globalChannel = GlobalChannel(connection: self)
    }
    
    internal func addCallbackToGlobalChannel(callback: (AnyObject?) -> Void) -> String {
        return globalChannel.bind(callback)
    }
    
    internal func removeCallbackFromGlobalChannel(callbackId: String) {
        globalChannel.unbind(callbackId)
    }
    
    internal func removeAllCallbacksFromGlobalChannel() {
        globalChannel.unbindAll()
    }
    
    internal func updateConnectionState(newState: ConnectionState) {
        self.stateChangeDelegate?.connectionChange(self.connectionState, new: newState)
        self.connectionState = newState
    }
    
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
    
    private func callGlobalCallbacks(eventName: String, jsonObject: Dictionary<String,AnyObject>) {
        if let channelName = jsonObject["channel"] as? String, eData =  jsonObject["data"] as? String {
            if let globalChannel = self.globalChannel {
                globalChannel.handleEvent(channelName, eventName: eventName, eventData: eData)
            }
        }
    }
    
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
    
    private func subscribeToNormalChannel(channel: PusherChannel) {
        self.sendEvent("pusher:subscribe",
                       data: [
                        "channel": channel.name
            ]
        )
    }
    
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
    
    private func handleAuthResponse(json: Dictionary<String, AnyObject>, channel: PusherChannel, callback: ((Dictionary<String, String>?) -> Void)? = nil) {
        if let auth = json["auth"] as? String {
            if let channelData = json["channel_data"] as? String {
                handlePresenceChannelAuth(auth, channel: channel, channelData: channelData, callback: callback)
            } else {
                handlePrivateChannelAuth(auth, channel: channel, callback: callback)
            }
        }
    }
    
    private func handlePresenceChannelAuth(auth: String, channel: PusherChannel, channelData: String, callback: ((Dictionary<String, String>?) -> Void)? = nil) {
        if let cBack = callback {
            cBack(["auth": auth, "channel_data": channelData])
        } else {
            self.sendEvent("pusher:subscribe",
                           data: [
                            "channel": channel.name,
                            "auth": auth,
                            "channel_data": channelData
                ]
            )
        }
    }
    
    private func handlePrivateChannelAuth(auth: String, channel: PusherChannel, callback: ((Dictionary<String, String>?) -> Void)? = nil) {
        if let cBack = callback {
            cBack(["auth": auth])
        } else {
            self.sendEvent("pusher:subscribe",
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