import Foundation
import Network

internal class WebSocketServerConnection {

    // MARK: - Public properties

    let id: Int

    var didStopHandler: ((Error?) -> Void)? = nil
    var didReceiveStringHandler: ((String) -> ())? = nil
    var didReceiveDataHandler: ((Data) -> ())? = nil

    // MARK: - Private properties

    private static var nextID: Int = 0
    private let connection: NWConnection

    // MARK: - Lifecycle

    init(nwConnection: NWConnection) {
        connection = nwConnection
        id = Self.nextID
        Self.nextID += 1
    }

    deinit {
        print("deinit")
    }

    // MARK: - Public methods

    func start() {
        print("connection \(id) will start")
        connection.stateUpdateHandler = self.stateDidChange(to:)
        listen()
        connection.start(queue: .main)
    }

    func receiveMessage(data: Data, context: NWConnection.ContentContext) {
        guard let metadata = context.protocolMetadata.first as? NWProtocolWebSocket.Metadata else {
            return
        }

        switch metadata.opcode {
        case .binary:
            didReceiveDataHandler?(data)
        case .cont:
            //
            break
        case .text:
            guard let string = String(data: data, encoding: .utf8) else {
                return
            }
            didReceiveStringHandler?(string)
        case .close:
            //
            break
        case .ping:
            pong()
            break
        case .pong:
            //
            break
        @unknown default:
            fatalError()
        }
    }

    func send(string: String) {
        let metaData = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "textContext",
                                                  metadata: [metaData])
        self.send(data: string.data(using: .utf8), context: context)
    }

    func send(data: Data) {
        let metaData = NWProtocolWebSocket.Metadata(opcode: .binary)
        let context = NWConnection.ContentContext(identifier: "binaryContext",
                                                  metadata: [metaData])
        self.send(data: data, context: context)
    }

    func stop() {
        print("connection \(id) will stop")
    }

    // MARK: - Private methods

    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .setup:
            print("connection is setup.")
        case .waiting(let error):
            connectionDidReceiveError(error)
        case .preparing:
            print("connection is being establised.")
        case .ready:
            print("connection \(id) ready")
        case .cancelled:
            stopConnection(error: nil)
        case .failed(let error):
            stopConnection(error: error)
        @unknown default:
            fatalError()
        }
    }

    private func listen() {
        connection.receiveMessage() { (data, context, isComplete, error) in
            if let data = data, let context = context, !data.isEmpty {
                self.receiveMessage(data: data, context: context)
            }
            if let error = error {
                self.connectionDidReceiveError(error)
            } else {
                self.listen()
            }
        }
    }

    private func pong() {
        let metaData = NWProtocolWebSocket.Metadata(opcode: .pong)
        let context = NWConnection.ContentContext(identifier: "pongContext",
                                                  metadata: [metaData])
        self.send(data: Data(), context: context)
    }

    private func send(data: Data?, context: NWConnection.ContentContext) {
        self.connection.send(content: data,
                             contentContext: context,
                             isComplete: true,
                             completion: .contentProcessed( { error in
                                if let error = error {
                                    self.connectionDidReceiveError(error)
                                    return
                                }
                                print("connection \(self.id) did send, data: \(String(describing: data))")
                             }))
    }

    private func connectionDidReceiveError(_ error: NWError) {
        print("connection did receive error: \(error.debugDescription)")
    }

    private func stopConnection(error: Error?) {
        connection.stateUpdateHandler = nil
        if let didStopHandler = didStopHandler {
            self.didStopHandler = nil
            didStopHandler(error)
        }
        if let error = error {
            print("connection \(id) did fail, error: \(error)")
        } else {
            print("connection \(id) did end")
        }
    }
}

