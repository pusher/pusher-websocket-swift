import XCTest
import Network
@testable import PusherSwift

class WebSocketClientTests: XCTestCase {
    static var socket: WebSocketClient!
    static var server: WebSocketServer!

    static var connectExpectation: XCTestExpectation? {
        didSet {
            Self.shouldDisconnectImmediately = false
        }
    }
    static var disconnectExpectation: XCTestExpectation! {
        didSet {
            Self.shouldDisconnectImmediately = true
        }
    }
    static var stringMessageExpectation: XCTestExpectation! {
        didSet {
            Self.shouldDisconnectImmediately = false
        }
    }
    static var dataMessageExpectation: XCTestExpectation! {
        didSet {
            Self.shouldDisconnectImmediately = false
        }
    }
    static var pongExpectation: XCTestExpectation? {
        didSet {
            Self.shouldDisconnectImmediately = false
        }
    }
    static var pingsWithIntervalExpectation: XCTestExpectation? {
        didSet {
            Self.shouldDisconnectImmediately = false
        }
    }
    static var errorExpectation: XCTestExpectation? {
        didSet {
            Self.shouldDisconnectImmediately = false
        }
    }

    static var shouldDisconnectImmediately: Bool!
    static var receivedPongTimestamps: [Date]!

    static let expectationTimeout = 5.0
    static let stringMessage = "This is a string message!"
    static let dataMessage = "This is a data message!".data(using: .utf8)!
    static let expectedReceivedPongsCount = 3
    static let repeatedPingInterval = 0.5
    static let validLocalhostServerPort: UInt16 = 3000
    static let invalidLocalhostServerPort: UInt16 = 2000

    override func setUp() {
        super.setUp()

        Self.server = WebSocketServer(port: Self.validLocalhostServerPort)
        try! Self.server.start()
        let serverURL = URL(string: "ws://localhost:\(Self.validLocalhostServerPort)")!
        Self.socket = WebSocketClient(url: serverURL, options: .default)
        Self.socket.delegate = self
        Self.receivedPongTimestamps = []
    }

    // MARK: - Test methods

    func testConnect() {
        Self.connectExpectation = XCTestExpectation(description: "connectExpectation")
        Self.socket.connect()
        wait(for: [Self.connectExpectation!], timeout: Self.expectationTimeout)
    }

    func testDisconnect() {
        Self.disconnectExpectation = XCTestExpectation(description: "disconnectExpectation")
        Self.socket.connect()
        wait(for: [Self.disconnectExpectation], timeout: Self.expectationTimeout)
    }

    func testReceiveStringMessage() {
        Self.stringMessageExpectation = XCTestExpectation(description: "stringMessageExpectation")
        Self.socket.connect()
        Self.socket.send(string: Self.stringMessage)
        wait(for: [Self.stringMessageExpectation], timeout: Self.expectationTimeout)
    }

    func testReceiveDataMessage() {
        Self.dataMessageExpectation = XCTestExpectation(description: "dataMessageExpectation")
        Self.socket.connect()
        Self.socket.send(data: Self.dataMessage)
        wait(for: [Self.dataMessageExpectation], timeout: Self.expectationTimeout)
    }

    func testReceivePong() {
        Self.pongExpectation = XCTestExpectation(description: "pongExpectation")
        Self.socket.connect()
        Self.socket.ping()
        wait(for: [Self.pongExpectation!], timeout: Self.expectationTimeout)
    }

    func testPingsWithInterval() {
        Self.pingsWithIntervalExpectation = XCTestExpectation(description: "pingsWithIntervalExpectation")
        Self.socket.connect()
        Self.socket.ping(interval: Self.repeatedPingInterval)
        wait(for: [Self.pingsWithIntervalExpectation!], timeout: Self.expectationTimeout)
    }

    func testReceiveError() {
        // Redefine socket with invalid path
        Self.socket = WebSocketClient(request: URLRequest(url: URL(string: "ws://localhost:\(Self.invalidLocalhostServerPort)")!))
        Self.socket.delegate = self

        Self.errorExpectation = XCTestExpectation(description: "errorExpectation")
        Self.socket.connect()
        wait(for: [Self.errorExpectation!], timeout: Self.expectationTimeout)
    }

}

// MARK: - WebSocketConnectionDelegate conformance

extension WebSocketClientTests: WebSocketConnectionDelegate {
    func webSocketDidConnect(connection: WebSocketConnection) {
        Self.connectExpectation?.fulfill()

        if Self.shouldDisconnectImmediately {
            Self.socket.disconnect()
        }
    }

    func webSocketDidDisconnect(connection: WebSocketConnection,
                                closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Self.disconnectExpectation?.fulfill()
    }

    func webSocketViabilityDidChange(connection: WebSocketConnection, isViable: Bool) {
        if isViable == false {
            XCTFail("WebSocket should not become unviable during testing.")
        }
    }

    func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketConnection, Error>) {
        XCTFail("WebSocket should not attempt to migrate to a better path during testing.")
    }

    func webSocketDidReceiveError(connection: WebSocketConnection, error: Error) {
        Self.errorExpectation?.fulfill()
    }

    func webSocketDidReceivePong(connection: WebSocketConnection) {
        Self.pongExpectation?.fulfill()

        guard Self.pingsWithIntervalExpectation != nil else {
            return
        }

        if Self.receivedPongTimestamps.count == Self.expectedReceivedPongsCount {
            Self.pingsWithIntervalExpectation?.fulfill()
        }
        Self.receivedPongTimestamps.append(Date())
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        XCTAssertEqual(string, Self.stringMessage)
        Self.stringMessageExpectation.fulfill()
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        XCTAssertEqual(data, Self.dataMessage)
        Self.dataMessageExpectation.fulfill()
    }
}

