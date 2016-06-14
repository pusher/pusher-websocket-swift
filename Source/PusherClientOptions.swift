//
//  PusherClientOptions.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

public struct PusherClientOptions {
    public let authEndpoint: String?
    public let secret: String?
    public let userDataFetcher: (() -> PusherUserData)?
    public let authMethod: AuthMethod
    public let attemptToReturnJSONObject: Bool
    public let encrypted: Bool
    public let host: String
    public let port: Int?
    public let autoReconnect: Bool
    public let authRequestCustomizer: ((endpoint: String, socket: String, channel: PusherChannel) -> NSMutableURLRequest)?
    public let debugLogger: ((String) -> ())?

    static var defaultOptions: PusherClientOptions = {
        return PusherClientOptions()
    }()
    
    public init(authEndpoint: String? = nil, secret: String? = nil, userDataFetcher: (() -> PusherUserData)? = nil,
                authMethod: AuthMethod? = nil, attemptToReturnJSONObject: Bool = true, encrypted: Bool = true, host: String = "ws.pusherapp.com",
                port: Int? = nil, autoReconnect: Bool = true, authRequestCustomizer: ((endpoint: String, socket: String, channel: PusherChannel) -> NSMutableURLRequest)? = nil,
                debugLogger: ((String) -> ())? = nil) {
        self.init(authEndpoint: authEndpoint, secret: secret, userDataFetcher: userDataFetcher, authMethod: AuthMethod(endpoint: authEndpoint, secret: secret),
                  attemptToReturnJSONObject: attemptToReturnJSONObject, encrypted: encrypted, host: host,
                  port: port, autoReconnect: autoReconnect, authRequestCustomizer: authRequestCustomizer, debugLogger: debugLogger)
    }
    
    public init(authEndpoint: String? = nil, secret: String? = nil, userDataFetcher: (() -> PusherUserData)? = nil,
                attemptToReturnJSONObject: Bool = true, encrypted: Bool = true, cluster: String, port: Int? = nil,
                autoReconnect: Bool = true, authRequestCustomizer: ((endpoint: String, socket: String, channel: PusherChannel) -> NSMutableURLRequest)? = nil,
                debugLogger: ((String) -> ())? = nil) {
        self.init(authEndpoint: authEndpoint, secret: secret, userDataFetcher: userDataFetcher, authMethod: AuthMethod(endpoint: authEndpoint, secret: secret),
                  attemptToReturnJSONObject: attemptToReturnJSONObject, encrypted: encrypted, host: "ws-\(cluster).pusher.com",
                  port: port, autoReconnect: autoReconnect, authRequestCustomizer: authRequestCustomizer, debugLogger: debugLogger)
    }
    
    private init(authEndpoint: String?, secret: String?, userDataFetcher: (() -> PusherUserData)?, authMethod: AuthMethod,
                 attemptToReturnJSONObject: Bool, encrypted: Bool, host: String,
                 port: Int?, autoReconnect: Bool, authRequestCustomizer: ((endpoint: String, socket: String, channel: PusherChannel) -> NSMutableURLRequest)?,
                 debugLogger: ((String) -> ())?) {
        self.authEndpoint = authEndpoint
        self.secret = secret
        self.userDataFetcher = userDataFetcher
        self.authMethod = AuthMethod(endpoint: authEndpoint, secret: secret)
        self.attemptToReturnJSONObject = attemptToReturnJSONObject
        self.encrypted = encrypted
        self.host = host
        self.port = port
        self.autoReconnect = autoReconnect
        self.authRequestCustomizer =  authRequestCustomizer
        self.debugLogger = debugLogger
    }
}
