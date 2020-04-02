#import <Foundation/Foundation.h>

#if TARGET_OS_IOS
    #import "iOS/ViewController.h"
#else
    #import "macOS/ViewController.h"
#endif

#if WITH_ENCRYPTION
    @import PusherSwiftWithEncryption;
#else
    @import PusherSwift;
#endif

NS_ASSUME_NONNULL_BEGIN

@interface AuthRequestBuilder : NSObject <AuthRequestBuilderProtocol>

- (NSMutableURLRequest *)requestForSocketID:(NSString *)socketID channel:(PusherChannel *)channel;
- (NSURLRequest *)requestForSocketID:(NSString *)socketID channelName:(NSString *)channelName;

@end

@interface ViewController (Extensions) <PusherDelegate>

- (Pusher *)makeAndLaunchPusher;

@end

NS_ASSUME_NONNULL_END
