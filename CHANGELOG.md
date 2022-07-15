# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [10.1.0](https://github.com/pusher/pusher-websocket-swift/compare/10.0.1...10.1.0) - 2022-07-15

### Added

- `onSubscriptionCountChanged(count:Int)` method to handle `pusher_internal:subscription_count` event

### Removed

- SwiftLint from SPM's package.swift.


## [10.0.1](https://github.com/pusher/pusher-websocket-swift/compare/10.0.0...10.0.1) - 2022-03-23

### Fixed

- Prevent reconnection after intentional disconnection

## [10.0.0](https://github.com/pusher/pusher-websocket-swift/compare/9.2.2...10.0.0) - 2021-07-08

### Added

- The library now supports watchOS 6.0 and above.
- [Auto-generated API docs.](https://pusher.github.io/pusher-websocket-swift/)

### Removed

- The deprecated `bind(_ callback:)` method on `Pusher` has been removed.
- The deprecated `bind(eventName:callback:)` method on `PusherChannel` has been removed.

## [9.2.2](https://github.com/pusher/pusher-websocket-swift/compare/9.2.1...9.2.2) - 2021-03-11

### Fixed

- Resolved an issue preventing App Store submission when integrating the SDK using certain dependency managers.

## [9.2.1](https://github.com/pusher/pusher-websocket-swift/compare/9.2.0...9.2.1) - 2021-03-04

### Deprecated

- Marked the legacy `bind(_ callback:)` method on `Pusher` as deprecated.
- Marked the legacy `bind(eventName:callback:)` method on `PusherChannel` as deprecated.

## [9.2.0](https://github.com/pusher/pusher-websocket-swift/compare/9.1.1...9.2.0) - 2021-01-15

### Added

- Added an optional `path` parameter to `PusherClientOptions` to specify custom additional path components.

### Changed

- All debugging messages are now sent via `debugLog(message: String)` (previously there were some messages which weren't sent this way).

### Fixed

- The `subscribed` parameter on a `PusherChannel` is now set to `false` when calling `unsubscribe(_ channelName: String)`.
- Enhanced thread safety for common operations: subscribing / unsubscribing with channels, and binding / unbinding with events.

## [9.1.1](https://github.com/pusher/pusher-websocket-swift/compare/9.1.0...9.1.1) - 2020-12-15

### Fixed

- Resolved a race condition that could prevent automatic reconnection attempts in certain circumstances.

## [9.1.0](https://github.com/pusher/pusher-websocket-swift/compare/9.0.0...9.1.0) - 2020-12-07

### Added

- Encrypted channels are now support by default by the `PusherSwift` target.
- Encrypted channels are now supported if integrating the SDK via Swift Package Manager.
- tvOS as a target platform is now supported regardless of if encrypted channels are used.
- [tweetnacl-swiftwrap](https://github.com/bitmark-inc/tweetnacl-swiftwrap) is now a dependency.

### Changed

- Migrated the WebSocket client code to use our [NWWebSocket](https://github.com/pusher/NWWebSocket) library.
- Improvements to WebSocket reconnection functionality for unstable connections, or connections which migrate from Wi-Fi to Cellular (or vice versa).

### Removed

- The `PusherSwiftWithEncryption` target has been removed.
- Reachability is no longer a dependency.

## [9.0.0](https://github.com/pusher/pusher-websocket-swift/compare/8.0.0...9.0.0) - 2020-10-09

### Added

- Connects to Pusher servers using a WebSocket client that is fully-native code.
- [Pusher Channels Protocol closure codes](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol#connection-closure) are now respected when attempting to reconnect to Pusher servers after a disconnection.

### Changed

- The `autoReconnect` option is now ignored if a received closure code is from the Channels Protocol closure code range.
- The SDK minimum deployment targets are now: iOS 13.0, macOS 10.15 and tvOS 13.0.
- Fixed some typos in the README.
- Removed BETA label for Private encrypted channels feature in the README.
- Clarified in the README which frameworks to import in your project if you are integrating the SDK using Carthage.

### Removed

- Starscream is no longer a dependency.

## [8.0.0](https://github.com/pusher/pusher-websocket-swift/compare/7.2.0...8.0.0) - 2020-04-27

### Added

- Added support for [end-to-end encryption](https://pusher.com/docs/channels/using_channels/encrypted-channels). There is a new target: `PusherSwiftWithEncryption` and a new dependency for that target `Sodium`. The original `PusherSwift` target does not require `Sodium` and has all the same features as `PusherSwiftWithEncryption` except the ability to decrypt events. You can find details about how to use `PusherSwiftWithEncryption` in the [README](https://github.com/pusher/pusher-websocket-swift#private-encrypted-channels-beta). As part of this feature, there is a new function in the `PusherDelegate`: `failedToDecryptEvent`, and channel names prefixed with `private-encrypted-` are now interpreted as encrypted channels in both targets.

### Changed

- The `encrypted` parameter for `PusherClientOptions` has been renamed to `useTLS`. Its behavior and default value (`true`) are unchanged.
- Updated to Swift 5.0 and updated dependencies ([@JonathanDowning](https://github.com/JonathanDowning)).

### Removed

- CryptoSwift is no longer a dependency.

## [7.2.0](https://github.com/pusher/pusher-websocket-swift/compare/7.1.0...7.2.0) - 2019-10-18

### Added

- Added support for Swift Package Manager ([@JonathanDowning](https://github.com/JonathanDowning)).

### Fixed

- Fixed a compilation warning caused by incorrect parameter names in documentation comments ([@funkyboy](https://github.com/funkyboy)).

## [7.1.0](https://github.com/pusher/pusher-websocket-swift/compare/7.0.0...7.1.0) - 2019-10-03

### Added

- Added new `bind` functions which accept a callback that receives a `PusherEvent`. A `PusherEvent` represents an event received from the websocket and has properties containing the event name, channel name and data. In addition, `PusherEvent` has a new property, `userId`, which allows you to verify the ID of the user who triggered a client event on a presence channel. You can read more about this feature in [the docs](https://pusher.com/docs/channels/using_channels/events#user-id-in-client-events). All the old `bind` functions are still available for backwards compatibility. The `data` property of `PusherEvent` is not automatically parsed from JSON and you can decide to parse that as required. The parsing behavior is unchanged for data passed to callbacks bound by the old `bind` functions.

### Changed

- Updated the deployment targets so they are consistent regardless of whether you import the library using CocoaPods or Carthage.

## [7.0.0](https://github.com/pusher/pusher-websocket-swift/compare/6.1.0...7.0.0) - 2019-04-16

### Changed

- Updated to Swift 4.2.
- Updated dependencies to newer versions, but pinned dependencies before any Swift 5 versions for compatibility with older versions of Xcode ([@cowgp](https://github.com/cowgp)).

### Removed

- Removed push notifications beta (replaced by [Pusher Beams](https://pusher.com/beams) which has its own libraries).
- Removed TaskQueue dependency (used by push notifications beta).

### Fixed

- Fixed issues compiling the library with Swift 5/Xcode 10.2.
- Fixed issue related to the capturing of self in Reachability callbacks ([@PorterHoskins](https://github.com/PorterHoskins)).
- Fixed unreliable tests.

## [6.1.0](https://github.com/pusher/pusher-websocket-swift/compare/6.0.0...6.1.0) - 2018-05-18

### Changed

- Reverted to using upstream version of Starscream instead of fork.

## [6.0.0](https://github.com/pusher/pusher-websocket-swift/compare/5.1.1...6.0.0) - 2018-04-04

### Added

- Client will now send a ping to the server if there has been a period of inactivity on the socket. This should help detect some disconnections that previously weren't being noticed.

### Changed

- All dependencies are now defined to be brought in using the appropriate package manager (Carthage or CocoaPods)
- Reconnection strategy has been changed to now attempt reconnecting indefinitely, with an exponential backoff but a maximum interval of 120 seconds between reconnection attempts.

### Removed

- Removed the deprecated `AuthRequestBuilderProtocol` function: `func requestFor(socketID: String, channel: PusherChannel) -> NSMutableURLRequest?`
- `reconnectingWhenNetworkBecomesReachable` connection state

## [5.1.1](https://github.com/pusher/pusher-websocket-swift/compare/5.1.0...5.1.1) - 2018-01-22

### Changed
- Updated Starscream and CryptoSwift based code. Starscream is at roughly 3.0.4 and CryptoSwift at roughly 0.8.1.

## [5.1.0](https://github.com/pusher/pusher-websocket-swift/compare/5.0.1...5.1.0) - 2017-11-23

### Added
- [`setSubscriptions`](https://pusher.com/docs/push_notifications/reference/client_api#put-v1clientsclientidinterests) method.

## 5.0.1

* Swift 4 support.
* Updated CryptoSwift-based code.

## 5.0.0

* Swift 3.2 support (requires Xcode 9+).

## 4.2.1

* Updated Starscream dependency (commit SHA 789264eef). Fixes #115.

## 4.2.0

* Added `Authorizer` protocol that permits a new authorization method for channels requiring it (private and presence channels).

## 4.1.0

* Reverted change introduced in 4.0.2 that set up a custom callback queue for the underlying websocket
* Added the ability to provide auth values on channel subscriptions
* Updated Starscream dependency to latest version (commit SHA ee993322c)
* Encode channel names to be consistent with other libraries

## 4.0.2 (pulled - upgrade to 4.1.0+)

* Fixed `members` property not being set before `subscription_succeeded` event callbacks were called for presence channels ([@ichibod](https://github.com/ichibod))

## 4.0.1

* Fixed memory leak issues with `PusherConnection` and `PusherDelegate` ([@anlaital](https://github.com/anlaital))
* Deprecated `requestFor` in `AuthRequestBuilderProtocol` that returns `NSMutableURLRequest?`
* Added `requestFor` in `AuthRequestBuilderProtocol` that takes a `channelName` `String` instead of a `PusherChannel` instance, and returns `URLRequest?` ([@Noobish1](https://github.com/Noobish1))

## 4.0.0

* Made code required for push notifications available on macOS platform (i.e. push notifications work on macOS!) ([@jameshfisher](https://github.com/jameshfisher))
* Removed `PusherConnectionDelegate` and moved all delegate functions into unified `PusherDelegate`
* Renamed most delegate functions:
  - `didRegisterForPushNotifications(clientId: String)` -> `registeredForPushNotifications(clientId: String)`
  - `didSubscribeToInterest(named name: String)` -> `subscribedToInterest(name: String)`
  - `didUnsubscribeFromInterest(named name: String)` -> `unsubscribedFromInterest(name: String)`
  - `connectionStateDidChange?(from: oldState, to: newState)` -> `changedConnectionState(from old: ConnectionState, to new: ConnectionState)`
  - `subscriptionDidSucceed?(channelName: channelName)` -> `subscribedToChannel(name: String)`
  - `subscriptionDidFail?(channelName: channelName, response: response, data: data, error: error)` -> `failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?)`
* Added macOS Example Swift project that contains an example macOS app to demo push notifications (requires setting up with your own Pusher app)
* Update CryptoSwift and Starscream dependencies
* Made `NativePusher` not be a singleton anymore
* Fixed `taskQueue` crash (#96)

## 3.2.0

* Authentication requests that result in any status code other that 200 or 201 are now treated as failures (previously any 2xx status code was treated as a success)
* Add a `findPresence` function to the `PusherPresenceChannel` class
* Make docs for working with presence channels much clearer

## 3.1.0

* Fix bug in NativePusher where subscription modification requests would fail but not call the appropriate branch of the `guard` statement
* Add `PusherDelegate`, which includes optional functions related to Push Notification-related events
* Added TaskQueue and refactored how subscribe / unsubscribe events are sent to the Push Notifications service (to make it thread-safe)
* Added tests for NativePusher-related code paths

## 3.0.0

* Update to work with Swift 3
* Rewrote all tests using XCTest
* Remove all need for Podfile / Cartfile when building PusherSwift locally
* Combine different builds into single target
* Merge in native notification code into main branch (push-notifications branch)
* Consolidate connection-related handlers / callbacks into `PusherConnectionDelegate`
* Make `requestFor` in `AuthRequestBuilderProtocol` able to fail
* Rename `PresencePusherChannel` -> `PusherPresenceChannel`
* Rename `PresenceChannelMember` -> `PusherPresenceChannelMember`
* Rename `internal` `authMethod` enum case to `inline`
* Add Obj-C compatibility
* Add iOS Obj-C example app
* Add `subscribeToPresenceChannel` method

## 2.0.1

* Fix potential forceful unwrapping of a nil in debug logging when reconnecting (thanks to [@psycotica0](https://github.com/psycotica0) for the spot)

## 2.0.0

* Made the `Pusher` initializer take an instance of a `PusherClientOptions` struct ([@Noobish1](https://github.com/Noobish1))
* Authenticating channels can now be achieved by: specifying an auth endpoint, providing an auth request builder (which conforms to the `AuthRequestBuilder` protocol), or by providing your app's secret (not for production) ([@Noobish1](https://github.com/Noobish1))
* Made the code Swiftier in general, e.g. `PusherChannelType` enum ([@Noobish1](https://github.com/Noobish1))
* More robust reconnect (#66 - thanks to [@psycotica0](https://github.com/psycotica0) for review)
* Added two new connection state cases: `Reconnecting` and `ReconnectingWhenNetworkBecomesReachable`
* Added `reconnectAttemptsMax` and `maxReconnectGapInSeconds` for tweaking specifics of reconnection logic
* Receiving Pusher-related errors by binding to the event name `pusher:error` on the client now works

## 1.0.0

* Add `onMemberAdded`, `onMemberRemoved`, `findMember`, and `me` functions to PusherPresenceChannel class
* Bring CryptoSwift, Starscream and Reachability dependencies inside the PusherSwift library
* Update Quick and Nimble dependencies to remove warnings for Swift compatibility
* Use cocoapods version 1.0.0 on Travis
* Split up `PusherSwift.swift` and `PusherSwiftTests.swift` into components
* Add inline documentation throughout codebase
* Added `debugLogger` option to client
* Handling of `pusher:error` messages now works as it should have done all along
* Building with Carthage now now longer requires a `pod install` to make it work
* Fix bug in `ConnectionStateChangeDelegate`
* Pass authorization errors to client ([@psycotica0](https://github.com/psycotica0))

## 0.3.0

* Use cocoapods version 1.0.0.beta.6 to make builds work on Travis
* Use Xcode 7.3 image and updated simulators on Travis
* Update CryptoSwift to 0.3.1 and Starscream to 1.1.3 (largely for Swift 2.2 compatibility)
* Add ConnectionStateChangeDelegate and associated docs & tests

## 0.2.4

* Use cocoapods version 1.0.0.beta.5 to make builds work on Travis
* Update CryptoSwift to 0.2.3
* Update Starscream to 1.1.2
* Add `cluster` option to client initialiser options dictionary
* Fix autoreconnect bugs ([@bdolman](https://github.com/bdolman))
* Make `pusher:subscription_succeeded` event accessible ([@bdolman](https://github.com/bdolman))

## 0.2.3

* Make `unsentEvents` an array instead of a dictionary (fixes #29)

## 0.2.2

* Fix building for Carthage
* Update `TARGETED_DEVICE_FAMILY` for tvOS target to be correct (`3`)

## 0.2.1

* Remove Pods directory from repo
* Change iOS deployment target to 8.0
* Use cocoapods version 1.0.0.beta.2 to make builds work on Travis

## 0.2.0

* Add platform-specific builds for iOS, tvOS, OSX
* Add build and test schemes for platform-specific builds
* Update Starscream to 1.1.1
* POST auth parameter with HTTP Body ([@ngs](https://github.com/ngs))

## 0.1.7

* Add support for tvOS as platform ([@goose2460](https://github.com/goose2460))
* Update CryptoSwift to 0.2.2 ([@goose2460](https://github.com/goose2460))
* Update ReachabilitySwift to 2.3.3 ([@goose2460](https://github.com/goose2460))
* Rename `Sources` back to `Source`

## 0.1.6

* Fixed build errors with Carthage
* Rename `Source` to `Sources` in order to work with Swift Package Manager (in principle)
* Make headers for PusherSwift and PusherSwiftTests targets public
