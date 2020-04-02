#import <Cocoa/Cocoa.h>

#if WITH_ENCRYPTION
    #import "PusherSwiftWithEncryption/PusherSwiftWithEncryption-Swift.h"
#else
    #import "PusherSwift/PusherSwift-Swift.h"
#endif

@interface ViewController : NSViewController

@property (nonatomic, strong, readwrite) Pusher *client;

@end

