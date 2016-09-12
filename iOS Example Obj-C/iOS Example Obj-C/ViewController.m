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

    OCAuthMethod *authMethod = [[OCAuthMethod alloc] initWithSecret:@"YOUR_APP_SECRET"];
    PusherClientOptions *options = [[PusherClientOptions alloc] initWithAuthMethod:authMethod];

    self.client = [[Pusher alloc] initWithKey:@"YOUR_APP_KEY" options:options];

    self.client.connection.stateChangeDelegate = self;

    self.client.connection.debugLogger = ^void (NSString *text) {
        NSLog(@"%@", text);
    };

    __weak typeof(self) weakSelf = self;
    self.client.connection.subscriptionSuccessHandler = ^(NSString *str) {
        if ([str  isEqual: @"presence-test"]) {
            NSLog(@"%@", [(PusherPresenceChannel *)[weakSelf.client.connection.channels findWithName:@"presence-test"] members]);
        }
    };

    [self.client connect];

    PusherChannel *presChan = [self.client subscribeWithChannelName:@"presence-test"];

    [presChan bindWithEventName:@"test-event" callback:^void (id data) {
        NSLog(@"And here is the data: %@", data);
    }];

    void (^onMemberAdded)(PresenceChannelMember*) = ^void (PresenceChannelMember *member) {
        NSLog(@"member added: %@", member);
    };

    void (^onMemberRemoved)(PresenceChannelMember*) = ^void (PresenceChannelMember *member) {
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
