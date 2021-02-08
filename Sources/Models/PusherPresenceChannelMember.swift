import Foundation

@objcMembers
@objc public class PusherPresenceChannelMember: NSObject {
    public let userId: String
    public let userInfo: Any?

    public init(userId: String, userInfo: Any? = nil) {
        self.userId = userId
        self.userInfo = userInfo
    }
}
