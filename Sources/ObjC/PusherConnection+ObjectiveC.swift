import Foundation

@objc public extension PusherConnection {
    var OCReconnectAttemptsMax: NSNumber? {
        get {
            return reconnectAttemptsMax as NSNumber?
        }
        set(newValue) {
            reconnectAttemptsMax = newValue?.intValue
        }
    }

    var OCMaxReconnectGapInSeconds: NSNumber? {
        get {
            return maxReconnectGapInSeconds as NSNumber?
        }
        set(newValue) {
            maxReconnectGapInSeconds = newValue?.doubleValue
        }
    }
}
