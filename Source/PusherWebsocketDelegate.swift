//
//  PusherWebsocketDelegate.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 01/04/2016.
//
//

extension PusherConnection: WebSocketDelegate {
    // MARK: WebSocketDelegate Implementation

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

        updateConnectionState(.Disconnected)
        for (_, channel) in self.channels.channels {
            channel.subscribed = false
        }
        
        // Handle error (if any)
        guard let error = error where error.code != Int(WebSocket.CloseCode.Normal.rawValue) else {
            return
        }
        
        print("Websocket is disconnected. Error: \(error.localizedDescription)")
        
        // Reconnect if possible
        if let reconnect = self.options.autoReconnect where reconnect {
            if let reachability = self.reachability where reachability.isReachable() {
                let operation = NSBlockOperation {
                    self.socket.connect()
                }

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC)), dispatch_get_main_queue()) {
                    NSOperationQueue.mainQueue().addOperation(operation)
                }

                self.reconnectOperation?.cancel()
                self.reconnectOperation = operation
            }
        }
    }

    public func websocketDidConnect(ws: WebSocket) {}
    public func websocketDidReceiveData(ws: WebSocket, data: NSData) {}
}

