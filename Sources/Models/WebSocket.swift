import Foundation
import Network

open class WebSocket: WebSocketConnection {

    // MARK: - Public properties

    weak var delegate: WebSocketConnectionDelegate?

    // MARK: - Private properties

    private var connection: NWConnection?
    private let endpoint: NWEndpoint
    private let parameters: NWParameters
    private let connectionQueue: DispatchQueue
    private var pingTimer: Timer?

    private static let webSocketSubProtocol = "pusher-channels-protocol-\(PROTOCOL)"

    // MARK: - Initialization

    init(request: URLRequest,
         connectAutomatically: Bool = false,
         connectionQueue: DispatchQueue = .global(qos: .default)) {

        endpoint = .url(request.url!)

        if request.url?.scheme == "ws" {
            parameters = NWParameters.tcp
        } else {
            parameters = NWParameters.tls
        }

        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = true
        wsOptions.setSubprotocols([Self.webSocketSubProtocol])
        parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)

        self.connectionQueue = connectionQueue

        if connectAutomatically {
            connect()
        }
    }

    init(url: URL,
         connectAutomatically: Bool = false,
         connectionQueue: DispatchQueue = .global(qos: .default)) {

        endpoint = .url(url)

        if url.scheme == "ws" {
            parameters = NWParameters.tcp
        } else {
            parameters = NWParameters.tls
        }

        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = true
        wsOptions.setSubprotocols([Self.webSocketSubProtocol])
        parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)

        self.connectionQueue = connectionQueue

        if connectAutomatically {
            connect()
        }
    }

    // MARK: - WebSocketConnection conformance

    func connect() {
        if connection == nil {
            connection = NWConnection(to: endpoint, using: parameters)
        }
        connection?.stateUpdateHandler = stateDidChange(to:)
        listen()
        connection?.start(queue: connectionQueue)
    }

    func send(string: String) {
        guard let data = string.data(using: .utf8) else {
            return
        }
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "textContext", metadata: [metadata])

        send(data: data, context: context)
    }

    func send(data: Data) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .binary)
        let context = NWConnection.ContentContext(identifier: "binaryContext", metadata: [metadata])

        send(data: data, context: context)
    }

    func listen() {
        connection?.receiveMessage { [weak self] (data, context, _, error) in
            guard let self = self else {
                return
            }

            if let data = data, !data.isEmpty, let context = context {
                self.receiveMessage(data: data, context: context)
            }

            if let error = error {
                self.delegate?.webSocketDidReceiveError(connection: self, error: error)
            } else {
                self.listen()
            }
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
        let metadata = NWProtocolWebSocket.Metadata(opcode: .ping)
        metadata.setPongHandler(connectionQueue) { [weak self] error in
            guard let self = self else {
                return
            }

            self.delegate?.webSocketDidReceivePong(connection: self)

            if let error = error {
                self.delegate?.webSocketDidReceiveError(connection: self, error: error)
            }
        }
        let context = NWConnection.ContentContext(identifier: "pingContext", metadata: [metadata])

        send(data: Data(), context: context)
    }

    func disconnect(closeCode: NWProtocolWebSocket.CloseCode = .protocolCode(.normalClosure)) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .close)
        metadata.closeCode = closeCode
        let context = NWConnection.ContentContext(identifier: "closeContext", metadata: [metadata])

        send(data: nil, context: context)
        delegate?.webSocketDidDisconnect(connection: self, closeCode: closeCode, reason: nil)
    }

    // MARK: - Private methods

    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .ready:
            delegate?.webSocketDidConnect(connection: self)
        case .waiting(let error):
            delegate?.webSocketDidReceiveError(connection: self, error: error)
        case .failed(let error):
            stopConnection(error: error)
        case .setup:
            break
        case .preparing:
            break
        case .cancelled:
            stopConnection(error: nil)
        @unknown default:
            fatalError()
        }
    }

    private func receiveMessage(data: Data, context: NWConnection.ContentContext) {
        guard let metadata = context.protocolMetadata.first as? NWProtocolWebSocket.Metadata else {
            return
        }

        switch metadata.opcode {
        case .binary:
            self.delegate?.webSocketDidReceiveMessage(connection: self, data: data)
        case .cont:
            //
            break
        case .text:
            guard let string = String(data: data, encoding: .utf8) else {
                return
            }
            self.delegate?.webSocketDidReceiveMessage(connection: self, string: string)
        case .close:
            delegate?.webSocketDidDisconnect(connection: self,
                                             closeCode: metadata.closeCode,
                                             reason: data)
        case .ping:
            // SEE `autoReplyPing = true` in `init()`.
            break
        case .pong:
            // SEE `ping()` FOR PONG RECEIVE LOGIC.
            break
        @unknown default:
            fatalError()
        }
    }

    private func send(data: Data?, context: NWConnection.ContentContext) {
        connection?.send(content: data,
                         contentContext: context,
                         isComplete: true,
                         completion: .contentProcessed({ [weak self] error in
                            guard let self = self else {
                                return
                            }

                            if let error = error {
                                self.delegate?.webSocketDidReceiveError(connection: self, error: error)
                            }
                         }))
    }

    private func stopConnection(error: Error?) {
        if let error = error {
            delegate?.webSocketDidReceiveError(connection: self, error: error)
        }
        pingTimer?.invalidate()
        connection = nil
    }
}
