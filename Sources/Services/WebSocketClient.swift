import Foundation

/// A WebSocket client that manages a socket connection.
open class WebSocketClient: WebSocketConnection {

    // MARK: - Public properties

    /// The WebSocket connection delegate.
    public weak var delegate: WebSocketConnectionDelegate?

    // MARK: - Private properties

    private var webSocketTask: URLSessionWebSocketTask?
    private let url: URL
    private let session: URLSession
    private let connectionQueue: DispatchQueue
    private var pingTimer: Timer?
    private var isConnected = false
    private var isIntentionalDisconnection = false
    private var errorWhileWaitingCount = 0
    private let errorWhileWaitingLimit = 20
    private var disconnectionWorkItem: DispatchWorkItem?
    private var activeListeners = Set<UUID>()

    // MARK: - Initialization

    /// Creates a `NWWebSocket` instance which connects to a socket `url`.
    /// - Parameters:
    ///   - request: The `URLRequest` containing the connection endpoint `URL`.
    ///   - connectAutomatically: Determines if a connection should occur automatically on initialization.
    ///                           The default value is `false`.
    ///   - connectionQueue: A `DispatchQueue` on which to deliver all connection events. The default value is `.main`.
    public convenience init(request: URLRequest,
                            options: URLSessionConfiguration = .default,
                            connectAutomatically: Bool = false,
                            connectionQueue: DispatchQueue = .main) {
        self.init(url: request.url!,
                  options: options,
                  connectAutomatically: connectAutomatically,
                  connectionQueue: connectionQueue)
    }

    /// Creates a `NWWebSocket` instance which connects to a socket `url`.
    /// - Parameters:
    ///   - url: The connection endpoint `URL`.
    ///   - connectAutomatically: Determines if a connection should occur automatically on initialization.
    ///                           The default value is `false`.
    ///   - connectionQueue: A `DispatchQueue` on which to deliver all connection events. The default value is `.main`.
    public init(url: URL,
                options: URLSessionConfiguration,
                connectAutomatically: Bool = false,
                connectionQueue: DispatchQueue = .main) {
        self.url = url
        self.connectionQueue = connectionQueue
        self.session = URLSession(configuration: options)

        if connectAutomatically {
            connect()
        }
    }

    deinit {
        disconnect(closeCode: .normalClosure)
    }

    // MARK: - WebSocketConnection conformance

    /// Connect to the WebSocket.
    open func connect() {
        guard !isConnected else { return }

        if webSocketTask != nil {
            disconnect(closeCode: .normalClosure)
        }

        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        activeListeners.removeAll()
        delegate?.webSocketDidConnect(connection: self)
        listen()
    }

    /// Send a UTF-8 formatted `String` over the WebSocket.
    /// - Parameter string: The `String` that will be sent.
    open func send(string: String) {
        let message = URLSessionWebSocketTask.Message.string(string)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                self?.delegate?.webSocketDidReceiveError(connection: self!, error: error)
            }
        }
    }

    /// Send some `Data` over the WebSocket.
    /// - Parameter data: The `Data` that will be sent.
    open func send(data: Data) {
        let message = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                self?.delegate?.webSocketDidReceiveError(connection: self!, error: error)
            }
        }
    }

    /// Start listening for messages over the WebSocket.
    public func listen() {
        guard isConnected else { return }

        let listenerId = UUID()
        activeListeners.insert(listenerId)

        webSocketTask?.receive { [weak self] result in
            guard let self = self,
                  self.isConnected,
                  self.activeListeners.contains(listenerId) else { return }

            switch result {
            case .success(let message):
                switch message {
                case .string(let string):
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: string)
                case .data(let data):
                    self.delegate?.webSocketDidReceiveMessage(connection: self, data: data)
                @unknown default:
                    break
                }

                if self.isConnected && self.activeListeners.contains(listenerId) {
                    self.listen()
                }

            case .failure(let error):
                self.delegate?.webSocketDidReceiveError(connection: self, error: error)
                if !self.isIntentionalDisconnection {
                    self.disconnect(closeCode: .abnormalClosure)
                }
            }
        }
    }

    /// Ping the WebSocket periodically.
    /// - Parameter interval: The `TimeInterval` (in seconds) with which to ping the server.
    open func ping(interval: TimeInterval) {
        pingTimer = .scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.ping()
        }
        pingTimer?.tolerance = 0.01
    }

    /// Ping the WebSocket once.
    open func ping() {
        webSocketTask?.sendPing { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.delegate?.webSocketDidReceiveError(connection: self, error: error)
            } else {
                self.delegate?.webSocketDidReceivePong(connection: self)
            }
        }
    }

    /// Disconnect from the WebSocket.
    /// - Parameter closeCode: The code to use when closing the WebSocket connection.
    open func disconnect(closeCode: URLSessionWebSocketTask.CloseCode = .normalClosure) {
        guard isConnected || webSocketTask != nil else { return }

        isIntentionalDisconnection = true
        isConnected = false

        activeListeners.removeAll()

        pingTimer?.invalidate()
        pingTimer = nil

        webSocketTask?.cancel(with: closeCode, reason: nil)
        webSocketTask = nil

        connectionQueue.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.webSocketDidDisconnect(connection: self,
                                                closeCode: closeCode,
                                                reason: nil)
            self.isIntentionalDisconnection = false
        }
    }
}


