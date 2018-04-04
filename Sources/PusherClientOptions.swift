import Foundation

public enum PusherHost {
    case host(String)
    case cluster(String)

    public var stringValue: String {
        switch self {
            case .host(let host): return host
            case .cluster(let cluster): return "ws-\(cluster).pusher.com"
        }
    }
}

public enum AuthMethod {
    case endpoint(authEndpoint: String)
    case authRequestBuilder(authRequestBuilder: AuthRequestBuilderProtocol)
    case authorizer(authorizer: Authorizer)
    case inline(secret: String)
    case noMethod
}

@objcMembers
@objc public class PusherClientOptions: NSObject {
    public var authMethod: AuthMethod
    public let attemptToReturnJSONObject: Bool
    public let autoReconnect: Bool
    public let host: String
    public let port: Int
    public let encrypted: Bool
    public let activityTimeout: TimeInterval?

    @nonobjc public init(
        authMethod: AuthMethod = .noMethod,
        attemptToReturnJSONObject: Bool = true,
        autoReconnect: Bool = true,
        host: PusherHost = .host("ws.pusherapp.com"),
        port: Int? = nil,
        encrypted: Bool = true,
        activityTimeout: TimeInterval? = nil
    ) {
        self.authMethod = authMethod
        self.attemptToReturnJSONObject = attemptToReturnJSONObject
        self.autoReconnect = autoReconnect
        self.host = host.stringValue
        self.port = port ?? (encrypted ? 443 : 80)
        self.encrypted = encrypted
        self.activityTimeout = activityTimeout
    }
}
