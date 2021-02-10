import Foundation

@objc public extension PusherClientOptions {

    // initializer without legacy "attemptToReturnJSONObject"
    convenience init(
        ocAuthMethod authMethod: OCAuthMethod,
        autoReconnect: Bool = true,
        ocHost host: OCPusherHost = PusherHost.defaultHost.toObjc(),
        port: NSNumber? = nil,
        useTLS: Bool = true,
        activityTimeout: NSNumber? = nil
    ) {
        self.init(
            ocAuthMethod: authMethod,
            attemptToReturnJSONObject: true,
            autoReconnect: autoReconnect,
            ocHost: host,
            port: port,
            useTLS: useTLS,
            activityTimeout: activityTimeout
        )
    }

    convenience init(
        ocAuthMethod authMethod: OCAuthMethod,
        attemptToReturnJSONObject: Bool = true,
        autoReconnect: Bool = true,
        ocHost host: OCPusherHost = PusherHost.defaultHost.toObjc(),
        port: NSNumber? = nil,
        useTLS: Bool = true,
        activityTimeout: NSNumber? = nil
    ) {
        self.init(
            authMethod: AuthMethod.fromObjc(source: authMethod),
            attemptToReturnJSONObject: attemptToReturnJSONObject,
            autoReconnect: autoReconnect,
            host: PusherHost.fromObjc(source: host),
            port: port as? Int,
            useTLS: useTLS,
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
