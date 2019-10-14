import Foundation

@objc public protocol PusherDelegate: class {
    @objc optional func debugLog(message: String)

    @objc optional func changedConnectionState(from old: ConnectionState, to new: ConnectionState)
    @objc optional func subscribedToChannel(name: String)
    @objc optional func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?)
    @objc(receivedError:) optional func receivedError(error: PusherError)
}
