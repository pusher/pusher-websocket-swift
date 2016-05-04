//
//  Mocks.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 07/04/2016.
//
//

import Foundation
import PusherSwift

public class MockWebSocket: WebSocket {
    let stubber = StubberForMocks()
    var callbackCheckString: String = ""
    var objectGivenToCallback: AnyObject? = nil

    init() {
        super.init(url: NSURL(string: "test")!)
    }

    public func appendToCallbackCheckString(str: String) {
        self.callbackCheckString += str
    }

    public func storeDataObjectGivenToCallback(data: AnyObject) {
        self.objectGivenToCallback = data
    }

    override public func connect() {
        stubber.stub(
            "connect",
            args: nil,
            functionToCall: {
                self.delegate?.websocketDidReceiveMessage(self, text: "{\"event\":\"pusher:connection_established\",\"data\":\"{\\\"socket_id\\\":\\\"45481.3166671\\\",\\\"activity_timeout\\\":120}\"}")
            }
        )
    }

    override public func disconnect(forceTimeout forceTimeout: NSTimeInterval? = nil) {
        stubber.stub(
            "disconnect",
            args: nil,
            functionToCall: {
                self.delegate?.websocketDidDisconnect(self, error: nil)
            }
        )
    }
    override public func writeString(str: String, completion: (() -> ())? = nil) {
        if str == "{\"data\":{\"channel\":\"test-channel\"},\"event\":\"pusher:subscribe\"}" || str == "{\"event\":\"pusher:subscribe\",\"data\":{\"channel\":\"test-channel\"}}" {
            stubber.stub(
                "writeString",
                args: [str],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"test-channel\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(str, elements: ["key:6aae8814fabd5285245422096705abbed64ea59614648814ffb0bf2dc5d19168", "private-channel", "pusher:subscribe"]) {
            stubber.stub(
                "writeString",
                args: [str],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-channel\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(str, elements: ["key:5ce61ee2b8594e22b66323913d7c7af9d8e815659365be3627733993f4ce3824", "presence-channel", "user_id", "45481.3166671", "pusher:subscribe"]) {
            stubber.stub(
                "writeString",
                args: [str],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"46123.486095\\\"],\\\"hash\\\":{\\\"46123.486095\\\":null}}}\",\"channel\":\"presence-channel\"}")
                }
            )
        } else if stringContainsElements(str, elements: ["key:e1d0947a10d6ff1a25990798910b2505687bb096e3e8b6c97eef02c6b1abb4c7", "private-channel", "pusher:subscribe"]) {
            stubber.stub(
                "writeString",
                args: [str],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-channel\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(str, elements: ["data", "testing client events", "private-channel", "client-test-event"]) {
            stubber.stub(
                "writeString",
                args: [str],
                functionToCall: nil
            )
        } else if stringContainsElements(str, elements: ["testKey123:12345678gfder78ikjbg", "private-test-channel", "pusher:subscribe"]) {
            stubber.stub(
                "writeString",
                args: [str],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-test-channel\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(str, elements: ["key:0d0d2e7c2cd967246d808180ef0f115dad51979e48cac9ad203928141f9e6a6f", "private-test-channel", "pusher:subscribe"]) {
            stubber.stub(
                "writeString",
                args: [str],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-test-channel\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(str, elements: ["test-channel", "pusher:unsubscribe"]) {
            stubber.stub(
                "writeString",
                args: [str],
                functionToCall: nil
            )
        } else if stringContainsElements(str, elements: ["testkey123:e5ee520a16348ced21be557e14ae70fcd1ae89f79d32d14d22a19049eaf56881", "presence-test", "user_id", "123", "pusher:subscribe", "user_info", "twitter", "hamchapman"]) {
            stubber.stub(
                "writeString",
                args: [str],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"123\\\"],\\\"hash\\\":{\\\"123\\\":{\\\"twitter\\\":\\\"hamchapman\\\"}}}}\",\"channel\":\"presence-test\"}")
                }
            )
        } else if stringContainsElements(str, elements: ["key:c2b53f001321bc088814f210fb63c259b464f590890eee2dde6387ea9b469a30", "presence-channel", "user_id", "123", "pusher:subscribe"]) {
            stubber.stub(
                "writeString",
                args: [str],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"123\\\"],\\\"hash\\\":{\\\"123\\\":{}}}}\",\"channel\":\"presence-channel\"}")
                }
            )
        }
    }
}

public func stringContainsElements(str: String, elements: [String]) -> Bool {
    var allElementsPresent = true
    for e in elements {
        if str.rangeOfString(e) == nil {
            allElementsPresent = false
        }
    }

    return allElementsPresent
}

public class MockPusherConnection: PusherConnection {
    let stubber = StubberForMocks()

    init(options: Dictionary<String, Any>? = nil) {
        let pusherClientOptions = PusherClientOptions(options: options)
        super.init(key: "key", socket: MockWebSocket(), url: "ws://blah.blah:80", options: pusherClientOptions)
    }

    override public func handleEvent(eventName: String, jsonObject: Dictionary<String,AnyObject>) {
        stubber.stub(
            "handleEvent",
            args: [eventName, jsonObject],
            functionToCall: { super.handleEvent(eventName, jsonObject: jsonObject) }
        )
    }
}

public class MockPusherChannel: PusherChannel {
    let stubber = StubberForMocks()

    init(name: String, connection: MockPusherConnection) {
        super.init(name: name, connection: connection)
    }

    override public func handleEvent(eventName: String, eventData: String) {
        stubber.stub(
            "handleEvent",
            args: [eventName, eventData],
            functionToCall: { super.handleEvent(eventName, eventData: eventData) }
        )
    }
}

public class TestConnectionStateChangeDelegate: ConnectionStateChangeDelegate {
    let stubber = StubberForMocks()

    public func connectionChange(old: ConnectionState, new: ConnectionState) {
        stubber.stub(
            "connectionChange",
            args: [old, new],
            functionToCall: nil
        )
    }
}

public class StubberForMocks {
    public var calls:[FunctionCall]
    public var responses:[String:AnyObject]

    init() {
        self.calls = []
        self.responses = [:]
    }

    public func stub(functionName:String, args:[Any]?, functionToCall: (() -> Any?)?) -> AnyObject? {
        calls.append(FunctionCall(name: functionName, args: args))
        if let response: AnyObject = responses[functionName] {
            return response
        } else if let functionToCall = functionToCall {
            functionToCall()
        }
        return nil
    }
}

public class FunctionCall {
    public let name:String
    public let args:[Any]?

    init(name:String, args:[Any]?) {
        self.name = name
        self.args = args
    }
}

class MockSession: NSURLSession {
    var completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?

    static var mockResponse: (data: NSData?, urlResponse: NSURLResponse?, error: NSError?) = (data: nil, urlResponse: nil, error: nil)

    override class func sharedSession() -> NSURLSession {
        return MockSession()
    }

    override func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask {
        self.completionHandler = completionHandler
        return MockTask(response: MockSession.mockResponse, completionHandler: completionHandler)
    }

    class MockTask: NSURLSessionDataTask {
        typealias Response = (data: NSData?, urlResponse: NSURLResponse?, error: NSError?)
        var mockResponse: Response
        let completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?

        init(response: Response, completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?) {
            self.mockResponse = response
            self.completionHandler = completionHandler
        }
        override func resume() {
            completionHandler!(mockResponse.data, mockResponse.urlResponse, mockResponse.error)
        }
    }
}
