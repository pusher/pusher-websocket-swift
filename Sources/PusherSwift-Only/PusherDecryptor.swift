
class PusherDecryptor {

    static func decrypt(data dataAsString: String?, decryptionKey: String?) throws -> String? {
        return dataAsString
    }

    static func encryptedChannelWarning(forChannelName channelName: String) {
        if PusherEncryptionHelpers.isEncryptedChannel(channelName: channelName) {
            let error = """

            WARNING: You are subscribing to an encrypted channel: '\(channelName)' but this version of PusherSwift does not \
            support end-to-end encryption. Events will not be decrypted. You must import 'PusherSwiftWithEncryption' in \
            order for events to be decrypted. See https://github.com/pusher/pusher-websocket-swift for more information

            """
            print(error)
        }
    }
    
}
