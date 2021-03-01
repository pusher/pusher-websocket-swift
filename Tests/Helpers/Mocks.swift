import Foundation
import Network
import NWWebSocket

@testable import PusherSwift

class MockWebSocket: NWWebSocket {
    let stubber = StubberForMocks()
    var callbackCheckString: String = ""
    var objectGivenToCallback: Any?
    var eventGivenToCallback: PusherEvent?

    init() {
        super.init(url: URL(string: "test")!)
    }

    func appendToCallbackCheckString(_ str: String) {
        self.callbackCheckString += str
    }

    func storeDataObjectGivenToCallback(_ data: Any) {
        self.objectGivenToCallback = data
    }

    func storeEventGivenToCallback(_ event: PusherEvent) {
        self.eventGivenToCallback = event
    }

    override func connect() {
        let connectionEstablishedString = "{\"event\":\"pusher:connection_established\",\"data\":\"{\\\"socket_id\\\":\\\"45481.3166671\\\",\\\"activity_timeout\\\":120}\"}"
        _ = stubber.stub(
            functionName: "connect",
            args: nil,
            functionToCall: {
                if let delegate = self.delegate {
                    delegate.webSocketDidReceiveMessage(connection: self, string: connectionEstablishedString)
                    delegate.webSocketDidConnect(connection: self)
                } else {
                    print("Your socket delegate is nil")
                }
            }
        )
    }

    override func disconnect(closeCode: NWProtocolWebSocket.CloseCode = .protocolCode(.normalClosure)) {
        _ = stubber.stub(
            functionName: "disconnect",
            args: nil,
            functionToCall: {
                self.delegate?.webSocketDidDisconnect(connection: self,
                                                      closeCode: closeCode,
                                                      reason: nil)
            }
        )
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    override func send(string: String) {
        if string == "{\"data\":{\"channel\":\"test-channel\"},\"event\":\"pusher:subscribe\"}" || string == "{\"event\":\"pusher:subscribe\",\"data\":{\"channel\":\"test-channel\"}}" {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"test-channel\",\"data\":\"{}\"}")
                }
            )
        } else if string == "{\"data\":{\"channel\":\"test-channel2\"},\"event\":\"pusher:subscribe\"}" || string == "{\"event\":\"pusher:subscribe\",\"data\":{\"channel\":\"test-channel2\"}}" {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"test-channel2\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["testkey123:6aae8814fabd5285245422096705abbed64ea59614648814ffb0bf2dc5d19168", "private-channel", "pusher:subscribe"]) {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-channel\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["key:5ce61ee2b8594e22b66323913d7c7af9d8e815659365be3627733993f4ce3824", "presence-channel", "user_id", "45481.3166671", "pusher:subscribe"]) {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"46123.486095\\\"],\\\"hash\\\":{\\\"46123.486095\\\":null}}}\",\"channel\":\"presence-channel\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["testkey123:5ce61ee2b8594e22b66323913d7c7af9d8e815659365be3627733993f4ce3824", "presence-channel", "user_id", "45481.3166671", "pusher:subscribe"]) {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"46123.486095\\\"],\\\"hash\\\":{\\\"46123.486095\\\":null}}}\",\"channel\":\"presence-channel\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["key:e1d0947a10d6ff1a25990798910b2505687bb096e3e8b6c97eef02c6b1abb4c7", "private-channel", "pusher:subscribe"]) {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-channel\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["data", "testing client events", "private-channel", "client-test-event"]) {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: nil
            )
        } else if stringContainsElements(string, elements: ["testKey123:12345678gfder78ikjbg", "private-test-channel", "pusher:subscribe"]) {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-test-channel\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["pusher:subscribe", "testKey123:12345678gfder78ikjbgmanualauth", "private-manual-auth"]) {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-manual-auth\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["pusher:subscribe", "testKey123:12345678gfder78ikjbgmanualauth", "presence-manual-auth"]) {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"presence-manual-auth\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"16\\\"],\\\"hash\\\":{\\\"16\\\":{\\\"twitter\\\":\\\"hamchapman\\\"}}}}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["key:0d0d2e7c2cd967246d808180ef0f115dad51979e48cac9ad203928141f9e6a6f", "private-test-channel", "pusher:subscribe"]) {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-test-channel\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["private-reservations-for-venue@venue_id=399edd2d-3f4a-43k9-911c-9e4b6bdf0f16;date=2017-01-13", "pusher:subscribe", "testKey123:12345678gfder78ikjbg"]) {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-reservations-for-venue@venue_id=399edd2d-3f4a-43k9-911c-9e4b6bdf0f16;date=2017-01-13\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["test-channel", "pusher:unsubscribe"]) {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: nil
            )
        } else if stringContainsElements(string, elements: ["test-channel2", "pusher:unsubscribe"]) {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: nil
            )
        } else if stringContainsElements(string, elements: ["presence-test", "user_id", "123", "pusher:subscribe", "user_info", "twitter", "hamchapman"]) && (stringContainsElements(string, elements: ["testkey123:736f0b19c2e56f985f3e6faa38db5b69d39305bc8519952c8f9f5595d69fcb3d"]) || stringContainsElements(string, elements: ["testkey123:e5ee520a16348ced21be557e14ae70fcd1ae89f79d32d14d22a19049eaf56881"])) {
            // We require different auth signatures depending on the ordering of the channel_data JSON/Dictionary
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"123\\\"],\\\"hash\\\":{\\\"123\\\":{\\\"twitter\\\":\\\"hamchapman\\\"}}}}\",\"channel\":\"presence-test\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["key:c2b53f001321bc088814f210fb63c259b464f590890eee2dde6387ea9b469a30", "presence-channel", "user_id", "123", "pusher:subscribe"]) {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"123\\\"],\\\"hash\\\":{\\\"123\\\":{}}}}\",\"channel\":\"presence-channel\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["pusher:subscribe", "presence-channel", "friends", "0", "user_id", "123"]) && (stringContainsElements(string, elements: ["key:dd2885ee6dc6f5c964d8e3c720980397db50bf8f528e0630d4208bff80ee23f0"]) || stringContainsElements(string, elements: ["key:80cfefb0ef08fb55353dbbc0480e6160059fac14fce862e9ed1f0121ae8a440f"])) {
            // We require different auth signatures depending on the ordering of the channel_data JSON/Dictionary
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"123\\\"],\\\"hash\\\":{\\\"123\\\":{\\\"friends\\\":0}}}}\",\"channel\":\"presence-channel\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["pusher:subscribe", "testKey123:authorizerblah123", "private-test-channel-authorizer"]) {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-test-channel-authorizer\",\"data\":\"{}\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["pusher:subscribe", "testKey123:authorizerblah1234", "presence-test-channel-authorizer"]) {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"data\":\"{\\\"presence\\\":{\\\"count\\\":1,\\\"ids\\\":[\\\"777\\\"],\\\"hash\\\":{\\\"777\\\":{\\\"twitter\\\":\\\"hamchapman\\\"}}}}\",\"channel\":\"presence-test-channel-authorizer\"}")
                }
            )
        } else if stringContainsElements(string, elements: ["private-encrypted-channel", "pusher:subscribe", "636a81ba7e7b15725c00:3ee04892514e8a669dc5d30267221f16727596688894712cad305986e6fc0f3c"]) {
            _ = stubber.stub(
                functionName: "writeString",
                args: [string],
                functionToCall: {
                    self.delegate?.webSocketDidReceiveMessage(connection: self, string: "{\"event\":\"pusher_internal:subscription_succeeded\",\"channel\":\"private-encrypted-channel\",\"data\":\"{}\"}")
                })
        } else {
            print("No match in write(string: ...) mock for string: \(string)")
        }
    }
}

