import Foundation

@objc public enum ConnectionState: Int {
    case connecting
    case connected
    case disconnecting
    case disconnected
    case reconnecting

    static let connectionStates = [
        connecting: "connecting",
        connected: "connected",
        disconnecting: "disconnecting",
        disconnected: "disconnected",
        reconnecting: "reconnecting"
    ]

    public func stringValue() -> String {
        return ConnectionState.connectionStates[self]!
    }
}
