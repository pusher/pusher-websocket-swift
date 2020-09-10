import Network

/// Manages a websocket connection to a given server which can accept such connections.
open class WebSocket: NSObject, WebSocketConnection, URLSessionWebSocketDelegate {

    // MARK: - Public properties

    weak var delegate: WebSocketConnectionDelegate?

    // MARK: - Private properties

    private var webSocketTask: URLSessionWebSocketTask?
    private var webSocketRequest: URLRequest!
    private var urlSession: URLSession!
    private let delegateQueue = OperationQueue()
    private var pingTimer: Timer?

    // MARK: - Initialization

    init(request: URLRequest, connectAutomatically: Bool = false) {
        super.init()
        webSocketRequest = request
        configureConnection(connectAutomatically: connectAutomatically)
    }

    init(url: URL, connectAutomatically: Bool = false) {
        super.init()
        webSocketRequest = URLRequest(url: url)
        configureConnection(connectAutomatically: connectAutomatically)
    }

    // MARK: - URLSessionWebSocketDelegate conformance

    public func urlSession(_ session: URLSession,
                           webSocketTask: URLSessionWebSocketTask,
                           didOpenWithProtocol protocol: String?) {
        delegate?.webSocketDidConnect(connection: self)
    }

    public func urlSession(_ session: URLSession,
                           webSocketTask: URLSessionWebSocketTask,
                           didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                           reason: Data?) {
        // swiftlint:disable:next force_try
        let nwCloseCode = try! NWProtocolWebSocket.CloseCode(rawValue: UInt16(closeCode.rawValue))
        delegate?.webSocketDidDisconnect(connection: self,
                                         closeCode: nwCloseCode,
                                         reason: reason)
    }

    // MARK: - WebSocketConnection conformance

    func connect() {
        if webSocketTask == nil {
            webSocketTask = urlSession.webSocketTask(with: webSocketRequest)
        }

        webSocketTask?.resume()
        listen()
    }

    func send(string: String) {
        send(message: .string(string))
    }

    func send(data: Data) {
        send(message: .data(data))
    }

    func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .failure(let error):
                self.delegate?.webSocketDidReceiveError(connection: self, error: error)
            case .success(let message):
                switch message {
                case .string(let string):
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: string)
                case .data(let data):
                    self.delegate?.webSocketDidReceiveMessage(connection: self, data: data)
                @unknown default:
                    fatalError()
                }
            }

            // Recursive to continue listening for future messages on connection
            self.listen()
        }
    }

    func ping(interval: TimeInterval) {
        pingTimer = .scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else {
                return
            }

            self.ping()
        }
    }

    func ping() {
        self.webSocketTask?.sendPing { error in
            if let error = error {
                self.delegate?.webSocketDidReceiveError(connection: self, error: error)
            } else {
                self.delegate?.webSocketDidReceivePong(connection: self)
            }
        }
    }

    func disconnect(closeCode: NWProtocolWebSocket.CloseCode = .protocolCode(.normalClosure)) {

        var webSocketTaskCloseCode: URLSessionWebSocketTask.CloseCode!
        switch closeCode {
        case .protocolCode(let definedCode):
            webSocketTaskCloseCode = URLSessionWebSocketTask.CloseCode(rawValue: Int(definedCode.rawValue))
        case .applicationCode, .privateCode:
            webSocketTaskCloseCode = .normalClosure
        @unknown default:
            fatalError()
        }

        webSocketTask?.cancel(with: webSocketTaskCloseCode, reason: nil)
        webSocketTask = nil
        pingTimer?.invalidate()
    }

    // MARK: - Private methods

    private func configureConnection(connectAutomatically: Bool) {
        urlSession = URLSession(configuration: .default,
                                delegate: self,
                                delegateQueue: delegateQueue)

        if connectAutomatically {
            connect()
        }
    }

    private func send(message: URLSessionWebSocketTask.Message) {
        webSocketTask?.send(message) { [weak self] error in
            guard let self = self else {
                return
            }

            if let error = error {
                self.delegate?.webSocketDidReceiveError(connection: self, error: error)
            }
        }
    }
}
