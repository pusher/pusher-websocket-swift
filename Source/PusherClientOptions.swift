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

public protocol AuthRequestBuilderProtocol {
    func requestFor(socketID: String, channel: PusherChannel) -> NSMutableURLRequest
}

public enum AuthMethod {
    case Endpoint(authEndpoint: String)
    case AuthRequestBuilder(authRequestBuilder: AuthRequestBuilderProtocol)
    case Internal(secret: String)
    case NoMethod
}

public struct PusherClientOptions {
    public let authMethod: AuthMethod
    public let attemptToReturnJSONObject: Bool
    public let autoReconnect: Bool
    public let host: String
    public let port: Int
    public let encrypted: Bool

    public init(
        authMethod: AuthMethod = .NoMethod,
        attemptToReturnJSONObject: Bool = true,
        autoReconnect: Bool = true,
        host: PusherHost = .Host("ws.pusherapp.com"),
        port: Int? = nil,
        encrypted: Bool = true) {
            self.authMethod = authMethod
            self.attemptToReturnJSONObject = attemptToReturnJSONObject
            self.autoReconnect = autoReconnect
            self.host = host.stringValue
            self.port = port ?? (encrypted ? 443 : 80)
            self.encrypted = encrypted
    }
}
