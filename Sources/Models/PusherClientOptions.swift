import Foundation

@objcMembers
@objc public class PusherClientOptions: NSObject {
    public var authMethod: AuthMethod
    public let attemptToReturnJSONObject: Bool
    public let autoReconnect: Bool
    public let host: String
    public let port: Int
    public let path: String?
    public let useTLS: Bool
    public let activityTimeout: TimeInterval?

    @nonobjc public init(
        authMethod: AuthMethod = .noMethod,
        attemptToReturnJSONObject: Bool = true,
        autoReconnect: Bool = true,
        host: PusherHost = .defaultHost,
        port: Int? = nil,
        path: String? = nil,
        useTLS: Bool = true,
        activityTimeout: TimeInterval? = nil
    ) {
        self.authMethod = authMethod
        self.attemptToReturnJSONObject = attemptToReturnJSONObject
        self.autoReconnect = autoReconnect
        self.host = host.stringValue
        self.path = path
        self.port = port ?? (useTLS ? 443 : 80)
        self.useTLS = useTLS
        self.activityTimeout = activityTimeout
    }
}
