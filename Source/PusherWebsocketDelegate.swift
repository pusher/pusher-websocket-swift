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
        if let pusherPayloadObject = getPusherEventJSONFromString(text), eventName = pusherPayloadObject["event"] as? String {
            self.handleEvent(eventName, jsonObject: pusherPayloadObject)
        } else {
            print("Unable to handle incoming Websocket message")
        }
    }

    /**
        Delegate method called when a websocket disconnected

        - parameter ws:    The websocket that disconnected
        - parameter error: The error, if one exists, when disconnected
    */
    public func websocketDidDisconnect(ws: WebSocket, error: NSError?) {
        if let error = error {
            print("Websocket is disconnected: \(error.localizedDescription)")
        }

        updateConnectionState(.Disconnected)
        for (_, channel) in self.channels.channels {
            channel.subscribed = false
        }
    }

    public func websocketDidConnect(ws: WebSocket) {}
    public func websocketDidReceiveData(ws: WebSocket, data: NSData) {}
}

