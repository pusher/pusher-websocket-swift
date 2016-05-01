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
    public let authMethod: AuthMethod?
    public let attemptToReturnJSONObject: Bool?
    public let encrypted: Bool?
    public let host: String?
    public let port: Int?
    public let autoReconnect: Bool?
    public let authRequestCustomizer: (NSMutableURLRequest -> NSMutableURLRequest)?

    /**
        Initializes a new PusherClientOptions instance, optionally with a provided options dictionary

        - parameter options: An optional dictionary of client options

        - returns: A new PusherClientOptions instance
    */
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
