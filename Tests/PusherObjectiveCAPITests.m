#import <XCTest/XCTest.h>
#import "PusherSwift/PusherSwift-Swift.h"

@interface PusherObjectiveCAPITests : XCTestCase

@end

@implementation PusherObjectiveCAPITests

- (void)testThatDataBindIsAccessible {
    Pusher *pusher = [[Pusher alloc] initWithKey:@"YOUR_APP_KEY"];
    PusherChannel *chan = [pusher subscribeWithChannelName:@"my-channel"];

    [chan bindWithEventName:@"my-event" callback: ^void (NSDictionary *data) {
        NSString *commenter = data[@"commenter"];
        NSString *message = data[@"message"];

        NSLog(@"%@ wrote %@", commenter, message);
    }];
}



- (void)testThatEventBindIsAccessible {
    Pusher *pusher = [[Pusher alloc] initWithKey:@"YOUR_APP_KEY"];
    PusherChannel *chan = [pusher subscribeWithChannelName:@"my-channel"];

    [chan bindWithEventName:@"my-event" eventCallback: ^void (PusherEvent *event) {
        NSDictionary *data = event.data;

        NSString *commenter = data[@"commenter"];
        NSString *message = data[@"message"];

        NSLog(@"%@ wrote %@", commenter, message);

        NSString *eventName = event.eventName;
        NSString *channelName = event.channelName;
        NSString *userId = event.userId;

        NSLog(@"%@, %@, %@", eventName, channelName, userId);
    }];
}


@end
