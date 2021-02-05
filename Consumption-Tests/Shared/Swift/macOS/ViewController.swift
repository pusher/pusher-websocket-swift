import Cocoa

import PusherSwift

class ViewController: NSViewController {
    var pusher: Pusher! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.pusher = makeAndLaunchPusher()
    }
}
