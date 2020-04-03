# Consumption Tests

### Table of Contents  
- [Objective](#objective)  
- [How to Run the Test Suite LOCALLY](#howto)  
- [Maintaining the Suite of Projects/Targets](#maintenance)  

<a name=“objective” />

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

<a name=“howto” /> 

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


<a name=“maintenance” />

## Maintaining the Suite of Projects/Targets

I foresee two types of maintenance: 
a. [Updates to the “toolset”](#update-toolset)
b. [Updates to the project/targets](#update-targets)


<a name=“update-toolset” />

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


<a name=“update-targets” />

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
    - Delete all targets ending with `WithEncryption` since these aren’t supported with SPM
    - For each remaining target under `Build Phases` > `Link Binary with Libraries` add `PusherSwift`
 


