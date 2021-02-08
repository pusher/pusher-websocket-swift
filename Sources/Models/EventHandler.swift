import Foundation

public struct EventHandler {
    let id: String
    let callback: (PusherEvent) -> Void
}
