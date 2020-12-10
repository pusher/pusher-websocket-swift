import Foundation

/// Used for logging events for informational purposes
internal class PusherLogger {

    // MARK: - Enum definitions

    internal enum LoggingEvent: String {

        // Channels

        // swiftlint:disable:next identifier_name
        case presenceChannelSubscriptionAttemptWithoutChannelData =
        "Attempting to subscribe to presence channel but no channelData value provided"
        case subscriptionSucceededNoDataInPayload = "Subscription succeeded event received without data key in payload"

        // Events

        case clientEventSent = "sendClientEvent"
        case eventSent = "sendEvent"
        case skippedEventAfterDecryptionFailure = "Skipping event that failed to decrypt on channel"

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

    internal enum LoggingLevel: String {
        case debug      = "[PUSHER DEBUG]"
        case info       = "[PUSHER INFO]"
        case warning    = "[PUSHER WARNING]"
        case error      = "[PUSHER ERROR]"
    }

    // MARK: - Event logging

    /// A debug message relating to a particular event of interest.
    /// - Parameters:
    ///   - event: A particular `LoggingEvent` of interest.
    ///   - context: Additional context for the message.
    /// - Returns: A `String` with information to log concerning the event.
    internal static func debug(for event: LoggingEvent,
                               context: CustomStringConvertible? = nil) -> String {
        return message(for: event, level: .debug, context: context)
    }

    /// An informational message relating to a particular event of interest.
    /// - Parameters:
    ///   - event: A particular `LoggingEvent` of interest.
    ///   - context: Additional context for the message.
    /// - Returns: A `String` with information to log concerning the event.
    internal static func info(for event: LoggingEvent,
                              context: CustomStringConvertible? = nil) -> String {
        return message(for: event, level: .info, context: context)
    }

    /// A warning message relating to a particular event of interest.
    /// - Parameters:
    ///   - event: A particular `LoggingEvent` of interest.
    ///   - context: Additional context for the message.
    /// - Returns: A `String` with information to log concerning the event.
    internal static func warning(for event: LoggingEvent,
                                 context: CustomStringConvertible? = nil) -> String {
        return message(for: event, level: .warning, context: context)
    }

    /// An error message relating to a particular event of interest.
    /// - Parameters:
    ///   - event: A particular `LoggingEvent` of interest.
    ///   - context: Additional context for the message.
    /// - Returns: A `String` with information to log concerning the event.
    internal static func error(for event: LoggingEvent,
                               context: CustomStringConvertible? = nil) -> String {
        return message(for: event, level: .error, context: context)
    }

    // MARK: - Private methods

    /// An informational message relating to a particular event of interest.
    /// - Parameter event: A particular `LoggingEvent` of interest.
    /// - Parameter level: The `LoggingLevel` to set for the message.
    /// - Parameter context: Additional context for the message.
    /// - Returns: A `String` with information to log concerning the event.
    private static func message(for event: LoggingEvent,
                                level: LoggingLevel,
                                context: CustomStringConvertible? = nil) -> String {
        var message = "\(level.rawValue) \(event.rawValue)"
        if let context = context {
            message += " \(context)"
        }

        return message
    }
}
