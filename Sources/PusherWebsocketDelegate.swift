import Foundation
import Starscream

extension PusherConnection: WebSocketDelegate {

    /**
        Delegate method called when a message is received over a websocket

        - parameter ws:   The websocket that has received the message
        - parameter text: The message received over the websocket
    */
    public func websocketDidReceiveMessage(socket ws: WebSocketClient, text: String) {
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
            guard let event = PusherEvent(jsonObject: payload) else {
                self.delegate?.debugLog?(message: "[PUSHER DEBUG] Unable to handle incoming event \(text)")
                return
            }
            self.handleEvent(event: event)
        }
    }

    /**
        Delegate method called when a websocket disconnected

        - parameter ws:    The websocket that disconnected
        - parameter error: The error, if one exists, when disconnected
    */
    public func websocketDidDisconnect(socket ws: WebSocketClient, error: Error?) {
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

        if let reachability = self.reachability, reachability.connection == .none {
            self.delegate?.debugLog?(message: "[PUSHER DEBUG] Network unreachable so reconnect likely to fail")
        }

        attemptReconnect()
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

    /**
        Delegate method called when a websocket connected

        - parameter ws:    The websocket that connected
    */
    public func websocketDidConnect(socket ws: WebSocketClient) {
        self.socketConnected = true
    }

    public func websocketDidReceiveData(socket ws: WebSocketClient, data: Data) {}
}

extension PusherConnection: WebSocketPongDelegate {

    public func websocketDidReceivePong(socket: WebSocketClient, data: Data?) {
        self.delegate?.debugLog?(message: "[PUSHER DEBUG] Websocket received pong")
        resetActivityTimeoutTimer()
    }

}
