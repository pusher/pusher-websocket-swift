import Foundation

internal struct PusherParser {

    /**
     Parse a string to extract Pusher event information from it

     - parameter string: The string received over the websocket connection containing
     Pusher event information

     - returns: A dictionary of Pusher-relevant event data
     */

    static func getPusherEventJSON(from string: String) -> [String: AnyObject]? {
        let data = (string as NSString).data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)

        do {
            if let jsonData = data, let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: AnyObject] {
                return jsonObject
            } else {
                print("Unable to parse string from WebSocket: \(string)")
            }
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
        return nil
    }

    /**
     Parse a string to extract Pusher event data from it

     - parameter string: The data string received as part of a Pusher message

     - returns: The object sent as the payload part of the Pusher message
     */
    static func getEventDataJSON(from string: String) -> Any? {
        let data = (string as NSString).data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)

        do {
            if let jsonData = data, let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) {
                return jsonObject
            } else {
                print("Unable to parse string as JSON - check that your JSON is valid.")
            }
        }
        return nil
    }
}
