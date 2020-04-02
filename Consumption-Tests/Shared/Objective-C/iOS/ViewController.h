#import <UIKit/UIKit.h>

#if WITH_ENCRYPTION
    @import PusherSwiftWithEncryption;
#else
    @import PusherSwift;
#endif

@interface ViewController : UIViewController <PusherDelegate>

@property (nonatomic, strong, readwrite) Pusher *client;

@end
