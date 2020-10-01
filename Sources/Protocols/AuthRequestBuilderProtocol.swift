import Foundation

@objc public protocol AuthRequestBuilderProtocol {
    @objc optional func requestFor(socketID: String, channelName: String) -> URLRequest?
}
