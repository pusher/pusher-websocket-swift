import Foundation

@objcMembers
@objc public class OCPusherHost: NSObject {
    var type: Int
    var host: String?
    var cluster: String?

    override public init() {
        self.type = 2
    }

    public init(host: String) {
        self.type = 0
        self.host = host
    }

    public init(cluster: String) {
        self.type = 1
        self.cluster = cluster
    }
}
