# Consumption Tests


## Objective
The objective of the "Consumption Tests" is to _truly verify_ that our core code/project is written/configured such that it _can_ be integrated into _any_ of the types of client project we support.

A “suite” of projects/targets exist, each is configured to use one of:

- `PusherSwift.framework` _or_ `PusherSwiftWithEncryption.framework`
- `Carthage`, `Cocoapods` _or_ `Swift Package Manager`
- “Minimum” or “Latest” toolset

| Toolset                    | MINIMUM | LATEST |
|----------------------------|---------|--------|
| Xcode version              | 11      | 11.4   |
| IPHONEOS_DEPLOYMENT_TARGET | 8.0     |  13.0  |
| MACOSX_DEPLOYMENT_TARGET   | 10.11   | 10.15  |

Giving us the following “suite”:

**Carthage-Latest**
 - Swift-iOS-WithoutEncryption
 - Swift-iOS-WithEncryption
 - Swift-macOS-WithoutEncryption
 - Swift-macOS-WithEncryption
 - ObjectiveC-iOS-WithoutEncryption
 - ObjectiveC-iOS-WithEncryption
 - ObjectiveC-macOS-WithoutEncryption
 - ObjectiveC-macOS-WithEncryption

**Carthage-Minimum**
 - Swift-iOS-WithoutEncryption
 - Swift-iOS-WithEncryption
 - Swift-macOS-WithoutEncryption
 - Swift-macOS-WithEncryption
 - ObjectiveC-iOS-WithoutEncryption
 - ObjectiveC-iOS-WithEncryption
 - ObjectiveC-macOS-WithoutEncryption
 - ObjectiveC-macOS-WithEncryption

**Cocoapods-Latest**
 - Swift-iOS-WithoutEncryption
 - Swift-iOS-WithEncryption
 - Swift-macOS-WithoutEncryption
 - Swift-macOS-WithEncryption
 - ObjectiveC-iOS-WithoutEncryption
 - ObjectiveC-iOS-WithEncryption
 - ObjectiveC-macOS-WithoutEncryption
 - ObjectiveC-macOS-WithEncryption
 
**Cocoapods-Minimum**
 - Swift-iOS-WithoutEncryption
 - Swift-iOS-WithEncryption
 - Swift-macOS-WithoutEncryption
 - Swift-macOS-WithEncryption
 - ObjectiveC-iOS-WithoutEncryption
 - ObjectiveC-iOS-WithEncryption
 - ObjectiveC-macOS-WithoutEncryption
 - ObjectiveC-macOS-WithEncryption

**SwiftPackageManager-Latest**
 - Swift-iOS-WithoutEncryption
 - Swift-macOS-WithoutEncryption
 - ObjectiveC-iOS-WithoutEncryption
 - ObjectiveC-macOS-WithoutEncryption

_Note that SwiftPackageManager integration is not supported with `PusherSwiftWithEncyrption`_
 
**SwiftPackageManager-Minimum**
 - Swift-iOS-WithoutEncryption
 - Swift-macOS-WithoutEncryption

_Note that SwiftPackageManager integration not supported with Objective-C in Xcode versions < v11.4 or at all with `PusherSwiftWithEncyrption`_

## How to Run the Test Suite LOCALLY

To run the _full_ suite of tests, simply execute:
`sh ./Consumption-Tests/run-tests-LOCALLY.sh`

Alternatively if you only want to run a sub-set of the suite or skip the `carthage update` or `pod install` then you can pass various flags to `run-tests-LOCALLY.sh`.  For example…

```
# Run full suite but do not perform any `carthage update`
sh ./Consumption-Tests/run-tests-LOCALLY.sh -skip-carthage-checkouts`
```

```
# Run only `Carthage-Minimum` and `Carthage-Latest` suites…
sh ./Consumption-Tests/run-tests-LOCALLY.sh -skip-spm -skip-cocoapods`
```

Full list of flags available…

| Flag                      | Usage                                                                                                                                                   |
|---------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| -skip-carthage            | Skips running `Carthage-Minimum` and `Carthage-Latest` projects/targets                                                                                 |
| -skip-cocoapods           | Skips running `Cocoapods-Minimum` and `Cocoapods-Latest` projects/targets      
| -skip-spm           | Skips running `SwiftPackageManager-Minimum` and `SwiftPackageManager-Latest` projects/targets                                                                           |
| -skip-checkouts           | Does not perform any `carthage update` or `pod install`. Useful if you know that dependencies have already pulled/integrated and you want to save time. |
| -skip-carthage-checkouts  | Does not perform any `carthage update`                                                                                                                  |
| -skip-cocoapods-checkouts | Does not perform any `pod install`      
