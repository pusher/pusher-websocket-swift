import Foundation

@objc public extension Pusher {
    func subscribe(channelName: String) -> PusherChannel {
        return self.subscribe(channelName, onMemberAdded: nil, onMemberRemoved: nil)
    }

    func subscribe(
        channelName: String,
        onMemberAdded: ((PusherPresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((PusherPresenceChannelMember) -> ())? = nil
    ) -> PusherChannel {
        return self.subscribe(channelName, auth: nil, onMemberAdded: onMemberAdded, onMemberRemoved: onMemberRemoved)
    }

    func subscribeToPresenceChannel(channelName: String) -> PusherPresenceChannel {
        return self.subscribeToPresenceChannel(channelName: channelName, auth: nil, onMemberAdded: nil, onMemberRemoved: nil)
    }

    func subscribeToPresenceChannel(
        channelName: String,
        onMemberAdded: ((PusherPresenceChannelMember) -> ())? = nil,
        onMemberRemoved: ((PusherPresenceChannelMember) -> ())? = nil
    ) -> PusherPresenceChannel {
        return self.subscribeToPresenceChannel(channelName: channelName, auth: nil, onMemberAdded: onMemberAdded, onMemberRemoved: onMemberRemoved)
    }

    convenience init(withAppKey key: String, options: PusherClientOptions) {
        self.init(key: key, options: options)
    }

    convenience init(withKey key: String) {
        self.init(key: key)
    }
}

@objc public extension PusherConnection {
    var OCReconnectAttemptsMax: NSNumber? {
        get {
            return reconnectAttemptsMax as NSNumber?
        }
        set(newValue) {
            reconnectAttemptsMax = newValue?.intValue
        }
    }

    var OCMaxReconnectGapInSeconds: NSNumber? {
        get {
            return maxReconnectGapInSeconds as NSNumber?
        }
        set(newValue) {
            maxReconnectGapInSeconds = newValue?.doubleValue
        }
    }
}

@objc public extension PusherClientOptions {

    // initializer without legacy "attemptToReturnJSONObject"
    convenience init(
        ocAuthMethod authMethod: OCAuthMethod,
        autoReconnect: Bool = true,
        ocHost host: OCPusherHost = PusherHost.host("ws.pusherapp.com").toObjc(),
        port: NSNumber? = nil,
        encrypted: Bool = true,
        activityTimeout: NSNumber? = nil
    ) {
        self.init(
            ocAuthMethod: authMethod,
            attemptToReturnJSONObject: true,
            autoReconnect: autoReconnect,
            ocHost: host,
            port: port,
            encrypted: encrypted,
            activityTimeout: activityTimeout
        )
    }

    convenience init(
        ocAuthMethod authMethod: OCAuthMethod,
        attemptToReturnJSONObject: Bool = true,
        autoReconnect: Bool = true,
        ocHost host: OCPusherHost = PusherHost.host("ws.pusherapp.com").toObjc(),
        port: NSNumber? = nil,
        encrypted: Bool = true,
        activityTimeout: NSNumber? = nil
    ) {
        self.init(
            authMethod: AuthMethod.fromObjc(source: authMethod),
            attemptToReturnJSONObject: attemptToReturnJSONObject,
            autoReconnect: autoReconnect,
            host: PusherHost.fromObjc(source: host),
            port: port as? Int,
            encrypted: encrypted,
            activityTimeout: activityTimeout as? TimeInterval
        )
    }

    convenience init(authMethod: OCAuthMethod) {
        self.init(authMethod: AuthMethod.fromObjc(source: authMethod))
    }

    func setAuthMethod(authMethod: OCAuthMethod) {
        self.authMethod = AuthMethod.fromObjc(source: authMethod)
    }
}


public extension PusherHost {
    func toObjc() -> OCPusherHost {
        switch self {
        case let .host(host):
            return OCPusherHost(host: host)
        case let .cluster(cluster):
            return OCPusherHost(cluster: "ws-\(cluster).pusher.com")
        }
    }

    static func fromObjc(source: OCPusherHost) -> PusherHost {
        switch (source.type) {
        case 0: return PusherHost.host(source.host!)
        case 1: return PusherHost.cluster(source.cluster!)
        default: return PusherHost.host("ws.pusherapp.com")
        }
    }
}

@objcMembers
@objc public class OCPusherHost: NSObject {
    var type: Int
    var host: String? = nil
    var cluster: String? = nil

    public override init() {
        self.type = 2
    }

    public init(host: String) {
        self.type = 0
        self.host = host
    }

    public init(cluster: String) {
        self.type = 1
        self.cluster = cluster
    }
}

public extension AuthMethod {
    func toObjc() -> OCAuthMethod {
        switch self {
        case let .endpoint(authEndpoint):
            return OCAuthMethod(authEndpoint: authEndpoint)
        case let .authRequestBuilder(authRequestBuilder):
            return OCAuthMethod(authRequestBuilder: authRequestBuilder)
        case let .inline(secret):
            return OCAuthMethod(secret: secret)
        case let .authorizer(authorizer):
            return OCAuthMethod(authorizer: authorizer)
        case .noMethod:
            return OCAuthMethod(type: 4)
        }
    }

    static func fromObjc(source: OCAuthMethod) -> AuthMethod {
        switch (source.type) {
        case 0: return AuthMethod.endpoint(authEndpoint: source.authEndpoint!)
        case 1: return AuthMethod.authRequestBuilder(authRequestBuilder: source.authRequestBuilder!)
        case 2: return AuthMethod.inline(secret: source.secret!)
        case 3: return AuthMethod.authorizer(authorizer: source.authorizer!)
        case 4: return AuthMethod.noMethod
        default: return AuthMethod.noMethod
        }
    }
}

@objcMembers
@objc public class OCAuthMethod: NSObject {
    var type: Int
    var secret: String? = nil
    var authEndpoint: String? = nil
    var authRequestBuilder: AuthRequestBuilderProtocol? = nil
    var authorizer: Authorizer? = nil

    public init(type: Int) {
        self.type = type
    }

    public init(authEndpoint: String) {
        self.type = 0
        self.authEndpoint = authEndpoint
    }

    public init(authRequestBuilder: AuthRequestBuilderProtocol) {
        self.type = 1
        self.authRequestBuilder = authRequestBuilder
    }

    public init(secret: String) {
        self.type = 2
        self.secret = secret
    }

    public init(authorizer: Authorizer) {
        self.type = 3
        self.authorizer = authorizer
    }
}

public extension PusherError {
    /// The error code as an NSNumber (for Objective-C compatibility).
    var codeOC: NSNumber? {
        if let code = code {
            return NSNumber(value: code)
        } else {
            return nil
        }
    }
}
