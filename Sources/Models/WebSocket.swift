import Foundation

/// Manages a websocket connection to a given server which can accept such connections.
open class WebSocket: NSObject, WebSocketConnection, URLSessionWebSocketDelegate {

    // MARK: - Public properties

    weak var delegate: WebSocketConnectionDelegate?

    // MARK: - Private properties

    private var webSocketTask: URLSessionWebSocketTask!
    private var urlSession: URLSession!
    private let delegateQueue = OperationQueue()
    private var pingTimer: Timer?

    // MARK: - Initialization

    init(request: URLRequest, connectAutomatically: Bool = false) {
        super.init()
        urlSession = URLSession(configuration: .default,
                                delegate: self,
                                delegateQueue: delegateQueue)
        webSocketTask = urlSession.webSocketTask(with: request)

        if connectAutomatically {
            connect()
        }
    }

    init(url: URL, connectAutomatically: Bool = false) {
        super.init()
        urlSession = URLSession(configuration: .default,
                                delegate: self,
                                delegateQueue: delegateQueue)
        webSocketTask = urlSession.webSocketTask(with: url)

        if connectAutomatically {
            connect()
        }
    }

    // MARK: - URLSessionWebSocketDelegate methods

    public func urlSession(_ session: URLSession,
                           webSocketTask: URLSessionWebSocketTask,
                           didOpenWithProtocol protocol: String?) {
        delegate?.webSocketDidConnect(connection: self)
    }

    public func urlSession(_ session: URLSession,
                           webSocketTask: URLSessionWebSocketTask,
                           didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                           reason: Data?) {
        delegate?.webSocketDidDisconnect(connection: self,
                                         closeCode: closeCode.rawValue,
                                         reason: reason)
    }

    // MARK: - WebSocketConnectionDelegate methods

    func connect() {
        webSocketTask.resume()
        listen()
    }

    func send(string: String) {
        send(message: .string(string))
    }

    func send(data: Data) {
        send(message: .data(data))
    }

    func listen() {
        webSocketTask.receive { [weak self] result in
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
        self.webSocketTask.sendPing { error in
            if let error = error {
                self.delegate?.webSocketDidReceiveError(connection: self, error: error)
            } else {
                self.delegate?.webSocketDidReceivePong(connection: self)
            }
        }
    }

    func disconnect(closeCode: Int = URLSessionWebSocketTask.CloseCode.normalClosure.rawValue) {
        let closeCode = URLSessionWebSocketTask.CloseCode(rawValue: closeCode) ?? .normalClosure
        webSocketTask.cancel(with: closeCode, reason: nil)
        pingTimer?.invalidate()
    }

    // MARK: - Private methods

    private func send(message: URLSessionWebSocketTask.Message) {
        webSocketTask.send(message) { [weak self] error in
            guard let self = self else {
                return
            }

            if let error = error {
                self.delegate?.webSocketDidReceiveError(connection: self, error: error)
            }
        }
    }
}
