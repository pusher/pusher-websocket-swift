import Foundation

public extension PusherError {
    /// The error code as an NSNumber (for Objective-C compatibility).
    var codeOC: NSNumber? {
        guard let code = code else {
            return nil
        }

        return NSNumber(value: code)
    }
}
