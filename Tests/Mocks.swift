//
//  Mocks.swift
//  PusherSwift
//
//  Created by Hamilton Chapman on 07/04/2016.
//
//

import PusherSwift

open class MockWebSocket: WebSocket {
    let stubber = StubberForMocks()
    var callbackCheckString: String = ""
    var objectGivenToCallback: Any? = nil

    init() {
        super.init(url: URL(string: "test")!)
    }

    open func appendToCallbackCheckString(_ str: String) {
        self.callbackCheckString += str
    }

    open func storeDataObjectGivenToCallback(_ data: Any) {
        self.objectGivenToCallback = data
    }

    open override func connect() {
        let connectionEstablishedString = "{\"event\":\"pusher:connection_established\",\"data\":\"{\\\"socket_id\\\":\\\"45481.3166671\\\",\\\"activity_timeout\\\":120}\"}"
        let _ = stubber.stub(
            functionName: "connect",
            args: nil,
            functionToCall: {
                if let delegate = self.delegate {
                    delegate.websocketDidReceiveMessage(socket: self, text: connectionEstablishedString)
                    delegate.websocketDidConnect(socket: self)
                } else {
                    print("Your socket delegate is nil")
                }
            }
        )
    }

    open override func disconnect(forceTimeout: TimeInterval? = nil, closeCode: UInt16 = CloseCode.normal.rawValue) {
        let _ = stubber.stub(
            functionName: "disconnect",
            args: nil,
            functionToCall: {
                self.delegate?.websocketDidDisconnect(socket: self, error: nil)
            }
        )
    }

    open override func write(string: String, completion: (() -> ())? = nil) {
        if string == "{\"data\":{\"channel\":\"test-channel\"},\"event\":\"pusher:subscribe\"}" || string == "{\"event\":\"pusher:subscribe\",\"data\":{\"channel\":\"test-channel\"}}" {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(socket: self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"test-channel\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["testkey123:6aae8814fabd5285245422096705abbed64ea59614648814ffb0bf2dc5d19168", "private-channel", "pusher:subscribe"]) {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(socket: self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-channel\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["key:5ce61ee2b8594e22b66323913d7c7af9d8e815659365be3627733993f4ce3824", "presence-channel", "user_id", "45481.3166671", "pusher:subscribe"]) {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(socket: self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"46123.486095\\\"],\\\"hash\\\":{\\\"46123.486095\\\":null}}}\",\"channel\":\"presence-channel\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["testkey123:5ce61ee2b8594e22b66323913d7c7af9d8e815659365be3627733993f4ce3824", "presence-channel", "user_id", "45481.3166671", "pusher:subscribe"]) {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(socket: self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"46123.486095\\\"],\\\"hash\\\":{\\\"46123.486095\\\":null}}}\",\"channel\":\"presence-channel\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["key:e1d0947a10d6ff1a25990798910b2505687bb096e3e8b6c97eef02c6b1abb4c7", "private-channel", "pusher:subscribe"]) {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(socket: self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-channel\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["data", "testing client events", "private-channel", "client-test-event"]) {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: nil
            )
        } else if stringContainsElements(string, elements: ["testKey123:12345678gfder78ikjbg", "private-test-channel", "pusher:subscribe"]) {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(socket: self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-test-channel\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["pusher:subscribe", "testKey123:12345678gfder78ikjbgmanualauth", "private-manual-auth"]) {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(socket: self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-manual-auth\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["pusher:subscribe", "testKey123:12345678gfder78ikjbgmanualauth", "presence-manual-auth"]) {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(socket: self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"presence-manual-auth\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"16\\\"],\\\"hash\\\":{\\\"16\\\":{\\\"twitter\\\":\\\"hamchapman\\\"}}}}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["key:0d0d2e7c2cd967246d808180ef0f115dad51979e48cac9ad203928141f9e6a6f", "private-test-channel", "pusher:subscribe"]) {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(socket: self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-test-channel\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["private-reservations-for-venue@venue_id=399edd2d-3f4a-43k9-911c-9e4b6bdf0f16;date=2017-01-13", "pusher:subscribe", "testKey123:12345678gfder78ikjbg"]) {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(socket: self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-reservations-for-venue@venue_id=399edd2d-3f4a-43k9-911c-9e4b6bdf0f16;date=2017-01-13\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["test-channel", "pusher:unsubscribe"]) {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: nil
            )
        } else if stringContainsElements(string, elements: ["testkey123:736f0b19c2e56f985f3e6faa38db5b69d39305bc8519952c8f9f5595d69fcb3d", "presence-test", "user_id", "123", "pusher:subscribe", "user_info", "twitter", "hamchapman"]) {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(socket: self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"123\\\"],\\\"hash\\\":{\\\"123\\\":{\\\"twitter\\\":\\\"hamchapman\\\"}}}}\",\"channel\":\"presence-test\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["key:c2b53f001321bc088814f210fb63c259b464f590890eee2dde6387ea9b469a30", "presence-channel", "user_id", "123", "pusher:subscribe"]) {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(socket: self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"123\\\"],\\\"hash\\\":{\\\"123\\\":{}}}}\",\"channel\":\"presence-channel\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["pusher:subscribe", "key:dd2885ee6dc6f5c964d8e3c720980397db50bf8f528e0630d4208bff80ee23f0", "presence-channel", "friends", "0", "user_id", "123"]) {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(socket: self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"123\\\"],\\\"hash\\\":{\\\"123\\\":{\\\"friends\\\":0}}}}\",\"channel\":\"presence-channel\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["pusher:subscribe", "testKey123:authorizerblah123", "private-test-channel-authorizer"]) {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(socket: self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-test-channel-authorizer\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["pusher:subscribe", "testKey123:authorizerblah1234", "presence-test-channel-authorizer"]) {
            let _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.websocketDidReceiveMessage(socket: self, text: "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"777\\\"],\\\"hash\\\":{\\\"777\\\":{\\\"twitter\\\":\\\"hamchapman\\\"}}}}\",\"channel\":\"presence-test-channel-authorizer\"}")
                }
            )
        } else {
            print("No match in write(string: ...) mock for string: \(string)")
        }
    }
}

public func stringContainsElements(_ str: String, elements: [String]) -> Bool {
    var allElementsPresent = true
    for e in elements {
        if str.range(of: e) == nil {
            allElementsPresent = false
        }
    }

    return allElementsPresent
}

open class MockPusherConnection: PusherConnection {
    let stubber = StubberForMocks()

