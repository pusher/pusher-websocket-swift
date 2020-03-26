import Foundation
import Sodium

@objcMembers
open class PusherEvent: NSObject, NSCopying {
    
    private struct EncryptedData: Decodable {
        var nonce: String
        var ciphertext: String
    }
    
    /// The JSON object received from the websocket
    @nonobjc internal let raw: [String: Any]

    // According to Channels protocol, there is always an event https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol#events
    /// The name of the event.
    public lazy var eventName: String = { return raw["event"] as! String }()
    
    /// The name of the channel that the event was triggered on. Not present in events without an associated channel, e.g. "pusher:error" events relating to the connection.
    public lazy var channelName: String? = { return raw["channel"] as? String }()
    
    /// The data that was passed when the event was triggered.
    public lazy var data: String? = {
        if self.isEncryptedChannel && !self.isPusherSystemEvent {
            return self.decryptedString
        }
        return raw["data"] as? String
    }()
    
    /// The ID of the user who triggered the event. Only present in client event on presence channels.
    public lazy var userId: String? = { return raw["user_id"] as? String }()

    @nonobjc private lazy var isEncryptedChannel: Bool = {
        return channelName?.starts(with: "private-encrypted-") ?? false
    }()
    
    @nonobjc private lazy var isPusherSystemEvent: Bool = {
        return eventName.starts(with: "pusher:") || eventName.starts(with: "pusher_internal:")
    }()
    
    @nonobjc private lazy var decryptedString: String? = {
        guard
            let cipherText = self.cipherText,
            let secretKey = self.secretKey,
            let nonce = self.nonce,
            let decryptedData = sodium.secretBox.open(authenticatedCipherText: cipherText, secretKey: secretKey, nonce: nonce),
            let decryptedString = String(bytes: decryptedData, encoding: .utf8) else {
                return nil
        }
        return decryptedString
    }()
    
    @nonobjc private lazy var encryptedData: EncryptedData? = {
        guard let dataAsString = raw["data"] as? String,
            let dataAsData = dataAsString.data(using: .utf8),
            let encryptedData = try? JSONDecoder().decode(EncryptedData.self, from: dataAsData) else {
                return nil
        }
        return encryptedData
    }()
    
    @nonobjc private lazy var secretKey: SecretBox.Key? = {
        guard let keyProvider = self.keyProvider,
            let decodedKey = Data(base64Encoded: keyProvider.decryptionKey) else {
            return nil
        }
        return SecretBox.Key(decodedKey)
    }()
    
    @nonobjc private lazy var nonce: SecretBox.Nonce? = {
        guard let encryptedData = self.encryptedData,
            let decodedNonce = Data(base64Encoded: encryptedData.nonce) else {
            return nil
        }
        return SecretBox.Nonce(decodedNonce)
    }()
    
    @nonobjc private lazy var cipherText: Bytes? = {
        guard let encryptedData = self.encryptedData,
            let decodedCipherText = Data(base64Encoded: encryptedData.ciphertext) else {
            return nil
        }
        return Bytes(decodedCipherText)
    }()

    @nonobjc private let sodium = Sodium()
    @nonobjc private let keyProvider: PusherKeyProviding?
    
    @nonobjc internal init?(jsonObject: [String: Any], keyProvider: PusherKeyProviding? = nil) {
        // Every event must have a name
        if !(jsonObject["event"] is String) {
            return nil
        }
        self.raw = jsonObject
        self.keyProvider = keyProvider
    }

    /**
     Parse the data payload to a JSON object

     - returns: The JSON as Swift data types
    */
    @nonobjc internal func dataToJSONObject() -> Any? {
        guard let data = data else {
            return nil
        }
        // Parse or return nil if we can't parse
        return PusherParser.getEventDataJSON(from: data)
    }

    /**
     A helper function for accessing raw properties from the websocket event. Data
     returned by this function should not be considered stable and it is recommended
     that you use the properties of the `PusherEvent` instance instead e.g.
     `eventName`, `channelName` etc.

     - parameter key: The key of the property to be returned

     - returns: The property, if present
     */
    public func property(withKey key: String) -> Any? {
        return raw[key]
    }

    /**
     Creates a copy of the `PusherEvent` with an updated event name. This is useful
     when translating `pusher_internal:` events to `pusher:` events.

     - parameter eventName: The name of the new event

     - returns: The new `PusherEvent`
     */
    @nonobjc internal func copy(withEventName eventName: String) -> PusherEvent {
        var jsonObject = self.raw
        jsonObject["event"] = eventName
        return PusherEvent(jsonObject: jsonObject, keyProvider: self.keyProvider)!
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        return PusherEvent(jsonObject: self.raw, keyProvider: self.keyProvider)!
    }
}
