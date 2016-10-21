import Cocoa
import PusherSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, PusherDelegate {

    let pusher = Pusher(key: "YOUR_APP_KEY")

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSApp.registerForRemoteNotifications(matching: [NSRemoteNotificationType.alert, NSRemoteNotificationType.sound, NSRemoteNotificationType.badge]);

        self.pusher.delegate = self
        self.pusher.connect()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.pusher.nativePusher().register(deviceToken: deviceToken)
        self.pusher.nativePusher().subscribe(interestName: "donuts")
    }

    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
        print("Received remote notification: " + userInfo.debugDescription)
    }

    // MARK: PusherDelegate

    func didRegisterForPushNotifications(clientId: String) {
        print("Registered with Pusher with client_id: " + clientId)
    }

    func didSubscribeToInterest(named name: String) {
        print("Subscribed to interest: " + name)
    }

    func didUnsubscribeFromInterest(named name: String) {
        print("Unsubscribed from interest: " + name)
    }
}
