# Changelog

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

* Add `onMemberAdded`, `onMemberRemoved`, `findMember`, and `me` functions to PresencePusherChannel class
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

###### Misc

* Add support for tvOS as platform ([@goose2460](https://github.com/goose2460))
* Update CryptoSwift to 0.2.2 ([@goose2460](https://github.com/goose2460))
* Update ReachabilitySwift to 2.3.3 ([@goose2460](https://github.com/goose2460))
* Rename `Sources` back to `Source`

## 0.1.6

###### Misc

* Fixed build errors with Carthage
* Rename `Source` to `Sources` in order to work with Swift Package Manager (in principle)
* Make headers for PusherSwift and PusherSwiftTests targets public
