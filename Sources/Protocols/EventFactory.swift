import Foundation

protocol EventFactory {

    func makeEvent(fromJSON json: ChannelEventPayload, withDecryptionKey decryptionKey: String?) throws -> PusherEvent
}
