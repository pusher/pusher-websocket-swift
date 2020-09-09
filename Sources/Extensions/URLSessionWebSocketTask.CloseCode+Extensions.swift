import Foundation

internal extension URLSessionWebSocketTask.CloseCode {

    // MARK: - Pusher Channels Protocol close codes

    /// Describes closure codes as specified by the Pusher Channels Protocol
    ///
    /// Reference: https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol#error-codes
    enum PusherChannelsProtocol: Int {

        // 4000 - 4099
        case applicationOnlyAcceptsSSLConnections   = 4000
        case applicationDoesNotExist                = 4001
        case applicationDisabled                    = 4003
        case applicationIsOverConnectionQuota       = 4004
        case pathNotFound                           = 4005
        case invalidVersionStringFormat             = 4006
        case unsupportedProtocolVersion             = 4007
        case noProtocolVersionSupplied              = 4008
        case connectionIsUnauthorized               = 4009

        // 4100 - 4199
        case overCapacity                           = 4100

        // 4200 - 4299
        case genericReconnectImmediately            = 4200

        /// Ping was sent to the client, but no reply was received
        case pongReplyNotReceived                   = 4201

        /// Client has been inactive for a long time (currently 24 hours)
        /// and client does not support ping.
        case closedAfterInactivity                  = 4202

        // 4300 - 4399
        case clientEventRejectedDueToRateLimit      = 4300

        var reconnectionStrategy: PusherChannelsReconnectionStrategy {
            return PusherChannelsReconnectionStrategy(rawValue: self.rawValue)
        }
    }

    // MARK: - Pusher Channels Protocol reconnection strategies

    /// Describes the reconnection strategy for a given `PusherChannelsProtocol` closure code.
    ///
    /// Reference: https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol#connection-closure
    enum PusherChannelsReconnectionStrategy: Int {

        /// Indicates an error resulting in the connection being closed by Pusher Channels,
        /// and that attempting to reconnect using the same parameters will not succeed.
        case doNotReconnectUnchanged

        /// Indicates an error resulting in the connection being closed by Pusher Channels,
        /// and that the client may reconnect after 1s or more.
        case reconnectAfterBackingOff

        /// Indicates an error resulting in the connection being closed by Pusher Channels,
        /// and that the client may reconnect immediately.
        case reconnectImmediately

        /// Indicates any other type of error in the connection being closed by Pusher Channels,
        /// and the client may reconnect if appropriate.
        case reconnectIfAppropriate

        /// Indicates that the reconnection strategy is unknown due to the closure code being
        /// outside of the expected range as specified by the Pusher Channels Protocol.
        case unknown

        init(rawValue: Int) {
            switch rawValue {
            case 4000...4099:
                self = .doNotReconnectUnchanged
            case 4100...4199:
                self = .reconnectAfterBackingOff
            case 4200...4299:
                self = .reconnectImmediately
            case 4300...4399:
                self = .reconnectIfAppropriate
            default:
                self = .unknown
            }
        }
    }
}
