import Foundation
import Network
import NWWebSocket

extension PusherConnection: WebSocketConnectionDelegate {

    /**
        Delegate method called when a message is received over a websocket

        - parameter connection:   The websocket that has received the message
        - parameter string: The message received over the websocket
    */
    public func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        Logger.shared.debug(for: .receivedMessage, context: string)

        guard let payload = EventParser.getPusherEventJSON(from: string),
            let event = payload[Constants.JSONKeys.event] as? String
        else {
            Logger.shared.debug(for: .unableToHandleIncomingMessage,
                                context: string)
            return
        }

        if event == Constants.Events.Pusher.error {
            guard let error = PusherError(jsonObject: payload) else {
                Logger.shared.debug(for: .unableToHandleIncomingError,
                                    context: string)
                return
            }
            self.handleError(error: error)
        } else {
            self.eventQueue.enqueue(json: payload)
        }
    }

    /// Delegate method called when a pong is received over a websocket
    /// - Parameter connection: The websocket that has received the pong
    public func webSocketDidReceivePong(connection: WebSocketConnection) {
        Logger.shared.debug(for: .pongReceived)
        resetActivityTimeoutTimer()
    }

    /**
     Delegate method called when a websocket disconnected

     - parameter connection: The websocket that disconnected
     - parameter closeCode: The closure code for the websocket connection.
     - parameter reason: Optional further information on the connection closure.
     */
    public func webSocketDidDisconnect(connection: WebSocketConnection,
                                       closeCode: NWProtocolWebSocket.CloseCode,
                                       reason: Data?) {
        // Handles setting channel subscriptions to unsubscribed whether disconnection
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
            Logger.shared.debug(for: .intentionalDisconnection)
            return
        }

        // Log the disconnection

        logDisconnection(closeCode: closeCode, reason: reason)

        // Attempt reconnect if possible

        // `autoReconnect` option is ignored if the closure code is within the 4000-4999 range
        if case .privateCode = closeCode {} else {
            guard self.options.autoReconnect else {
                return
            }
        }

        guard reconnectAttemptsMax == nil || reconnectAttempts < reconnectAttemptsMax! else {
            Logger.shared.debug(for: .maxReconnectAttemptsLimitReached)
            return
        }

        attemptReconnect(closeCode: closeCode)
    }

    public func webSocketViabilityDidChange(connection: WebSocketConnection, isViable: Bool) {
        if isViable {
            Logger.shared.debug(for: .networkConnectionViable)
        } else {
            Logger.shared.debug(for: .networkConnectionUnviable)
        }
    }

    public func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketConnection, NWError>) {
        switch result {
        case .success:
            updateConnectionState(to: .reconnecting)

        case .failure(let error):
            Logger.shared.debug(for: .errorReceived,
                                context: """
                Path migration error: \(error.debugDescription)
                """)
        }
    }

    /**
     Attempt to reconnect triggered by a disconnection.

     If the `closeCode` case is `.privateCode()`, then the reconnection logic is determined by
     `PusherChannelsProtocolCloseCode.ReconnectionStrategy`.
     - Parameter closeCode: The closure code received by the WebSocket connection.
     */
    func attemptReconnect(closeCode: NWProtocolWebSocket.CloseCode = .protocolCode(.normalClosure)) {
        guard connectionState != .connected else {
            return
        }

        guard reconnectAttemptsMax == nil || reconnectAttempts < reconnectAttemptsMax! else {
            return
        }

        // Reconnect attempt according to Pusher Channels Protocol close code (if present).
        // (Otherwise, the default behavior is to attempt reconnection after backing off).
        var channelsCloseCode: ChannelsProtocolCloseCode?
        if case let .privateCode(code) = closeCode {
            channelsCloseCode = ChannelsProtocolCloseCode(rawValue: code)
        }
        let strategy = channelsCloseCode?.reconnectionStrategy ?? .reconnectAfterBackingOff

        switch strategy {
        case .doNotReconnectUnchanged:
            // Return early without attempting reconnection
            return
        case .reconnectAfterBackingOff,
             .reconnectImmediately,
             .unknown:
            if connectionState != .reconnecting {
                updateConnectionState(to: .reconnecting)
            }

            logReconnectionAttempt(strategy: strategy)
        }

        reconnectTimer = Timer.scheduledTimer(
            timeInterval: reconnectionAttemptTimeInterval(strategy: strategy),
            target: self,
            selector: #selector(connect),
            userInfo: nil,
            repeats: false
        )
        reconnectAttempts += 1
    }

    /// Returns a `TimeInterval` appropriate for a reconnection attempt after some delay.
    /// - Parameter strategy: The reconnection strategy for the reconnection attempt.
    /// - Returns: An appropriate `TimeInterval`. (0.0 if `strategy == .reconnectImmediately`).
    func reconnectionAttemptTimeInterval(strategy: ChannelsProtocolCloseCode.ReconnectionStrategy) -> TimeInterval {
        if case .reconnectImmediately = strategy {
            return 0.0
        }

        let reconnectInterval = Double(reconnectAttempts * reconnectAttempts)

        return maxReconnectGapInSeconds != nil ?
            min(reconnectInterval, maxReconnectGapInSeconds!) : reconnectInterval
    }

    /// Logs the websocket reconnection attempt.
    /// - Parameter strategy: The reconnection strategy for the reconnection attempt.
    func logReconnectionAttempt(strategy: ChannelsProtocolCloseCode.ReconnectionStrategy) {

        var context = "(attempt \(reconnectAttempts + 1))"
        var loggingEvent = Logger.LoggingEvent.attemptReconnectionImmediately

        if reconnectAttemptsMax != nil {
            context.insert(contentsOf: " of \(reconnectAttemptsMax!)", at: context.index(before: context.endIndex))
        }

        if strategy != .reconnectImmediately {
            loggingEvent = .attemptReconnectionAfterWaiting
            let timeInterval = reconnectionAttemptTimeInterval(strategy: strategy)
            context = "\(timeInterval) seconds " + context
        }

        Logger.shared.debug(for: loggingEvent,
                            context: context)
    }

    /// Logs the websocket disconnection event.
    /// - Parameters:
    ///   - closeCode: The closure code for the websocket connection.
    ///   - reason: Optional further information on the connection closure.
    func logDisconnection(closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        var rawCode: UInt16!
        switch closeCode {
        case .protocolCode(let definedCode):
            rawCode = definedCode.rawValue

        case .applicationCode(let applicationCode):
            rawCode = applicationCode

        case .privateCode(let protocolCode):
            rawCode = protocolCode
        @unknown default:
            fatalError()
        }

        var closeMessage: String = "Close code: \(String(describing: rawCode))."
        if let reason = reason,
            let reasonString = String(data: reason, encoding: .utf8) {
            closeMessage += " Reason: \(reasonString)."
        }

        Logger.shared.debug(for: .disconnectionWithoutError,
                            context: closeMessage)
    }

    /**
        Delegate method called when a websocket connected

        - parameter connection:    The websocket that connected
    */
    public func webSocketDidConnect(connection: WebSocketConnection) {
        self.socketConnected = true
    }

    public func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        //
    }

    public func webSocketDidReceiveError(connection: WebSocketConnection, error: NWError) {
        Logger.shared.debug(for: .errorReceived,
                            context: """
            Error: \(error.debugDescription)
            """)
    }
}
