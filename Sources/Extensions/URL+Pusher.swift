import Foundation

extension URL {

    /// Creates a valid URL string that can be used in a connection attempt.
    /// - Parameters:
    ///   - key: The app key to be inserted into the URL.
    ///   - options: The collection of options needed to correctly construct the URL.
    /// - Returns: The constructed URL string, ready to use in a connection attempt.
    static func channelsSocketUrl(key: String, options: PusherClientOptions) -> String {
        var url = ""
        let additionalPathComponents = options.path ?? ""

        if options.useTLS {
            url = "wss://\(options.host):\(options.port)\(additionalPathComponents)/app/\(key)"
        } else {
            url = "ws://\(options.host):\(options.port)\(additionalPathComponents)/app/\(key)"
        }

        return "\(url)?client=\(CLIENT_NAME)&version=\(VERSION)&protocol=\(PROTOCOL)"
    }
}
