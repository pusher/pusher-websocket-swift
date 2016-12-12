//
//  PusherWebsocketDelegate.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

extension PusherConnection: WebSocketDelegate {

    /**
        Delegate method called when a message is received over a websocket

        - parameter ws:   The websocket that has received the message
        - parameter text: The message received over the websocket
    */
    public func websocketDidReceiveMessage(ws: WebSocket, text: String) {
        self.debugLogger?("[PUSHER DEBUG] websocketDidReceiveMessage \(text)")
        if let pusherPayloadObject = getPusherEventJSONFromString(text), eventName = pusherPayloadObject["event"] as? String {
            self.handleEvent(eventName, jsonObject: pusherPayloadObject)
        } else {
            print("Unable to handle incoming Websocket message \(text)")
        }
    }

    /**
        Delegate method called when a websocket disconnected

        - parameter ws:    The websocket that disconnected
        - parameter error: The error, if one exists, when disconnected
    */
    public func websocketDidDisconnect(ws: WebSocket, error: NSError?) {
        // Handles setting channel subscriptions to unsubscribed wheter disconnection
        // is intentional or not
        if connectionState == .Disconnecting || connectionState == .Connected {
            for (_, channel) in self.channels.channels {
                channel.subscribed = false
            }
        }

        self.connectionEstablishedMessageReceived = false
        self.socketConnected = false

        // Handle error (if any)
        guard let error = error where error.code != Int(WebSocket.CloseCode.Normal.rawValue) else {
            self.debugLogger?("[PUSHER DEBUG] Deliberate disconnection - skipping reconnect attempts")
            return updateConnectionState(.Disconnected)
        }

        print("Websocket is disconnected. Error: \(error.localizedDescription)")
        // Attempt reconnect if possible

        guard self.options.autoReconnect else {
            return updateConnectionState(.Disconnected)
        }

        guard reconnectAttemptsMax == nil || reconnectAttempts < reconnectAttemptsMax! else {
            self.debugLogger?("[PUSHER DEBUG] Max reconnect attempts reached")
            return updateConnectionState(.Disconnected)
        }

        guard let reachability = self.reachability where reachability.isReachable() else {
            self.debugLogger?("[PUSHER DEBUG] Network unreachable so waiting to attempt reconnect")
            return updateConnectionState(.ReconnectingWhenNetworkBecomesReachable)
        }

        if connectionState != .Reconnecting {
            updateConnectionState(.Reconnecting)
        }
        self.debugLogger?("[PUSHER DEBUG] Network reachable so will setup reconnect attempt")

        attemptReconnect()
    }

    /**
        Attempt to reconnect triggered by a disconnection
    */
    internal func attemptReconnect() {
        guard connectionState != .Connected else {
            return
        }

        guard reconnectAttemptsMax == nil || reconnectAttempts < reconnectAttemptsMax! else {
            return
        }

        let reconnectInterval = Double(reconnectAttempts * reconnectAttempts)

        let timeInterval = maxReconnectGapInSeconds != nil ? min(reconnectInterval, maxReconnectGapInSeconds!)
                                                           : reconnectInterval

        if reconnectAttemptsMax != nil {
            self.debugLogger?("[PUSHER DEBUG] Waiting \(timeInterval) seconds before attempting to reconnect (attempt \(reconnectAttempts + 1) of \(reconnectAttemptsMax!))")
        } else {
            self.debugLogger?("[PUSHER DEBUG] Waiting \(timeInterval) seconds before attempting to reconnect (attempt \(reconnectAttempts + 1))")
        }

        reconnectTimer = NSTimer.scheduledTimerWithTimeInterval(
            timeInterval,
            target: self,
            selector: #selector(connect),
            userInfo: nil,
            repeats: false
        )
        reconnectAttempts += 1
    }


    public func websocketDidConnect(ws: WebSocket) {
        self.socketConnected = true
    }

    public func websocketDidReceiveData(ws: WebSocket, data: NSData) {}
}
