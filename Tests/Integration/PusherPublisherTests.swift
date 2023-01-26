import XCTest
import Combine

@testable import PusherSwift

class PusherPublisherTests: XCTestCase {
    
    private var key: String!
    private var pusher: Pusher!
    private var socket: MockWebSocket!
    
    override func setUpWithError() throws {
        key = "testKey123"
        pusher = Pusher(key: key)
        socket = MockWebSocket()
        socket.delegate = pusher.connection
        pusher.connection.socket = socket
    }
    
    override func tearDownWithError() throws {
        pusher.unsubscribeAll()
    }
    
    // MARK: - Channels
    
    func testChannelEventStreamReceivesEvent() {
        let sinkExpectation = expectation(description: "Event received")
        let cancellable = pusher
            .publisher(channelName: TestObjects.Event.testChannelName, eventName: TestObjects.Event.testEventName)
            .sink { event in
                let expectedData = TestObjects.Event.Data.unencryptedJSON.toJsonDict() as! [String: String]
                XCTAssertEqual(event.channelName, TestObjects.Event.testChannelName)
                XCTAssertEqual(event.eventName, TestObjects.Event.testEventName)
                XCTAssertEqual(event.dataToJSONObject() as! [String : String], expectedData)
                sinkExpectation.fulfill()
            }
        
        pusher.connection.webSocketDidReceiveMessage(
            connection: socket,
            string: TestObjects.Event.withJSON()
        )
        waitForExpectations(timeout: 0.5, handler: nil)
        cancellable.cancel()
    }
    
    func testMultipleChannelEventStreamsReceiveEvent() {
        let expectedData = TestObjects.Event.Data.unencryptedJSON.toJsonDict() as! [String: String]
        var cancellables = [AnyCancellable]()
        let sink1Expectation = expectation(description: "Event received on stream 1")
        pusher
            .publisher(channelName: TestObjects.Event.testChannelName, eventName: TestObjects.Event.testEventName)
            .sink { event in
                XCTAssertEqual(event.channelName, TestObjects.Event.testChannelName)
                XCTAssertEqual(event.eventName, TestObjects.Event.testEventName)
                XCTAssertEqual(event.dataToJSONObject() as! [String : String], expectedData)
                sink1Expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let sink2Expectation = expectation(description: "Event received on stream 2")
        pusher
            .publisher(channelName: TestObjects.Event.testChannelName, eventName: TestObjects.Event.testEventName)
            .sink { event in
                XCTAssertEqual(event.channelName, TestObjects.Event.testChannelName)
                XCTAssertEqual(event.eventName, TestObjects.Event.testEventName)
                XCTAssertEqual(event.dataToJSONObject() as! [String : String], expectedData)
                sink2Expectation.fulfill()
            }
            .store(in: &cancellables)
        
        pusher.connection.webSocketDidReceiveMessage(
            connection: socket,
            string: TestObjects.Event.withJSON()
        )
        waitForExpectations(timeout: 0.5, handler: nil)
        cancellables.forEach { $0.cancel() }
    }
    
    func testChannelEventStreamUnbindsUponCancelling() throws {
        let cancellable = pusher
            .publisher(channelName: TestObjects.Event.testChannelName, eventName: TestObjects.Event.testEventName)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        
        let channel = try XCTUnwrap(pusher.connection.channels.find(name: TestObjects.Event.testChannelName))
        XCTAssertEqual(channel.eventHandlers[TestObjects.Event.testEventName]?.count, 1)
        cancellable.cancel()
        XCTAssertEqual(channel.eventHandlers[TestObjects.Event.testEventName]?.count, 0)
    }
    
    // MARK: - Global events
    
    func testGlobalEventStreamReceivesAnyEvent() {
        let sinkExpectation = expectation(description: "Event received")
        let cancellable = pusher
            .publisher()
            .sink { event in
                let expectedData = TestObjects.Event.Data.unencryptedJSON.toJsonDict() as! [String: String]
                XCTAssertNil(event.channelName)
                XCTAssertEqual(event.eventName, TestObjects.Event.testEventName)
                XCTAssertEqual(event.dataToJSONObject() as! [String : String], expectedData)
                sinkExpectation.fulfill()
            }
        
        pusher.connection.webSocketDidReceiveMessage(
            connection: socket,
            string: TestObjects.Event.withoutChannelNameJSON
        )
        waitForExpectations(timeout: 0.5, handler: nil)
        cancellable.cancel()
    }
    
    func testGlobalEventStreamReceivesSpecificEvent() {
        let sinkExpectation = expectation(description: "Event received")
        let cancellable = pusher
            .publisher(eventName: TestObjects.Event.testEventName)
            .sink { event in
                let expectedData = TestObjects.Event.Data.unencryptedJSON.toJsonDict() as! [String: String]
                XCTAssertNil(event.channelName)
                XCTAssertEqual(event.eventName, TestObjects.Event.testEventName)
                XCTAssertEqual(event.dataToJSONObject() as! [String : String], expectedData)
                sinkExpectation.fulfill()
            }
        
        pusher.connection.webSocketDidReceiveMessage(
            connection: socket,
            string: TestObjects.Event.withoutChannelNameJSON
        )
        waitForExpectations(timeout: 0.5, handler: nil)
        cancellable.cancel()
    }
    
    func testGlobalEventStreamUnbindsUponCancelling() {
        let cancellable = pusher
            .publisher()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        
        XCTAssertEqual(pusher.connection.globalChannel.globalCallbacks.count, 1)
        cancellable.cancel()
        XCTAssertEqual(pusher.connection.globalChannel.globalCallbacks.count, 0)
    }
    
    func testSpecificGlobalEventStreamUnbindsUponCancelling() {
        let cancellable = pusher
            .publisher(eventName: TestObjects.Event.testEventName)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        
        XCTAssertEqual(pusher.connection.globalChannel.globalCallbacks.count, 1)
        cancellable.cancel()
        XCTAssertEqual(pusher.connection.globalChannel.globalCallbacks.count, 0)
    }
}
