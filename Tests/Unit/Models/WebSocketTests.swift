import XCTest
import Network

#if WITH_ENCRYPTION
    @testable import PusherSwiftWithEncryption
#else
    @testable import PusherSwift
#endif

// swiftlint:disable todo

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
    var pongExpectation: XCTestExpectation! {
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

    override func setUp() {
        super.setUp()

        socket = WebSocket(url: URL(string: "wss://echo.websocket.org")!)
        socket.delegate = self
    }

    func testConnect() {
        connectExpectation = XCTestExpectation(description: "connectExpectation")
        socket.connect()
        wait(for: [connectExpectation!], timeout: 1.0)
    }

    func testDisconnect() {
        disconnectExpectation = XCTestExpectation(description: "disconnectExpectation")
        socket.connect()
        wait(for: [disconnectExpectation], timeout: 1.0)
    }

    func testReceiveStringMessage() {
        stringMessageExpectation = XCTestExpectation(description: "stringMessageExpectation")
        socket.connect()
        socket.send(string: "This is a string message!")
        wait(for: [stringMessageExpectation], timeout: 1.0)
    }

    func testReceiveDataMessage() {
        dataMessageExpectation = XCTestExpectation(description: "dataMessageExpectation")
        socket.connect()
        socket.send(data: "This is a data message!".data(using: .utf8)!)
        wait(for: [dataMessageExpectation], timeout: 1.0)
    }

    func testReceivePong() {
        pongExpectation = XCTestExpectation(description: "pongExpectation")
        socket.connect()
        socket.ping()
        wait(for: [pongExpectation], timeout: 1.0)
    }

    func testReceiveError() {
        // Redefine socket with invalid path
        socket = WebSocket(url: URL(string: "wss://echo.websocket.org/abc")!)
        socket.delegate = self

        errorExpectation = XCTestExpectation(description: "errorExpectation")
        socket.connect()
        // TODO: TRIGGER ERROR
        wait(for: [errorExpectation!], timeout: 1.0)
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
        pongExpectation.fulfill()
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
