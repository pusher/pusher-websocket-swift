# Consumption Tests

### Table of Contents  
- [Objective](#objective)  
- [How to Run the Test Suite LOCALLY](#how-to-run-the-test-suite-locally)  
- [Maintaining the Suite of Projects/Targets](#maintaining-the-suite-of-projectstargets)  

## Objective
The objective of the "Consumption Tests" is to _truly verify_ that our core code/project is written/configured such that it _can_ be integrated into _any_ of the types of client project we support.

Note that the "Consumption Tests" only **compile** the code and do not run or perform any unit testing.

A “suite” of projects/targets exist, each is configured to use one of:

- `PusherSwift.framework`
- `Carthage`, `Cocoapods` _or_ `Swift Package Manager`
- “Minimum” or “Latest” toolset

| Toolset                    | MINIMUM | LATEST |
|----------------------------|---------|--------|
| Xcode version              | 11.0      | 12.1   |
| SWIFT_VERSION              | 5.0     |  5.3  |
| IPHONEOS_DEPLOYMENT_TARGET | 13.0     |  14.1  |
| MACOSX_DEPLOYMENT_TARGET   | 10.15   | 10.15  |
| TVOS_DEPLOYMENT_TARGET     | 13.0     | 14.0  |

Giving us the following “suite”:

**Carthage-Latest**
 - Swift-iOS-WithEncryption
 - Swift-macOS-WithEncryption
 - Swift-tvOS-WithEncryption
 - ObjectiveC-iOS-WithEncryption
 - ObjectiveC-macOS-WithEncryption
 - ObjectiveC-tvOS-WithEncryption

**Carthage-Minimum**
 - Swift-iOS-WithEncryption
 - Swift-macOS-WithEncryption
 - Swift-tvOS-WithEncryption
 - ObjectiveC-iOS-WithEncryption
 - ObjectiveC-macOS-WithEncryption
 - ObjectiveC-tvOS-WithEncryption

**Cocoapods-Latest**
 - Swift-iOS-WithEncryption
 - Swift-macOS-WithEncryption
 - Swift-tvOS-WithEncryption
 - ObjectiveC-iOS-WithEncryption
 - ObjectiveC-macOS-WithEncryption
 - ObjectiveC-tvOS-WithEncryption
 
**Cocoapods-Minimum**
 - Swift-iOS-WithEncryption
 - Swift-macOS-WithEncryption
 - Swift-tvOS-WithEncryption
 - ObjectiveC-iOS-WithEncryption
 - ObjectiveC-macOS-WithEncryption
 - ObjectiveC-tvOS-WithEncryption

**SwiftPackageManager-Latest**
 - Swift-iOS-WithEncryption
 - Swift-macOS-WithEncryption
 - Swift-tvOS-WithEncryption
 - ObjectiveC-iOS-WithEncryption
 - ObjectiveC-macOS-WithEncryption
 - ObjectiveC-tvOS-WithEncryption

**SwiftPackageManager-Minimum**
 - Swift-iOS-WithEncryption
 - Swift-macOS-WithEncryption
 - Swift-tvOS-WithEncryption
 - ObjectiveC-iOS-WithEncryption
 - ObjectiveC-macOS-WithEncryption
 - ObjectiveC-tvOS-WithEncryption

_Note that SwiftPackageManager integration not supported with Objective-C in Xcode versions < v11.4_


## How to Run the Test Suite LOCALLY

To run the _full_ suite of tests, simply execute:
```
sh ./Consumption-Tests/run-tests-LOCALLY.sh`
```

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


## Maintaining the Suite of Projects/Targets

I foresee two types of maintenance: 
 - [Updates to the “toolset”](#updates-to-the-toolset)
 - [Updates to the project/targets](#updates-to-the-projectstargets)



### Updates to the “toolset”

Examples of why you’d need to update:
- Apple has released a new version of Xcode, Swift, and/or devices
- We’ve updated/added a third-party dependency in the main project and it has a higher minimum deployment target and/or Swift version.

How to update:
- All that’s require is adjusting the values in one or more of the following files:
    - `LATEST_SUPPORTED_VERSIONS.xcconfig`
    - `LATEST_SUPPORTED_XCODE_VERSION`
    - `MINIMUM_SUPPORTED_VERSIONS.xcconfig`
    - `MINIMUM_SUPPORTED_XCODE_VERSION`


### Updates to the projects/targets

Examples of why you’d need to update:
- A new version of Xcode/carthage/cocoapods has introduced breaking changes
- We’ve updated the main project to support a new target type (e.g. `watchOS`) or package manager. 

How to update:
The projects have specifically been setup so they are exactly the same (with exception of SPM projects).  This facilitates easy editing because we can update one project and copy and paste it into the other suites. 

If you need to update the `xcodeproj` files then I would strongly recommend the approach below.

_Note: use the minimum version of Xcode supported because if you use a new version of Xcode you may introduce changes that aren’t supported with your minimum version_

- `xcode-select` to your minimum supported Xcode version
- Open  the `Carthage-Minimum` workspace within the minimum supported Xcode version
- Make the necessary changes
- Now copy `Carthage-Minimum/Swift.xcodeproj` & `Carthage-Minimum/ObjectiveC.xcodeproj`
- Paste/replace them into all the other suites i.e. 
    - `Carthage-Latest`
    - `Cocoapods-Minimum`
    - `Cocoapods-Latest`
    - `SwiftPackageManager-Latest`
    - `SwiftPackageManager-Minimum`
- Open the following workspaces:
    - `SwiftPackageManager-Latest/SwiftPackageManager-Latest.xcworkspace`
    - `SwiftPackageManager-Minimum/SwiftPackageManager-Minimum.xcworkspace`
- and update both `Swift` and `ObjectiveC` projects as follows:
    - For every target, under `Build Phases` > `Link Binary with Libraries` add `PusherSwift`
 


