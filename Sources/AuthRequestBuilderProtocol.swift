import Foundation

@objc public protocol AuthRequestBuilderProtocol {
    @objc optional func requestFor(socketID: String, channelName: String) -> URLRequest?

    @available(*, deprecated: 4.0.2, message: "use requestFor(socketID: String, channelName: String) -> URLRequest? instead")
    @objc optional func requestFor(socketID: String, channel: PusherChannel) -> NSMutableURLRequest?
}
