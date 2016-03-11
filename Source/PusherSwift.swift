//
//  PusherSwift.swift
//
//  Created by Hamilton Chapman on 19/02/2015.
//
//

import Foundation
import Starscream
import CryptoSwift
import ReachabilitySwift

public typealias PusherEventJSON = Dictionary<String, AnyObject>
public typealias PusherUserInfoObject = Dictionary<String, AnyObject>
public typealias PusherUserData = PresenceChannelMember

let PROTOCOL = 7
let VERSION = "0.2.3"
let CLIENT_NAME = "pusher-websocket-swift"

public class Pusher {
    public let connection: PusherConnection

    public init(key: String, options: Dictionary<String, Any>? = nil) {
        let pusherClientOptions = PusherClientOptions(options: options)
        let urlString = constructUrl(key, options: pusherClientOptions)
        let ws = WebSocket(url: NSURL(string: urlString)!)
        connection = PusherConnection(key: key, socket: ws, url: urlString, options: pusherClientOptions)
        connection.createGlobalChannel()
    }

    public func subscribe(channelName: String) -> PusherChannel {
        return self.connection.subscribe(channelName)
    }

    public func unsubscribe(channelName: String) {
        self.connection.unsubscribe(channelName)
    }

    public func bind(callback: (AnyObject?) -> Void) -> String {
        return self.connection.addCallbackToGlobalChannel(callback)
    }

    public func unbind(callbackId: String) {
        self.connection.removeCallbackFromGlobalChannel(callbackId)
    }

    public func unbindAll() {
        self.connection.removeAllCallbacksFromGlobalChannel()
    }

    public func disconnect() {
        self.connection.disconnect()
    }

    public func connect() {
        self.connection.connect()
    }
}

public enum AuthMethod {
    case Endpoint
    case Internal
    case NoMethod
}

func constructUrl(key: String, options: PusherClientOptions) -> String {
    var url = ""

    if let encrypted = options.encrypted where !encrypted {
        let defaultPort = (options.port ?? 80)
        url = "ws://\(options.host!):\(defaultPort)/app/\(key)"
    } else {
        let defaultPort = (options.port ?? 443)
        url = "wss://\(options.host!):\(defaultPort)/app/\(key)"
    }
    return "\(url)?client=\(CLIENT_NAME)&version=\(VERSION)&protocol=\(PROTOCOL)"
}

public struct PusherClientOptions {
    public let authEndpoint: String?
    public let secret: String?
    public let userDataFetcher: (() -> PusherUserData)?
    public let authMethod: AuthMethod?
    public let attemptToReturnJSONObject: Bool?
    public let encrypted: Bool?
    public let host: String?
    public let port: Int?
    public let autoReconnect: Bool?
    public let authRequestCustomizer: (NSMutableURLRequest -> NSMutableURLRequest)?

