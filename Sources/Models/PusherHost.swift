import Foundation

public enum PusherHost {
    case host(String)
    case cluster(String)

    public static var defaultHost: Self {
        return .host(Constants.API.defaultHost)
    }

    public var stringValue: String {
        switch self {
        case .host(let host): return host
        case .cluster(let cluster): return "ws-\(cluster).\(Constants.API.pusherDomain)"
        }
    }
}
