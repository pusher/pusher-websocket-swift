#import "ViewController+Extensions.h"

@implementation AuthRequestBuilder

- (NSMutableURLRequest *)requestForSocketID:(NSString *)socketID channel:(PusherChannel *)channel {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [[NSURL alloc] initWithString:@"http://localhost:9292/pusher/auth"]];
    NSString *dataStr = [NSString stringWithFormat: @"socket_id=%@&channel_name=%@", socketID, [channel name]];
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = data;
    request.HTTPMethod = @"POST";
    return request;
}

- (NSURLRequest *)requestForSocketID:(NSString *)socketID channelName:(NSString *)channelName {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"http://localhost:9292/pusher/auth"]];
    NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL: [[NSURL alloc] initWithString:@"http://localhost:9292/pusher/auth"]];

    NSString *dataStr = [NSString stringWithFormat: @"socket_id=%@&channel_name=%@", socketID, channelName];
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    mutableRequest.HTTPBody = data;
    mutableRequest.HTTPMethod = @"POST";

    request = [mutableRequest copy];

    return request;
}

@end

@implementation ViewController (Extensions)

- (Pusher *)makeAndLaunchPusher {
    
    OCAuthMethod *authMethod = [[OCAuthMethod alloc] initWithSecret:@"YOUR_APP_SECRET"];
    PusherClientOptions *options = [[PusherClientOptions alloc] initWithAuthMethod:authMethod];

    // Use this if you want to try out your auth Endpoint
//    OCAuthMethod *endpointAuthMethod = [[OCAuthMethod alloc] initWithAuthRequestBuilder:[[AuthRequestBuilder alloc] init]];
//    PusherClientOptions *optionsWithEndpoint = [[PusherClientOptions alloc] initWithAuthMethod:endpointAuthMethod];

    Pusher *pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY" options:options];
    pusher.connection.delegate = self;

    pusher.connection.userDataFetcher = ^PusherPresenceChannelMember* () {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        return [[PusherPresenceChannelMember alloc] initWithUserId:uuid userInfo:nil];
    };

    // bind to all events globally
    [pusher bindWithEventCallback:^void (PusherEvent *event) {
        NSString *message = [NSString stringWithFormat: @"Event received '%@'", event.eventName];

        if (event.channelName) {
            message = [message stringByAppendingFormat: @" on channel '%@'", event.channelName];
        }
        if (event.userId) {
            message = [message stringByAppendingFormat: @" from user '%@'", event.userId];
        }
        if (event.data) {
            message = [message stringByAppendingFormat: @" with data '%@'", event.data];
        }

        NSLog(@"%@", message);
    }];

    [pusher connect];

    // subscribe to a public channel
    PusherChannel *myChannel = [pusher subscribeWithChannelName:@"my-channel"];

    // bind a callback to an event on that channel
    [myChannel bindWithEventName:@"my-event" eventCallback:^void (PusherEvent *event) {
        NSString *dataString = event.data;
        // convert string to data for decoding
        NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];

        NSError *error;
        // parse data as json
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];

        NSString *name = jsonObject[@"name"];
        NSString *message = jsonObject[@"message"];

        NSLog(@"%@ says %@", name, message);
    }];

    // callback for member added event
    void (^onMemberAdded)(PusherPresenceChannelMember*) = ^void (PusherPresenceChannelMember *member) {
        NSLog(@"member added: %@", member);
    };

    // callback for member removed event
    void (^onMemberRemoved)(PusherPresenceChannelMember*) = ^void (PusherPresenceChannelMember *member) {
        NSLog(@"member removed: %@", member);
    };

    // subscribe to a presence channel
    PusherPresenceChannel *presChanExplicit = [pusher subscribeToPresenceChannelWithChannelName:@"presence-explicit" onMemberAdded:onMemberAdded onMemberRemoved:onMemberRemoved];

    // bind a callback on the presence channel
    [presChanExplicit bindWithEventName:@"testing" eventCallback: ^void (PusherEvent *event) {
        NSLog(@"Data: %@", event.data);
    }];

    // trigger a client event
    [presChanExplicit triggerWithEventName:@"client-testing" data:@{ @"developers" : @"developers developers developers" }];
    
    return pusher;
}

- (void)changedConnectionStateFrom:(enum ConnectionState)old to:(enum ConnectionState)new_ {
    NSLog(@"Old connection: %d, new connection: %d", (int)old, (int)new_);
}

- (void)debugLogWithMessage:(NSString *)message {
    NSLog(@"%@", message);
}

- (void)subscribedToChannelWithName:(NSString *)name {
    NSLog(@"Subscribed to channel %@", name);

    if ([name isEqual: @"presence-test"]) {
        NSLog(@"%@", [(PusherPresenceChannel *)[self.client.connection.channels findWithName:@"presence-test"] members]);
    }
}

- (void)failedToSubscribeToChannelWithName:(NSString *)name response:(NSURLResponse *)response data:(NSString *)data error:(NSError *)error {
    NSLog(@"Failed to subscribe to channel %@", name);
}

- (void)receivedError:(PusherError *)error {
    NSNumber *code = error.codeOC;
    if(code) {
        NSLog(@"Received error: (%ld) %@", [code longValue], error.message);
    } else {
        NSLog(@"Received error: %@", error.message);
    }
}

@end
