import Foundation
import Network

/// Defines a WebSocket connection.
internal protocol WebSocketConnection {

    /// Connect to the WebSocket.
    func connect()

    /// Send a UTF-8 formatted `String` over the WebSocket.
    /// - Parameter string: The `String` that will be sent.
    func send(string: String)

    /// Send some `Data` over the WebSocket.
    /// - Parameter data: The `Data` that will be sent.
    func send(data: Data)

    /// Start listening for messages over the WebSocket.
    func listen()

    /// Ping the WebSocket periodically.
    /// - Parameter interval: The `TimeInterval` (in seconds) with which to ping the server.
    func ping(interval: TimeInterval)

    /// Ping the WebSocket once.
    func ping()

    /// Disconnect from the WebSocket.
    /// - Parameter closeCode: The code to use when closing the WebSocket connection.
    func disconnect(closeCode: NWProtocolWebSocket.CloseCode)

    var delegate: WebSocketConnectionDelegate? { get set }
}

/// Defines a delegate for a WebSocket connection.
internal protocol WebSocketConnectionDelegate: AnyObject {

    /// Called when the WebSocket has been established.
    /// - Parameter connection: The `WebSocketConnection`.
    func webSocketDidConnect(connection: WebSocketConnection)

    /// Called when the WebSocket has been disconnected.
    /// - Parameters:
    ///   - connection: The `WebSocketConnection`.
    ///   - closeCode: The `NWProtocolWebSocket.CloseCode` reported during the connection closure.
    ///   - reason: Optional informational `Data` reporting any addtional context for the closure.
    func webSocketDidDisconnect(connection: WebSocketConnection,
                                closeCode: NWProtocolWebSocket.CloseCode,
                                reason: Data?)

    /// Called when an error was received during the WebSocket connection lifetime.
    /// - Parameters:
    ///   - connection: The `WebSocketConnection`.
    ///   - error: The `Error` received by the `WebSocketConnection`.
    func webSocketDidReceiveError(connection: WebSocketConnection, error: Error)

    /// Called when the WebSocket received a 'Pong' message.
    /// - Parameter connection: The `WebSocketConnection`.
    func webSocketDidReceivePong(connection: WebSocketConnection)

    /// Called when the WebSocket received a message with UTF-8 encoded `String` data attached.
    /// - Parameters:
    ///   - connection: The `WebSocketConnection`.
    ///   - string: The `String` received in the message.
    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String)

    /// Called when the WebSocket received a message binary `Data` attached.
    /// - Parameters:
    ///   - connection: The `WebSocketConnection`.
    ///   - data: The `Data` received in the message.
    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data)
}