    init(options: PusherClientOptions = PusherClientOptions()) {
        super.init(key: "key", socket: MockWebSocket(), url: "ws://blah.blah:80", options: options)
    }

    open override func handleEvent(eventName: String, jsonObject: [String: AnyObject]) {
        let _ = stubber.stub(
            functionName: "handleEvent",
            args: [eventName, jsonObject],
            functionToCall: { super.handleEvent(eventName: eventName, jsonObject: jsonObject) }
        )
    }
}

open class StubberForMocks {
    open var calls: [FunctionCall]
    open var responses: [String: AnyObject]

    init() {
        self.calls = []
        self.responses = [:]
    }

    open func stub(functionName: String, args: [Any]?, functionToCall: (() -> Void)?) -> AnyObject? {
        calls.append(FunctionCall(name: functionName, args: args))
        if let response: AnyObject = responses[functionName] {
            return response
        } else if let functionToCall = functionToCall {
            functionToCall()
        }
        return nil
    }
}

open class FunctionCall {
    open let name: String
    open let args: [Any]?

    init(name: String, args: [Any]?) {
        self.name = name
        self.args = args
    }
}

public typealias Response = (data: Data?, urlResponse: URLResponse?, error: NSError?)

public class MockSession: URLSession {
    static public var mockResponses: [String: Response] = [:]
    static public var mockResponse: (data: Data?, urlResponse: URLResponse?, error: NSError?) = (data: nil, urlResponse: nil, error: nil)

    override public class var shared: URLSession {
        get {
            return MockSession()
        }
    }

    override public func dataTask(with: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        var response: Response
        let mockedMethodAndUrlString = "\(with.httpMethod!)||\((with.url?.absoluteString)!)"

        if let mockedResponse = MockSession.mockResponses[mockedMethodAndUrlString] {
            response = mockedResponse
        } else {
            response = MockSession.mockResponse
        }
        return MockTask(response: response, completionHandler: completionHandler)
    }

    public class func addMockResponse(for url: URL, httpMethod: String, data: Data?, urlResponse: URLResponse?, error: NSError?) {
        let response = (data: data, urlResponse: urlResponse, error: error)
        let mockedResponseString = "\(httpMethod)||\(url.absoluteString)"
        mockResponses[mockedResponseString] = response
    }

    public class MockTask: URLSessionDataTask {
        public var mockResponse: Response
        public let completionHandler: ((Data?, URLResponse?, NSError?) -> Void)?

        public init(response: Response, completionHandler: ((Data?, URLResponse?, NSError?) -> Void)?) {
            self.mockResponse = response
            self.completionHandler = completionHandler
        }

        override public func resume() {
            DispatchQueue.global(qos: .default).async {
                self.completionHandler!(self.mockResponse.data, self.mockResponse.urlResponse, self.mockResponse.error)
            }
        }
    }
}
