//
//  PusherClientOptions.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

public enum PusherHost {
    case Host(String)
    case Cluster(String)
    
    public var stringValue: String {
        switch self {
            case .Host(let host): return host
            case .Cluster(let cluster): return "ws-\(cluster).pusher.com"
        }
    }
}

public struct PusherClientOptions {
    public let authMethod: AuthMethod
    public let attemptToReturnJSONObject: Bool
    public let encrypted: Bool
    public let host: String
    public let port: Int
    public let autoReconnect: Bool

    public init(authMethod: AuthMethod = .NoMethod, attemptToReturnJSONObject: Bool = true, encrypted: Bool = true,
                host: PusherHost = .Host("ws.pusherapp.com"), port: Int? = nil, autoReconnect: Bool = true) {
        self.authMethod = authMethod
        self.attemptToReturnJSONObject = attemptToReturnJSONObject
        self.encrypted = encrypted
        self.host = host.stringValue
        self.port = encrypted ? 443 : 80
        self.autoReconnect = autoReconnect
    }
}
