import Foundation
import Starscream

extension PusherConnection: WebSocketDelegate {

    /// Delegate method called when an event is received over a websocket.
    /// - Parameters:
    ///   - event: The event received over the websocket.
    ///   - client: The active `WebSocket` that will receive events.
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            self.socketConnected = true
        case .disconnected(let reason, let code):
            handleDisconnect(error: nil)
        case .text(let text):
            self.delegate?.debugLog?(message: "[PUSHER DEBUG] websocketDidReceiveMessage \(text)")

            guard let payload = PusherParser.getPusherEventJSON(from: text),
                let event = payload["event"] as? String
            else {
                self.delegate?.debugLog?(message: "[PUSHER DEBUG] Unable to handle incoming Websocket message \(text)")
                return
            }

            if event == "pusher:error" {
                guard let error = PusherError(jsonObject: payload) else {
                    self.delegate?.debugLog?(message: "[PUSHER DEBUG] Unable to handle incoming error \(text)")
                    return
                }
                self.handleError(error: error)
            } else {
                self.eventQueue.enqueue(json: payload)
            }
        case .binary(let data):
            break
        case .ping(let pingData):
            break
        case .pong(let pongData):
            self.delegate?.debugLog?(message: "[PUSHER DEBUG] Websocket received pong")
            resetActivityTimeoutTimer()
        case .viabilityChanged(let isViable):
            break
        case .reconnectSuggested(let shouldAttemptReconnect):
            if shouldAttemptReconnect {
                attemptReconnect()
            }
        case .cancelled:
            handleDisconnect(error: nil)
            break
        case .error(let error):
            handleDisconnect(error: error)
            break
        }
    }

    /**
        Attempt to reconnect triggered by a disconnection
    */
    internal func attemptReconnect() {
        guard connectionState != .connected else {
            return
        }

        guard reconnectAttemptsMax == nil || reconnectAttempts < reconnectAttemptsMax! else {
            return
        }

        if connectionState != .reconnecting {
            updateConnectionState(to: .reconnecting)
        }

        let reconnectInterval = Double(reconnectAttempts * reconnectAttempts)

        let timeInterval = maxReconnectGapInSeconds != nil ? min(reconnectInterval, maxReconnectGapInSeconds!)
                                                           : reconnectInterval

        if reconnectAttemptsMax != nil {
            self.delegate?.debugLog?(message: "[PUSHER DEBUG] Waiting \(timeInterval) seconds before attempting to reconnect (attempt \(reconnectAttempts + 1) of \(reconnectAttemptsMax!))")
        } else {
            self.delegate?.debugLog?(message: "[PUSHER DEBUG] Waiting \(timeInterval) seconds before attempting to reconnect (attempt \(reconnectAttempts + 1))")
        }

        reconnectTimer = Timer.scheduledTimer(
            timeInterval: timeInterval,
            target: self,
            selector: #selector(connect),
            userInfo: nil,
            repeats: false
        )
        reconnectAttempts += 1
    }

    internal func handleDisconnect(error: Error?) {
        // Handles setting channel subscriptions to unsubscribed wheter disconnection
        // is intentional or not
        if connectionState == .disconnecting || connectionState == .connected {
            for (_, channel) in self.channels.channels {
                channel.subscribed = false
            }
        }

        self.connectionEstablishedMessageReceived = false
        self.socketConnected = false

        updateConnectionState(to: .disconnected)

        guard !intentionalDisconnect else {
            self.delegate?.debugLog?(message: "[PUSHER DEBUG] Deliberate disconnection - skipping reconnect attempts")
            return
        }

        // Handle error (if any)

        if let error = error {
            self.delegate?.debugLog?(message: "[PUSHER DEBUG] Websocket is disconnected. Error (code: \((error as NSError).code)): \(error.localizedDescription)")
        } else {
            self.delegate?.debugLog?(message: "[PUSHER DEBUG] Websocket is disconnected but no error received")
        }

        // Attempt reconnect if possible

        guard self.options.autoReconnect else {
            return
        }

        guard reconnectAttemptsMax == nil || reconnectAttempts < reconnectAttemptsMax! else {
            self.delegate?.debugLog?(message: "[PUSHER DEBUG] Max reconnect attempts reached")
            return
        }

        if let reachability = self.reachability, reachability.connection == .unavailable {
            self.delegate?.debugLog?(message: "[PUSHER DEBUG] Network unreachable so reconnect likely to fail")
        }

        attemptReconnect()
    }
}
