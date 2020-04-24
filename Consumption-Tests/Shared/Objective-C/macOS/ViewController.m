#import "ViewController.h"
#import "ViewController+Extensions.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.client = [self makeAndLaunchPusher];
}

@end
