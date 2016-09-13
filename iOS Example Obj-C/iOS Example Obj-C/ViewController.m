//
//  ViewController.m
//  iOS Example Obj-C
//
//  Created by Hamilton Chapman on 09/09/2016.
//  Copyright © 2016 Pusher. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    OCAuthMethod *authMethod = [[OCAuthMethod alloc] initWithSecret:@"daef58559fdd0aba8b63"];
    PusherClientOptions *options = [[PusherClientOptions alloc] initWithAuthMethod:authMethod];

    self.client = [[Pusher alloc] initWithAppKey:@"568d5a3851502158a022" options:options];

    self.client.connection.stateChangeDelegate = self;

    self.client.connection.debugLogger = ^void (NSString *text) {
        NSLog(@"%@", text);
    };

    self.client.connection.userDataFetcher = ^PusherPresenceChannelMember* () {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        return [[PusherPresenceChannelMember alloc] initWithUserId:uuid userInfo:nil];
    };

    self.client.connection.subscriptionSuccessHandler = ^void (NSString *channelName) {
        NSLog(@"Subscribed to %@", channelName);
    };

    __weak typeof(self) weakSelf = self;
    self.client.connection.subscriptionSuccessHandler = ^(NSString *str) {
        if ([str  isEqual: @"presence-test"]) {
            NSLog(@"%@", [(PusherPresenceChannel *)[weakSelf.client.connection.channels findWithName:@"presence-test"] members]);
        }
    };

    [self.client bind:^void (NSDictionary *data) {
        NSString *eventName = data[@"event"];

        if ([eventName isEqualToString:@"pusher:error"]) {
            NSString *errorMessage = data[@"data"][@"message"];
            NSLog(@"Error message: %@", errorMessage);
        }
    }];

    [self.client connect];

    PusherChannel *presChan = [self.client subscribeWithChannelName:@"presence-test"];

    [presChan bindWithEventName:@"test-event" callback:^void (id data) {
        NSLog(@"And here is the data: %@", data);
    }];

    void (^onMemberAdded)(PusherPresenceChannelMember*) = ^void (PusherPresenceChannelMember *member) {
        NSLog(@"member added: %@", member);
    };

    void (^onMemberRemoved)(PusherPresenceChannelMember*) = ^void (PusherPresenceChannelMember *member) {
        NSLog(@"member removed: %@", member);
    };

    PusherPresenceChannel *presChanExplicit = [self.client subscribeToPresenceChannelWithChannelName:@"presence-explicit" onMemberAdded:onMemberAdded onMemberRemoved:onMemberRemoved];

    [presChanExplicit bindWithEventName:@"testing" callback: ^void (id data) {
        NSLog(@"Data: %@", data);

        [presChanExplicit triggerWithEventName:@"client-testing" data:@{ @"developers" : @"developers developers developers" }];
    }];
}

-(void)connectionChangeWithOld:(enum ConnectionState)old new:(enum ConnectionState)new_ {
    NSLog(@"Old connection: %d, new connection: %d", (int)old, (int)new_);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
