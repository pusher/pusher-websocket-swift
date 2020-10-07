import XCTest
import Network

#if WITH_ENCRYPTION
    @testable import PusherSwiftWithEncryption
#else
    @testable import PusherSwift
#endif

class WebSocketTests: XCTestCase {
    var socket: WebSocket!

    var connectExpectation: XCTestExpectation? {
        didSet {
            shouldDisconnectImmediately = false
        }
    }
    var disconnectExpectation: XCTestExpectation! {
        didSet {
            shouldDisconnectImmediately = true
        }
    }
    var stringMessageExpectation: XCTestExpectation! {
        didSet {
            shouldDisconnectImmediately = false
        }
    }
    var dataMessageExpectation: XCTestExpectation! {
        didSet {
            shouldDisconnectImmediately = false
        }
    }
    var pongExpectation: XCTestExpectation? {
        didSet {
            shouldDisconnectImmediately = false
        }
    }
    var pingsWithIntervalExpectation: XCTestExpectation? {
        didSet {
            shouldDisconnectImmediately = false
        }
    }
    var errorExpectation: XCTestExpectation? {
        didSet {
            shouldDisconnectImmediately = false
        }
    }

    var shouldDisconnectImmediately: Bool!
    var receivedPongTimestamps = [Date]()
    static let expectationTimeout = 5.0
    static let repeatedPingInterval = 1.0

    override func setUp() {
        super.setUp()

        socket = WebSocket(url: URL(string: "wss://echo.websocket.org")!)
        socket.delegate = self
    }

    // MARK: - Test methods

    func testConnect() {
        connectExpectation = XCTestExpectation(description: "connectExpectation")
        socket.connect()
        wait(for: [connectExpectation!], timeout: Self.expectationTimeout)
    }

    func testDisconnect() {
        disconnectExpectation = XCTestExpectation(description: "disconnectExpectation")
        socket.connect()
        wait(for: [disconnectExpectation], timeout: Self.expectationTimeout)
    }

    func testReceiveStringMessage() {
        stringMessageExpectation = XCTestExpectation(description: "stringMessageExpectation")
        socket.connect()
        socket.send(string: "This is a string message!")
        wait(for: [stringMessageExpectation], timeout: Self.expectationTimeout)
    }

    func testReceiveDataMessage() {
        dataMessageExpectation = XCTestExpectation(description: "dataMessageExpectation")
        socket.connect()
        socket.send(data: "This is a data message!".data(using: .utf8)!)
        wait(for: [dataMessageExpectation], timeout: Self.expectationTimeout)
    }

    func testReceivePong() {
        pongExpectation = XCTestExpectation(description: "pongExpectation")
        socket.connect()
        socket.ping()
        wait(for: [pongExpectation!], timeout: Self.expectationTimeout)
    }

    func testPingsWithInterval() {
        pingsWithIntervalExpectation = XCTestExpectation(description: "pingsWithIntervalExpectation")
        socket.connect()
        socket.ping(interval: Self.repeatedPingInterval)
        wait(for: [pingsWithIntervalExpectation!], timeout: Self.expectationTimeout * 2)
    }

    func testReceiveError() {
        // Redefine socket with invalid path
        socket = WebSocket(request: URLRequest(url: URL(string: "wss://echo.websocket.org/abc")!))
        socket.delegate = self

        errorExpectation = XCTestExpectation(description: "errorExpectation")
        socket.connect()
        wait(for: [errorExpectation!], timeout: Self.expectationTimeout)
    }

}

// MARK: - WebSocketConnectionDelegate conformance

extension WebSocketTests: WebSocketConnectionDelegate {

    func webSocketDidConnect(connection: WebSocketConnection) {
        connectExpectation?.fulfill()

        if shouldDisconnectImmediately {
            socket.disconnect()
        }
    }

    func webSocketDidDisconnect(connection: WebSocketConnection,
                                closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        disconnectExpectation.fulfill()
    }

    func webSocketDidReceiveError(connection: WebSocketConnection, error: Error) {
        errorExpectation?.fulfill()
    }

    func webSocketDidReceivePong(connection: WebSocketConnection) {
        pongExpectation?.fulfill()

        guard pingsWithIntervalExpectation != nil else {
            return
        }

        if receivedPongTimestamps.count == 5 {
            let timestampOffsets = zip(receivedPongTimestamps.dropFirst(), receivedPongTimestamps).map { $0.timeIntervalSince($1) }
            for offset in timestampOffsets {
                XCTAssertEqual(offset, Self.repeatedPingInterval, accuracy: 0.1)
            }
            pingsWithIntervalExpectation?.fulfill()
        }
        receivedPongTimestamps.append(Date())
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        XCTAssertEqual(string, "This is a string message!")
        stringMessageExpectation.fulfill()
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        XCTAssertEqual(data, "This is a data message!".data(using: .utf8))
        dataMessageExpectation.fulfill()
    }
}
