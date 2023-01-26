import XCTest

@testable import PusherSwift

class PusherExtensionTests: XCTestCase {
    
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
        let expectation = expectation(description: "Event received")
        let cancellable = pusher
            .publisher(for: TestObjects.Event.testChannelName, eventName: TestObjects.Event.testEventName)
            .sink { event in
                let expectedData = TestObjects.Event.Data.unencryptedJSON.toJsonDict() as! [String: String]
                XCTAssertEqual(event.channelName, TestObjects.Event.testChannelName)
                XCTAssertEqual(event.eventName, TestObjects.Event.testEventName)
                XCTAssertEqual(event.dataToJSONObject() as! [String : String], expectedData)
                expectation.fulfill()
            }
        
        pusher.connection.webSocketDidReceiveMessage(
            connection: socket,
            string: TestObjects.Event.withJSON()
        )
        waitForExpectations(timeout: 0.5, handler: nil)
        cancellable.cancel()
    }
    
    func testChannelEventStreamUnbindsUponCancelling() {
        let cancellable = pusher
            .publisher(for: TestObjects.Event.testChannelName, eventName: TestObjects.Event.testEventName)
            .sink(receiveCompletion: { _ in
                XCTFail() // Should not be called in this test.
            }, receiveValue: { _ in
                XCTFail() // Should not be called in this test.
            })
        
        let channel = pusher.subscribe(channelName: TestObjects.Event.testChannelName)
        XCTAssertEqual(channel.eventHandlers[TestObjects.Event.testEventName]?.count, 1)
        cancellable.cancel()
        XCTAssertEqual(channel.eventHandlers[TestObjects.Event.testEventName]?.count, 0)
    }
    
    // MARK: - Global events
    
    func testGlobalEventStreamReceivesAnyEvent() {
        let expectation = expectation(description: "Event received")
        let cancellable = pusher
            .publisher()
            .sink { event in
                let expectedData = TestObjects.Event.Data.unencryptedJSON.toJsonDict() as! [String: String]
                XCTAssertNil(event.channelName)
                XCTAssertEqual(event.eventName, TestObjects.Event.testEventName)
                XCTAssertEqual(event.dataToJSONObject() as! [String : String], expectedData)
                expectation.fulfill()
            }
        
        pusher.connection.webSocketDidReceiveMessage(
            connection: socket,
            string: TestObjects.Event.withoutChannelNameJSON
        )
        waitForExpectations(timeout: 0.5, handler: nil)
        cancellable.cancel()
    }
    
    func testGlobalEventStreamReceivesSpecificEvent() {
        let expectation = expectation(description: "Event received")
        let cancellable = pusher
            .publisher(for: TestObjects.Event.testEventName)
            .sink { event in
                let expectedData = TestObjects.Event.Data.unencryptedJSON.toJsonDict() as! [String: String]
                XCTAssertNil(event.channelName)
                XCTAssertEqual(event.eventName, TestObjects.Event.testEventName)
                XCTAssertEqual(event.dataToJSONObject() as! [String : String], expectedData)
                expectation.fulfill()
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
            .sink(receiveCompletion: { _ in
                XCTFail() // Should not be called in this test.
            }, receiveValue: { _ in
                XCTFail() // Should not be called in this test.
            })
        
        XCTAssertEqual(pusher.connection.globalChannel.globalCallbacks.count, 1)
        cancellable.cancel()
        XCTAssertEqual(pusher.connection.globalChannel.globalCallbacks.count, 0)
    }
}
