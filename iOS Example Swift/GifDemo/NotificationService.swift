//
//  NotificationService.swift
//  GifDemo
//
//  Created by Hamilton Chapman on 12/09/2016.
//  Copyright © 2016 Pusher. All rights reserved.
//

import UserNotifications
import MobileCoreServices

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        /*
            The Swift code below is based on using a payload like this when sending a push
            notification through Pusher's Push Notifications Service:

                apns: {
                  aps: {
                    alert: {
                      title: "Pusher's Native Push Notifications API",
                      subtitle: "Bringing you iOS 10 support!",
                      body: "Now add more content to your Push Notifications!"
                    },
                    "mutable-content": 1
                  },
                  data: {
                    "gif_url": "https://partridge.cloud/grabs/S01E01/gif/EGYdGz9UcRxN.gif"
                  }
                }

        */

        if let notificationData = request.content.userInfo["data"] as? [String: String] {
            guard let urlString = notificationData["gif_url"], let fileUrl = URL(string: urlString) else {
                return
            }

            URLSession.shared.downloadTask(with: fileUrl) { (location, response, error) in
                guard let location = location else {
                    return
                }

                let tmpDirectory = NSTemporaryDirectory()
                let tmpFile = "file://".appending(tmpDirectory).appending(fileUrl.lastPathComponent)
                let tmpUrl = URL(string: tmpFile)!
                try! FileManager.default.moveItem(at: location, to: tmpUrl)

                guard let attachment = try? UNNotificationAttachment(identifier: "", url: tmpUrl) else {
                    return
                }

                self.bestAttemptContent?.attachments = [attachment]
                self.contentHandler!(self.bestAttemptContent!)
            }.resume()
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
