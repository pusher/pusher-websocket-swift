import Foundation
import Combine

public extension Pusher {
    
    /// Creates a Publisher that can be used to stream global Pusher events.
    /// - Parameter eventName: The event that should be received. If nil, all
    /// events are received.
    /// - Returns: A Publisher for a global Pusher event.
    func publisher(eventName: String? = nil) -> GlobalEventPublisher {
        GlobalEventPublisher(pusher: self, eventName: eventName)
    }
    
    /// Creates a Publisher that can be used to stream events from a Pusher channel.
    /// - Parameters:
    ///   - channelName: The channel that should be bound to.
    ///   - eventName: The event that should be received.
    /// - Returns: A Publisher for a Pusher channel event.
    func publisher(channelName: String, eventName: String) -> ChannelEventPublisher {
        ChannelEventPublisher(pusher: self, channelName: channelName, eventName: eventName)
    }
    
    /// A Publisher for global Pusher events.
    struct GlobalEventPublisher: Publisher {
        
        public typealias Output = PusherEvent
        public typealias Failure = Never
        
        fileprivate var pusher: Pusher
        fileprivate var eventName: String?
        
        public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            let subscriptionType: SubscriptionType
            if let eventName = eventName {
                subscriptionType = .globalEvent(eventName: eventName, callbackId: nil)
            } else {
                subscriptionType = .global(callbackId: nil)
            }
            
            let subscription = EventSubscription<S>(
                subscriber: subscriber,
                pusher: pusher,
                subscriptionType: subscriptionType
            )
            subscriber.receive(subscription: subscription)
        }
    }
    
    /// A Publisher for channel-specific Pusher events.
    struct ChannelEventPublisher: Publisher {
        
        public typealias Output = PusherEvent
        public typealias Failure = Never
        
        fileprivate var pusher: Pusher
        fileprivate var channelName: String
        fileprivate var eventName: String
        
        public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
            let channel = pusher.subscribe(channelName)
            let subscription = EventSubscription<S>(
                subscriber: subscriber,
                pusher: pusher,
                subscriptionType: .channel(channel, eventName: eventName, callbackId: nil)
            )
            subscriber.receive(subscription: subscription)
        }
    }
    
    /// A Subscription that will bind to a Pusher event and notify the subscriber
    /// when the event fires.
    class EventSubscription<S: Subscriber>: Subscription where S.Input == PusherEvent {
        
        private var subscriber: S?
        private var subscriptionType: SubscriptionType
        private let pusher: Pusher
        
        fileprivate init(subscriber: S, pusher: Pusher, subscriptionType: SubscriptionType) {
            self.subscriber = subscriber
            self.subscriptionType = subscriptionType
            self.pusher = pusher
            self.subscriptionType.bind(with: pusher, callback: eventReceived(_:))
        }
        
        public func request(_ demand: Subscribers.Demand) {}
        
        public func cancel() {
            subscriptionType.unbind(with: pusher)
            subscriber = nil
        }
        
        func eventReceived(_ event: PusherEvent) {
            let _ = subscriber?.receive(event)
        }
    }
}

/// A type responsible for binding and unbinding to various types of Pusher events.
fileprivate enum SubscriptionType {
    
    /// All events broadcast globally.
    case global(callbackId: String?)
    
    /// Events matching `eventName` that are broadcast globally.
    case globalEvent(eventName: String, callbackId: String?)
    
    /// Channel-specific events.
    case channel(_: PusherChannel, eventName: String, callbackId: String?)
    
    mutating func bind(with pusher: Pusher, callback: @escaping (PusherEvent) -> Void) {
        switch self {
        case .global(.none):
            let callbackId = pusher.bind(eventCallback: callback)
            self = .global(callbackId: callbackId)
        case .global(_):
            return // Already bound.
            
        case .globalEvent(let eventName, .none):
            let callbackId = pusher.bind { event in
                guard eventName == event.eventName else { return }
                callback(event)
            }
            self = .globalEvent(eventName: eventName, callbackId: callbackId)
        case .globalEvent(_, _):
            return // Already bound.
            
        case .channel(let channel, let eventName, .none):
            let callbackId = channel.bind(eventName: eventName, eventCallback: callback)
            self = .channel(channel, eventName: eventName, callbackId: callbackId)
        case .channel(_, _, _):
            return // Already bound.
        }
        
        // Calling this multiple times is allowed by Pusher.
        pusher.connect()
    }
    
    func unbind(with pusher: Pusher) {
        switch self {
        case .global(.some(let callbackId)):
            pusher.unbind(callbackId: callbackId)
        case .global(.none):
            return // Not bound
            
        case .globalEvent(_, .some(let callbackId)):
            pusher.unbind(callbackId: callbackId)
        case .globalEvent(_, .none):
            return // Not bound
            
        case .channel(let channel, let eventName, .some(let callbackId)):
            channel.unbind(eventName: eventName, callbackId: callbackId)
        case .channel(_, _, .none):
            return // Not bound
        }
    }
}
