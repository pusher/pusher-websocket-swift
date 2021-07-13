import Foundation
@testable import PusherSwift

// swiftlint:disable nesting

struct TestObjects {

    struct Event {

        struct Data {

            static let validDecryptionKey = "EOWC/ked3NtBDvEs9gFwk7x4oZEbH9I0Lz2qkopBxxs="

            static let badDecryptionKey = "00000000000000000000000000000000000000000000"

            // MARK: Valid payloads

            /// Encrypted form of: `{ "message": "hello world" }`
            static let encryptedJSONOne = """
            {
                "\(Constants.JSONKeys.nonce)": "4sVYwy4j/8dCcjyxtPCWyk19GaaViaW9",
                "\(Constants.JSONKeys.ciphertext)": "/GMESnFGlbNn01BuBjp31XYa3i9vZsGKR8fgR9EDhXKx3lzGiUD501A="
            }
            """

            /// `{ "message": "hello world" }`
            static let decryptedJSONOne = "{\"message\":\"hello world\"}"

            /// Encrypted form of: `{ "name": "freddy", "message": "hello" }`
            static let encryptedJSONTwo = """
            {
                "\(Constants.JSONKeys.nonce)": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm",
                "\(Constants.JSONKeys.ciphertext)": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
            }
            """

            /// `{ "name": "freddy", "message": "hello" }`
            static let decryptedJSONTwo = """
            {
                "name": "freddy",
                "message": "hello"
            }
            """

            /// `{ "test": "test_string", "and": "another" }`
            static let unencryptedJSON = """
            {
                "test": "test_string",
                "and": "another"
            }
            """

            // MARK: Invalid payloads

            static let undecryptableJSON = """
            {
                "\(Constants.JSONKeys.nonce)": "7w2hU5r5VMj3PGXXepgP6E/KgPob5o6t",
                "\(Constants.JSONKeys.ciphertext)": "FX0lJZu33f0dWPb89816ngn0l9NfJC5mFny6EQF6z25K+Ly5LFS9hP7XAC6s5pUoZqGXzC03FA=="
            }
            """

            static let missingNonceJSON = """
            {
                "\(Constants.JSONKeys.ciphertext)": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
            }
            """

            static let missingCiphertextJSON = """
            {
                "\(Constants.JSONKeys.nonce)": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm"
            }
            """

            static let badNonceJSON = """
            {
                "\(Constants.JSONKeys.nonce)": "00000000000000000000000000000000",
                "\(Constants.JSONKeys.ciphertext)": "ig9HfL7OKJ9TL97WFRG0xpuk9w0DXUJhLQlQbGf+ID9S3h15vb/fgDfsnsGxQNQDxw+i"
            }
            """

            static let badCiphertextJSON = """
            {
                "\(Constants.JSONKeys.nonce)": "Ew2lLeGzSefk8fyVPbwL1yV+8HMyIBrm",
                "\(Constants.JSONKeys.ciphertext)": "00000000000000000000000000000000000000000000000000000000000000000000"
            }
            """
        }

        static let clientEventName = "client-test-event"
        static let encryptedChannelName = "private-encrypted-channel"
        static let presenceChannelName = "presence-channel"
        static let privateChannelName = "private-channel"
        static let testChannelName = "test-channel"
        static let testEventName = "test-event"
        static let userEventName = "user-event"

        static func withJSON(name: String = testEventName,
                             channel: String = testChannelName,
                             data: String = Data.unencryptedJSON,
                             customKeyValuePair: (key: String, value: Any)? = nil) -> String {

            if let customKeyValuePair = customKeyValuePair {

                var customValue: Any!
                if customKeyValuePair.value is String {
                    customValue = (customKeyValuePair.value as! String).escaped
                } else if customKeyValuePair.value is NSNull {
                    customValue = "null"
                } else if customKeyValuePair.value is [String: Any],
                          let jsonStringData = try? JSONSerialization.data(withJSONObject: customKeyValuePair.value,
                                                                           options: []),
                          let jsonString = String(data: jsonStringData, encoding: .utf8) {
                    customValue = jsonString
                } else {
                    customValue = customKeyValuePair.value
                }

                return """
            {
                "\(Constants.JSONKeys.event)": "\(name)",
                "\(Constants.JSONKeys.channel)": "\(channel)",
                "\(Constants.JSONKeys.data)": \(data.removing(.whitespacesAndNewlines).escaped),
                \(customKeyValuePair.key.escaped): \(customValue!)
            }
            """
            } else {

                return """
            {
                "\(Constants.JSONKeys.event)": "\(name)",
                "\(Constants.JSONKeys.channel)": "\(channel)",
                "\(Constants.JSONKeys.data)": \(data.removing(.whitespacesAndNewlines).escaped)
            }
            """
            }
        }

        static let withoutChannelNameJSON = """
        {
            "\(Constants.JSONKeys.event)": "\(testEventName)",
            "\(Constants.JSONKeys.data)": \(Data.unencryptedJSON.removing(.whitespacesAndNewlines).escaped)
        }
        """

        static let withoutEventNameJSON = """
        {
            "\(Constants.JSONKeys.channel)": "\(testChannelName)",
            "\(Constants.JSONKeys.data)": \(Data.unencryptedJSON.removing(.whitespacesAndNewlines).escaped)
        }
        """

        static let withoutEventOrChannelNameJSON = """
        {
           "\(Constants.JSONKeys.data)": \(Data.unencryptedJSON.removing(.whitespacesAndNewlines).escaped)
        }
        """
    }
}
