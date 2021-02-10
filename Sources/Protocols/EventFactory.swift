import Foundation

protocol EventFactory {

    func makeEvent(fromJSON json: PusherEventPayload, withDecryptionKey decryptionKey: String?) throws -> PusherEvent
}
