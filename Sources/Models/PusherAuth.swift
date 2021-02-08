import Foundation

@objc public class PusherAuth: NSObject {
    public let auth: String
    public let channelData: String?
    public let sharedSecret: String?

    public init(auth: String, channelData: String? = nil, sharedSecret: String? = nil) {
        self.auth = auth
        self.channelData = channelData
        self.sharedSecret = sharedSecret
    }
}