func stringContainsElements(_ str: String, elements: [String]) -> Bool {
    var allElementsPresent = true
    for element in elements {
        if str.range(of: element) == nil {
            allElementsPresent = false
        }
    }

    return allElementsPresent
}

class MockPusherConnection: PusherConnection {
    let stubber = StubberForMocks()

    init(options: PusherClientOptions = PusherClientOptions()) {
        super.init(key: "key", socket: MockWebSocket(), url: "ws://blah.blah:80", options: options)
    }

    override func handleEvent(event: PusherEvent) {
        _ = stubber.stub(
            functionName: "handleEvent",
            args: [event],
            functionToCall: { super.handleEvent(event: event) }
        )
    }
}

class StubberForMocks {
    var calls: [FunctionCall]
    var responses: [String: AnyObject]
    var callbacks: [([FunctionCall]) -> Void]

    init() {
        self.calls = []
        self.responses = [:]
        self.callbacks = []
    }

    func stub(functionName: String, args: [Any]?, functionToCall: (() -> Void)?) -> AnyObject? {
        calls.append(FunctionCall(name: functionName, args: args))
        if let response: AnyObject = responses[functionName] {
            self.callCallbacks(calls: calls)
            return response
        } else if let functionToCall = functionToCall {
            functionToCall()
        }
        self.callCallbacks(calls: calls)
        return nil
    }

    func registerCallback(callback: @escaping ([FunctionCall]) -> Void) {
        callbacks.append(callback)
    }

    func callCallbacks(calls: [FunctionCall]) {
        for callback in callbacks {
            callback(calls)
        }
    }
}

class FunctionCall {
    let name: String
    let args: [Any]?

    init(name: String, args: [Any]?) {
        self.name = name
        self.args = args
    }
}

typealias Response = (data: Data?, urlResponse: URLResponse?, error: NSError?)

class MockSession: URLSession {
    static var mockResponses: [String: Response] = [:]
    // swiftlint:disable:next large_tuple
    static var mockResponse: (data: Data?, urlResponse: URLResponse?, error: NSError?) = (data: nil, urlResponse: nil, error: nil)

    override class var shared: URLSession {
        return MockSession()
    }

    override func dataTask(with: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        var response: Response
        let mockedMethodAndUrlString = "\(with.httpMethod!)||\((with.url?.absoluteString)!)"

        if let mockedResponse = MockSession.mockResponses[mockedMethodAndUrlString] {
            response = mockedResponse
        } else {
            response = MockSession.mockResponse
        }
        return MockTask(response: response, completionHandler: completionHandler)
    }

    class func addMockResponse(for url: URL, httpMethod: String, data: Data?, urlResponse: URLResponse?, error: NSError?) {
        let response = (data: data, urlResponse: urlResponse, error: error)
        let mockedResponseString = "\(httpMethod)||\(url.absoluteString)"
        mockResponses[mockedResponseString] = response
    }

    class MockTask: URLSessionDataTask {
        var mockResponse: Response
        let completionHandler: ((Data?, URLResponse?, NSError?) -> Void)?

        init(response: Response, completionHandler: ((Data?, URLResponse?, NSError?) -> Void)?) {
            self.mockResponse = response
            self.completionHandler = completionHandler
        }

        override func resume() {
            DispatchQueue.global(qos: .default).async {
                self.completionHandler!(self.mockResponse.data, self.mockResponse.urlResponse, self.mockResponse.error)
            }
        }
    }
}
