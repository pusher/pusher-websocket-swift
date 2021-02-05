import UIKit

import PusherSwift

class ViewController: UIViewController {
    var pusher: Pusher! = nil

    @IBAction func connectButton(_ sender: AnyObject) {
        pusher.connect()
    }

    @IBAction func disconnectButton(_ sender: AnyObject) {
        pusher.disconnect()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.pusher = makeAndLaunchPusher()
    }
}
