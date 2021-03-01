import Foundation

struct AuthError: Error {
    enum Kind {
        case notConnected
        case noMethod
        case couldNotBuildRequest
        case invalidAuthResponse
        case requestFailure
    }

    let kind: Kind

    var message: String?

    var response: URLResponse?
    var data: String?
    var error: NSError?
}
