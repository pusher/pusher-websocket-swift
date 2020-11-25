#import <Foundation/Foundation.h>

#if TARGET_OS_IOS
    #import "iOS/ViewController.h"
#elif TARGET_OS_TV
    #import "tvOS/ViewController.h"
#else
    #import "macOS/ViewController.h"
#endif

@import PusherSwift;

NS_ASSUME_NONNULL_BEGIN

@interface AuthRequestBuilder : NSObject <AuthRequestBuilderProtocol>

- (NSMutableURLRequest *)requestForSocketID:(NSString *)socketID channel:(PusherChannel *)channel;
- (NSURLRequest *)requestForSocketID:(NSString *)socketID channelName:(NSString *)channelName;

@end

@interface ViewController (Extensions) <PusherDelegate>

- (Pusher *)makeAndLaunchPusher;

@end

NS_ASSUME_NONNULL_END