    public init(options: [String:Any]?) {
        let validKeys = ["encrypted", "attemptToReturnJSONObject", "authEndpoint", "secret", "userDataFetcher", "port", "host", "cluster", "autoReconnect", "authRequestCustomizer"]
        let defaults: [String:AnyObject?] = [
            "encrypted": true,
            "attemptToReturnJSONObject": true,
            "authEndpoint": nil,
            "secret": nil,
            "userDataFetcher": nil,
            "autoReconnect": true,
            "authRequestCustomizer": nil,
            "host": "ws.pusherapp.com",
            "port": nil
        ]
        
        var mutableOptions = options
        
        if let options = options {
            for (key, _) in options {
                if !validKeys.contains(key) {
                    print("Invalid key in options: \(key)")
                }
            }
            
            if let cluster = options["cluster"] {
                if let host = options["host"] {
                    print("Both host (\(host)) and cluster (\(cluster)) passed as options - host takes precedence")
                } else {
                    mutableOptions!["host"] = "ws-\(cluster).pusher.com"
                }
            }
        }
        
        var optionsMergedWithDefaults: [String:Any?] = [:]

        for (key, value) in defaults {
            if let mutableOptions = mutableOptions, optionsValue = mutableOptions[key] {
                optionsMergedWithDefaults[key] = optionsValue
            } else {
                optionsMergedWithDefaults[key] = value
            }
        }

        self.encrypted = optionsMergedWithDefaults["encrypted"] as? Bool
        self.authEndpoint = optionsMergedWithDefaults["authEndpoint"] as? String
        self.secret = optionsMergedWithDefaults["secret"] as? String
        self.userDataFetcher = optionsMergedWithDefaults["userDataFetcher"] as? () -> PusherUserData
        self.attemptToReturnJSONObject = optionsMergedWithDefaults["attemptToReturnJSONObject"] as? Bool
        self.host = optionsMergedWithDefaults["host"] as? String
        self.port = optionsMergedWithDefaults["port"] as? Int
        self.autoReconnect = optionsMergedWithDefaults["autoReconnect"] as? Bool
        self.authRequestCustomizer = optionsMergedWithDefaults["authRequestCustomizer"] as? (NSMutableURLRequest -> NSMutableURLRequest)

        if let _ = authEndpoint {
            self.authMethod = .Endpoint
        } else if let _ = secret {
            self.authMethod = .Internal
        } else {
            self.authMethod = .NoMethod
        }
    }
}

public class PusherConnection: WebSocketDelegate {
    public let url: String
    public let key: String
    public var options: PusherClientOptions
    public var globalChannel: GlobalChannel!
    public var socketId: String?
    public var connected = false
    public var channels = PusherChannels()
    public var socket: WebSocket!
    public var URLSession: NSURLSession
    
