#import <UIKit/UIKit.h>

@import PusherSwift;

@interface ViewController : UIViewController <PusherDelegate>

@property (nonatomic, strong, readwrite) Pusher *client;

@end
