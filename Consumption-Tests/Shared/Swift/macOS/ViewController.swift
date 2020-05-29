import Cocoa

#if WITH_ENCRYPTION
    import PusherSwiftWithEncryption
#else
    import PusherSwift
#endif

class ViewController: NSViewController {
    var pusher: Pusher! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.pusher = makeAndLaunchPusher()
    }

}
