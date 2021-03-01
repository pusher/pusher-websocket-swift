import Foundation

/// Used for logging events for informational purposes
class Logger {

    // MARK: - Enum definitions

    enum LoggingEvent: String {

        // Channels

        // swiftlint:disable:next identifier_name
        case presenceChannelSubscriptionAttemptWithoutChannelData =
                "Attempting to subscribe to presence channel but no channelData value provided"
        case subscriptionSucceededNoDataInPayload = "Subscription succeeded event received without data key in payload"
        case unableToSubscribeToChannel = "Unable to subscribe to channel:"
        case unableToAddMemberToChannel = "Unable to add member to channel"
        case unableToRemoveMemberFromChannel = "Unable to remove member from channel"
        case authInfoForCompletionHandlerIsNil = "Auth info passed to authorizer completionHandler was nil"
        case authenticationFailed = "Authentication failed. You may not be connected"
        case authValueOnSubscriptionNotSupported = """
            Passing an auth value to 'subscribe' is not supported for encrypted channels. \
            Event decryption will fail. You must use one of the following auth methods: \
            'endpoint', 'authRequestBuilder', 'authorizer'
            """

        // Events

        case clientEventSent = "sendClientEvent"
        case eventSent = "sendEvent"
        case skippedEventAfterDecryptionFailure = "Skipping event that failed to decrypt on channel"
        case cannotSendClientEventForChannel = "You must be subscribed to a private or presence channel to send client events"
        case clientEventsNotSupported = "Client events are not supported on encrypted channels:"

        // JSON parsing

        case unableToParseStringAsJSON = "Unable to parse string as JSON:"

        // Misc

        case genericError = ""

        // Network

        case networkConnectionViable = "Network connection became viable"
        case networkConnectionUnviable = "Network connection became unviable"

        // WebSocket

        case attemptReconnectionAfterWaiting = "Attempting to reconnect after waiting"
        case attemptReconnectionImmediately = "Attempting to reconnect immediately"
        case connectionEstablished = "Socket established with socket ID:"
        case disconnectionWithoutError = "Websocket is disconnected but no error received"
        case errorReceived = "Websocket received error."
        case intentionalDisconnection = "Deliberate disconnection - skipping reconnect attempts"
        case maxReconnectAttemptsLimitReached = "Max reconnect attempts reached"
        case pingSent = "Ping sent"
        case pongReceived = "Websocket received pong"
        case receivedMessage = "websocketDidReceiveMessage"
        case unableToHandleIncomingError = "Unable to handle incoming error"
        case unableToHandleIncomingMessage = "Unable to handle incoming Websocket message"
    }

    enum LoggingLevel: String {
        case debug      = "[PUSHER DEBUG]"
        case info       = "[PUSHER INFO]"
        case warning    = "[PUSHER WARNING]"
        case error      = "[PUSHER ERROR]"
    }

    static let shared = Logger()

    weak var delegate: PusherDelegate?

    // MARK: - Event logging

    /// Logs a debug message relating to a particular event of interest.
    /// - Parameters:
    ///   - event: A particular `LoggingEvent` of interest.
    ///   - context: Additional context for the message.
    func debug(for event: LoggingEvent,
               context: CustomStringConvertible? = nil) {
        message(for: event, level: .debug, context: context)
    }

    /// Logs an informational message relating to a particular event of interest.
    /// - Parameters:
    ///   - event: A particular `LoggingEvent` of interest.
    ///   - context: Additional context for the message.
    func info(for event: LoggingEvent,
              context: CustomStringConvertible? = nil) {
        message(for: event, level: .info, context: context)
    }

    /// Logs a warning message relating to a particular event of interest.
    /// - Parameters:
    ///   - event: A particular `LoggingEvent` of interest.
    ///   - context: Additional context for the message.
    func warning(for event: LoggingEvent,
                 context: CustomStringConvertible? = nil) {
        message(for: event, level: .warning, context: context)
    }

    /// Logs an error message relating to a particular event of interest.
    /// - Parameters:
    ///   - event: A particular `LoggingEvent` of interest.
    ///   - context: Additional context for the message.
    func error(for event: LoggingEvent,
               context: CustomStringConvertible? = nil) {
        message(for: event, level: .error, context: context)
    }

    // MARK: - Private methods

    /// Logs an informational message relating to a particular event of interest.
    /// - Parameter event: A particular `LoggingEvent` of interest.
    /// - Parameter level: The `LoggingLevel` to set for the message.
    /// - Parameter context: Additional context for the message.
    private func message(for event: LoggingEvent,
                         level: LoggingLevel,
                         context: CustomStringConvertible? = nil) {
        var message = "\(level.rawValue) \(event.rawValue)"
        if let context = context {
            message += " \(context)"
        }

        self.delegate?.debugLog?(message: message)
    }
}
