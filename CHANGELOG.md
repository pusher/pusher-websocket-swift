# Changelog

## 0.2.4

* Use cocoapods version 1.0.0.beta.5 to make builds work on Travis
* Update CryptoSwift to 0.2.3
* Update Starscream to 0.1.2
* Add `cluster` option to client initialiser options dictionary
* Fix autoreconnect bugs (@bdolman)
* Make `pusher:subscription_succeeded` event accessible (@bdolman)

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
* POST auth parameter with HTTP Body (@ngs)

## 0.1.7

###### Misc

* Add support for tvOS as platform (@goose2460)
* Update CryptoSwift to 0.2.2 (@goose2460)
* Update ReachabilitySwift to 2.3.3 (@goose2460)
* Rename `Sources` back to `Source`

## 0.1.6

###### Misc

* Fixed build errors with Carthage
* Rename `Source` to `Sources` in order to work with Swift Package Manager (in principle)
* Make headers for PusherSwift and PusherSwiftTests targets public
