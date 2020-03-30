#import <UIKit/UIKit.h>
#import "PusherSwift/PusherSwift-Swift.h"

@interface ViewController : UIViewController <PusherDelegate>

@property (nonatomic, strong, readwrite) Pusher *client;

@end
