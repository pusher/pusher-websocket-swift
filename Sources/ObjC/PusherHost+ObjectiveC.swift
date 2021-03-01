import Foundation

public extension PusherHost {
    func toObjc() -> OCPusherHost {
        switch self {
        case let .host(host):
            return OCPusherHost(host: host)

        case let .cluster(cluster):
            return OCPusherHost(cluster: "ws-\(cluster).\(Constants.API.pusherDomain)")
        }
    }

    static func fromObjc(source: OCPusherHost) -> PusherHost {
        switch source.type {
        case 0: return PusherHost.host(source.host!)
        case 1: return PusherHost.cluster(source.cluster!)
        default: return PusherHost.defaultHost
        }
    }
}