    public lazy var reachability: Reachability? = {
        let reachability = try? Reachability.reachabilityForInternetConnection()
        reachability?.whenReachable = { [unowned self] reachability in
            if !self.connected {
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

    private func subscribe(channelName: String) -> PusherChannel {
        let newChannel = channels.add(channelName, connection: self)
        if self.connected {
            if !self.authorize(newChannel) {
                print("Unable to subscribe to channel: \(newChannel.name)")
            }
        }
        return newChannel
    }

    private func unsubscribe(channelName: String) {
        if let chan = self.channels.find(channelName) where chan.subscribed {
            self.sendEvent("pusher:unsubscribe",
                data: [
                    "channel": channelName
                ]
            )
            self.channels.remove(channelName)
        }
    }

    private func sendEvent(event: String, data: AnyObject, channelName: String? = nil) {
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
        if self.connected {
            self.reachability?.stopNotifier()
            self.socket.disconnect()
        }
    }
    
    public func connect() {
        if self.connected {
            return
        } else {
            self.socket.connect()
            if let reconnect = self.options.autoReconnect where reconnect {
                _ = try? reachability?.startNotifier()
            }
        }
    }

    private func createGlobalChannel() {
        self.globalChannel = GlobalChannel(connection: self)
    }

    private func addCallbackToGlobalChannel(callback: (AnyObject?) -> Void) -> String {
        return globalChannel.bind(callback)
    }

    private func removeCallbackFromGlobalChannel(callbackId: String) {
        globalChannel.unbind(callbackId)
    }

    private func removeAllCallbacksFromGlobalChannel() {
        globalChannel.unbindAll()
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
                self.connected = true
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

    // MARK: WebSocketDelegate Implementation

    public func websocketDidReceiveMessage(ws: WebSocket, text: String) {
        if let pusherPayloadObject = getPusherEventJSONFromString(text), eventName = pusherPayloadObject["event"] as? String {
            self.handleEvent(eventName, jsonObject: pusherPayloadObject)
        } else {
            print("Unable to handle incoming Websocket message")
        }
    }

    public func websocketDidDisconnect(ws: WebSocket, error: NSError?) {
        if let error = error {
            print("Websocket is disconnected: \(error.localizedDescription)")
        }
        
        self.connected = false
        for (_, channel) in self.channels.channels {
            channel.subscribed = false
        }
    }

    public func websocketDidConnect(ws: WebSocket) {}
    public func websocketDidReceiveData(ws: WebSocket, data: NSData) {}
}

public struct EventHandler {
    let id: String
    let callback: (AnyObject?) -> Void
}

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

public struct PusherEvent {
    public let name: String
    public let data: AnyObject
}

public class PresencePusherChannel: PusherChannel {
    public var members: [PresenceChannelMember]

    override init(name: String, connection: PusherConnection) {
        self.members = []
        super.init(name: name, connection: connection)
    }

    private func addMember(memberJSON: Dictionary<String, AnyObject>) {
        if let userId = memberJSON["user_id"] as? String {
            if let userInfo = memberJSON["user_info"] as? PusherUserInfoObject {
                members.append(PresenceChannelMember(userId: userId, userInfo: userInfo))
            } else {
                members.append(PresenceChannelMember(userId: userId))
            }
        } else if let userId = memberJSON["user_id"] as? Int {
            if let userInfo = memberJSON["user_info"] as? PusherUserInfoObject {
                members.append(PresenceChannelMember(userId: String(userId), userInfo: userInfo))
            } else {
                members.append(PresenceChannelMember(userId: String(userId)))
            }
        }
    }

    private func addExistingMembers(memberHash: Dictionary<String, AnyObject>) {
        for (userId, userInfo) in memberHash {
            if let userInfo = userInfo as? PusherUserInfoObject {
                self.members.append(PresenceChannelMember(userId: userId, userInfo: userInfo))
            } else {
                self.members.append(PresenceChannelMember(userId: userId))
            }
        }
    }

    private func removeMember(memberJSON: Dictionary<String, AnyObject>) {
        if let userId = memberJSON["user_id"] as? String {
            self.members = self.members.filter({ $0.userId != userId })
        } else if let userId = memberJSON["user_id"] as? Int {
            self.members = self.members.filter({ $0.userId != String(userId) })
        }
    }
}

public struct PresenceChannelMember {
    public let userId: String
    public let userInfo: AnyObject?

    public init(userId: String, userInfo: AnyObject? = nil) {
        self.userId = userId
        self.userInfo = userInfo
    }
}

public class GlobalChannel: PusherChannel {
    public var globalCallbacks: [String: (AnyObject?) -> Void] = [:]

    init(connection: PusherConnection) {
        super.init(name: "pusher_global_internal_channel", connection: connection)
    }

    private func handleEvent(channelName: String, eventName: String, eventData: String) {
        for (_, callback) in self.globalCallbacks {
            callback(["channel": channelName, "event": eventName, "data": eventData])
        }
    }

    private func bind(callback: (AnyObject?) -> Void) -> String {
        let randomId = NSUUID().UUIDString
        self.globalCallbacks[randomId] = callback
        return randomId
    }

    private func unbind(callbackId: String) {
        globalCallbacks.removeValueForKey(callbackId)
    }

    override public func unbindAll() {
        globalCallbacks = [:]
    }
}

public class PusherChannels {
    public var channels = [String: PusherChannel]()

    private func add(channelName: String, connection: PusherConnection) -> PusherChannel {
        if let channel = self.channels[channelName] {
            return channel
        } else {
            var newChannel: PusherChannel
            if isPresenceChannel(channelName) {
                newChannel = PresencePusherChannel(name: channelName, connection: connection)
            } else {
                newChannel = PusherChannel(name: channelName, connection: connection)
            }
            self.channels[channelName] = newChannel
            return newChannel
        }
    }

    private func remove(channelName: String) {
        self.channels.removeValueForKey(channelName)
    }

    private func find(channelName: String) -> PusherChannel? {
        return self.channels[channelName]
    }
}

private func isPresenceChannel(channelName: String) -> Bool {
    return (channelName.componentsSeparatedByString("-")[0] == "presence") ? true : false
}

private func isPrivateChannel(channelName: String) -> Bool {
    return (channelName.componentsSeparatedByString("-")[0] == "private") ? true : false
}
