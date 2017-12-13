import Foundation

@objc public protocol Authorizer {
    @objc func fetchAuthValue(socketID: String, channelName: String, completionHandler: @escaping (PusherAuth?) -> ())
}
