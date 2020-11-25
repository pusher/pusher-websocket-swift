#import <Cocoa/Cocoa.h>

@import PusherSwift;

@interface ViewController : NSViewController

@property (nonatomic, strong, readwrite) Pusher *client;

@end

