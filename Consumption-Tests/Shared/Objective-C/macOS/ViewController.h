#import <Cocoa/Cocoa.h>

#if WITH_ENCRYPTION
    @import PusherSwiftWithEncryption;
#else
    @import PusherSwift;
#endif

@interface ViewController : NSViewController

@property (nonatomic, strong, readwrite) Pusher *client;

@end

