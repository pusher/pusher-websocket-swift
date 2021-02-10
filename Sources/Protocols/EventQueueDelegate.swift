import Foundation

protocol EventQueueDelegate: AnyObject {

    func eventQueue(_ eventQueue: EventQueue,
                    didReceiveEvent event: PusherEvent,
                    forChannelName channelName: String?)
    func eventQueue(_ eventQueue: EventQueue,
                    didFailToDecryptEventWithPayload payload: PusherEventPayload,
                    forChannelName channelName: String)
    func eventQueue(_ eventQueue: EventQueue,
                    didReceiveInvalidEventWithPayload payload: PusherEventPayload)
    func eventQueue(_ eventQueue: EventQueue,
                    reloadDecryptionKeySyncForChannel channel: PusherChannel)
}
