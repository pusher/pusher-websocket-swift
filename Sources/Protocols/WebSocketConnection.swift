import Foundation

/// Defines a WebSocket connection.
public protocol WebSocketConnection {
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
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode)

    /// The WebSocket connection delegate.
    var delegate: WebSocketConnectionDelegate? { get set }
}

/// Defines a delegate for a WebSocket connection.
public protocol WebSocketConnectionDelegate: AnyObject {
    /// Tells the delegate that the WebSocket did connect successfully.
    /// - Parameter connection: The active `WebSocketConnection`.
    func webSocketDidConnect(connection: WebSocketConnection)

    /// Tells the delegate that the WebSocket did disconnect.
    /// - Parameters:
    ///   - connection: The `WebSocketConnection` that disconnected.
    ///   - closeCode: A `URLSessionWebSocketTask.CloseCode` describing how the connection closed.
    ///   - reason: Optional extra information explaining the disconnection. (Formatted as UTF-8 encoded `Data`).
    func webSocketDidDisconnect(connection: WebSocketConnection,
                                closeCode: URLSessionWebSocketTask.CloseCode,
                                reason: Data?)

    /// Tells the delegate that the WebSocket connection viability has changed.
    ///
    /// An example scenario of when this method would be called is a Wi-Fi connection being lost due to a device
    /// moving out of signal range, and then the method would be called again once the device moved back in range.
    /// - Parameters:
    ///   - connection: The `WebSocketConnection` whose viability has changed.
    ///   - isViable: A `Bool` indicating if the connection is viable or not.
    func webSocketViabilityDidChange(connection: WebSocketConnection,
                                     isViable: Bool)

    /// Tells the delegate that the WebSocket has attempted a migration based on a better network path becoming available.
    ///
    /// An example of when this method would be called is if a device is using a cellular connection, and a Wi-Fi connection
    /// becomes available. This method will also be called if a device loses a Wi-Fi connection, and a cellular connection is available.
    /// - Parameter result: A `Result` containing the `WebSocketConnection` if the migration was successful, or a
    /// `NWError` if the migration failed for some reason.
    func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketConnection, Error>)

    /// Tells the delegate that the WebSocket received an error.
    ///
    /// An error received by a WebSocket is not necessarily fatal.
    /// - Parameters:
    ///   - connection: The `WebSocketConnection` that received an error.
    ///   - error: The `Error` that was received.
    func webSocketDidReceiveError(connection: WebSocketConnection,
                                  error: Error)

    /// Tells the delegate that the WebSocket received a 'pong' from the server.
    /// - Parameter connection: The active `WebSocketConnection`.
    func webSocketDidReceivePong(connection: WebSocketConnection)

    /// Tells the delegate that the WebSocket received a `String` message.
    /// - Parameters:
    ///   - connection: The active `WebSocketConnection`.
    ///   - string: The UTF-8 formatted `String` that was received.
    func webSocketDidReceiveMessage(connection: WebSocketConnection,
                                    string: String)

    /// Tells the delegate that the WebSocket received a binary `Data` message.
    /// - Parameters:
    ///   - connection: The active `WebSocketConnection`.
    ///   - data: The `Data` that was received.
    func webSocketDidReceiveMessage(connection: WebSocketConnection,
                                    data: Data)
}
