import Foundation
import Network

extension PusherConnection: WebSocketConnectionDelegate {

    /**
        Delegate method called when a message is received over a websocket

        - parameter connection:   The websocket that has received the message
        - parameter string: The message received over the websocket
    */
    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        self.delegate?.debugLog?(message: PusherLogger.debug(for: .receivedMessage, context: string))

        guard let payload = PusherParser.getPusherEventJSON(from: string),
            let event = payload[Constants.JSONKeys.event] as? String
        else {
            self.delegate?.debugLog?(message: PusherLogger.debug(for: .unableToHandleIncomingMessage, context: string))
            return
        }

        if event == Constants.Events.Pusher.error {
            guard let error = PusherError(jsonObject: payload) else {
                self.delegate?.debugLog?(message: PusherLogger.debug(for: .unableToHandleIncomingError,
                                                                     context: string))
                return
            }
            self.handleError(error: error)
        } else {
            self.eventQueue.enqueue(json: payload)
        }
    }

    /// Delegate method called when a pong is received over a websocket
    /// - Parameter connection: The websocket that has received the pong
    func webSocketDidReceivePong(connection: WebSocketConnection) {
        self.delegate?.debugLog?(message: PusherLogger.debug(for: .pongReceived))
        resetActivityTimeoutTimer()
    }

    /**
     Delegate method called when a websocket disconnected

     - parameter connection: The websocket that disconnected
     - parameter closeCode: The closure code for the websocket connection.
     - parameter reason: Optional further information on the connection closure.
     */
    func webSocketDidDisconnect(connection: WebSocketConnection,
                                closeCode: NWProtocolWebSocket.CloseCode,
                                reason: Data?) {
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
            self.delegate?.debugLog?(message: PusherLogger.debug(for: .intentionalDisconnection))
            return
        }

        // Log the disconnection

        self.delegate?.debugLog?(message: PusherLogger.debug(for: .disconnectionWithoutError))

        // Attempt reconnect if possible

        guard self.options.autoReconnect else {
            return
        }

        guard reconnectAttemptsMax == nil || reconnectAttempts < reconnectAttemptsMax! else {
            self.delegate?.debugLog?(message: PusherLogger.debug(for: .maxReconnectAttemptsLimitReached))
            return
        }

        if let reachability = self.reachability, reachability.connection == .unavailable {
            self.delegate?.debugLog?(message: PusherLogger.debug(for: .reconnectionFailureLikely))
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
            let message = PusherLogger.debug(for: .attemptReconnectionAfterWaiting,
                                             context: "\(timeInterval) seconds (attempt \(reconnectAttempts + 1) of \(reconnectAttemptsMax!))")
            self.delegate?.debugLog?(message: message)
        } else {
            let message = PusherLogger.debug(for: .attemptReconnectionAfterWaiting,
                                             context: "\(timeInterval) seconds (attempt \(reconnectAttempts + 1))")
            self.delegate?.debugLog?(message: message)
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

        - parameter connection:    The websocket that connected
    */
    func webSocketDidConnect(connection: WebSocketConnection) {
        self.socketConnected = true
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        //
    }

    func webSocketDidReceiveError(connection: WebSocketConnection, error: Error) {
        self.delegate?.debugLog?(message: PusherLogger.debug(for: .errorReceived,
                                                             context: "Error (code: \((error as NSError).code)): \(error.localizedDescription)"))
    }
}
