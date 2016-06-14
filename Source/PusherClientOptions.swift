//
//  PusherClientOptions.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

public struct PusherClientOptions {
    public let userDataFetcher: (() -> PusherUserData)?
    public let authMethod: AuthMethod
    public let attemptToReturnJSONObject: Bool
    public let encrypted: Bool
    public let host: String
    public let port: Int
    public let autoReconnect: Bool
    public let authRequestCustomizer: ((endpoint: String, socket: String, channel: PusherChannel) -> NSMutableURLRequest)?
    public let debugLogger: ((String) -> ())?

    static var defaultOptions: PusherClientOptions = {
        return PusherClientOptions()
    }()
    
    public init(userDataFetcher: (() -> PusherUserData)? = nil, authMethod: AuthMethod = .NoMethod,
                attemptToReturnJSONObject: Bool = true, encrypted: Bool = true, host: String = "ws.pusherapp.com",
                port: Int? = nil, autoReconnect: Bool = true, authRequestCustomizer: ((endpoint: String, socket: String, channel: PusherChannel) -> NSMutableURLRequest)? = nil,
                debugLogger: ((String) -> ())? = nil) {
        self.userDataFetcher = userDataFetcher
        self.authMethod = authMethod
        self.attemptToReturnJSONObject = attemptToReturnJSONObject
        self.encrypted = encrypted
        self.host = host
        self.port = encrypted ? 443 : 80
        self.autoReconnect = autoReconnect
        self.authRequestCustomizer =  authRequestCustomizer
        self.debugLogger = debugLogger
    }
    
    public init(userDataFetcher: (() -> PusherUserData)? = nil, authMethod: AuthMethod = .NoMethod,
                attemptToReturnJSONObject: Bool = true, encrypted: Bool = true, cluster: String, port: Int? = nil,
                autoReconnect: Bool = true, authRequestCustomizer: ((endpoint: String, socket: String, channel: PusherChannel) -> NSMutableURLRequest)? = nil,
                debugLogger: ((String) -> ())? = nil) {
        self.init(userDataFetcher: userDataFetcher, authMethod: authMethod, attemptToReturnJSONObject: attemptToReturnJSONObject,
                  encrypted: encrypted, host: "ws-\(cluster).pusher.com", port: port, autoReconnect: autoReconnect,
                  authRequestCustomizer: authRequestCustomizer, debugLogger: debugLogger)
    }
}
