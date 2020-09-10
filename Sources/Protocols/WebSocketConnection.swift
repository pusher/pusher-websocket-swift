import Network

/// Defines a websocket connection.
internal protocol WebSocketConnection {
    /// Connect to the websocket.
    func connect()

    /// Send a UTF-8 formatted `String` over the websocket.
    /// - Parameter string: The `String` that will be sent.
    func send(string: String)

    /// Send some `Data` over the websocket.
    /// - Parameter data: The `Data` that will be sent.
    func send(data: Data)

    /// Start listening for messages over the websocket.
    func listen()

    /// Ping the websocket periodically.
    /// - Parameter interval: The `TimeInterval` (in seconds) with which to ping the server.
    func ping(interval: TimeInterval)

    /// Ping the websocket once.
    func ping()

    /// Disconnect from the websocket.
    /// - Parameter closeCode: The code to use when closing the websocket connection.
    func disconnect(closeCode: NWProtocolWebSocket.CloseCode)

    var delegate: WebSocketConnectionDelegate? { get set }
}

/// Defines a delegate for a websocket connection.
internal protocol WebSocketConnectionDelegate: AnyObject {
    func webSocketDidConnect(connection: WebSocketConnection)
    func webSocketDidDisconnect(connection: WebSocketConnection,
                                closeCode: NWProtocolWebSocket.CloseCode,
                                reason: Data?)
    func webSocketDidReceiveError(connection: WebSocketConnection, error: Error)
    func webSocketDidReceivePong(connection: WebSocketConnection)
    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String)
    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data)
}
