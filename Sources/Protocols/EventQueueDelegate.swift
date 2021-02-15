import Foundation

protocol EventQueueDelegate: AnyObject {

    func eventQueue(_ eventQueue: EventQueue,
                    didReceiveEvent event: PusherEvent,
                    forChannelName channelName: String?)
    func eventQueue(_ eventQueue: EventQueue,
                    didFailToDecryptEventWithPayload payload: ChannelEventPayload,
                    forChannelName channelName: String)
    func eventQueue(_ eventQueue: EventQueue,
                    didReceiveInvalidEventWithPayload payload: ChannelEventPayload)
    func eventQueue(_ eventQueue: EventQueue,
                    reloadDecryptionKeySyncForChannel channel: PusherChannel)
}
