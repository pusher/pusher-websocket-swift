import Foundation

protocol EventQueue {

    var delegate: EventQueueDelegate? { get set }

    func enqueue(json: ChannelEventPayload)
}
