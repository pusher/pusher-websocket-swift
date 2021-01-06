# Pusher Channels Swift Client (also works with Objective-C)

![Build Status](https://app.bitrise.io/app/3c6dac112b98e7fe.svg?token=n0z-aWua_Bc35kUGu4qpYg)
![Languages](https://img.shields.io/badge/languages-swift%20%7C%20objc-orange.svg)
[![Platform](https://img.shields.io/cocoapods/p/PusherSwift.svg?style=flat)](http://cocoadocs.org/docsets/PusherSwift)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/PusherSwift.svg)](https://img.shields.io/cocoapods/v/PusherSwift.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Twitter](https://img.shields.io/badge/twitter-@Pusher-blue.svg?style=flat)](http://twitter.com/Pusher)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/pusher/pusher-websocket-swift/master/LICENSE.md)
[![codecov](https://codecov.io/gh/pusher/pusher-websocket-swift/branch/master/graph/badge.svg)](https://codecov.io/gh/pusher/pusher-websocket-swift)

This is the [Pusher Channels](https://pusher.com/channels) websocket client, PusherSwift, which supports iOS, macOS (OS X) and tvOS. It works with Swift and Objective-C.

For tutorials and more in-depth information about Pusher Channels, visit our [official docs](https://pusher.com/docs/channels).

## Supported platforms
- Swift 5.0 and above
- Xcode 11.0 and above
- Can be used with Objective-C

### Deployment targets
- iOS 13.0 and above
- macOS (OS X) 10.15 and above
- tvOS 13.0 and above
- Not currently compatible with watchOS

### Legacy OS support

If you need support for older versions of iOS, macOS or tvOS, please use the latest v8.x release of the SDK.

## I just want to copy and paste some code to get me started

What else would you want? Head over to one of our example apps:

- For iOS with Swift, see [ViewController.swift](https://github.com/pusher/pusher-websocket-swift/blob/master/iOS%20Example%20Swift/iOS%20Example%20Swift/ViewController.swift)
- For iOS with Objective-C, see [ViewController.m](https://github.com/pusher/pusher-websocket-swift/blob/master/iOS%20Example%20Obj-C/iOS%20Example%20Obj-C/ViewController.m)

## Table of Contents

- [Installation](#installation)
  - [CocoaPods](#cocoapods)
  - [Carthage](#carthage)
  - [Swift Package Manager](#swift-package-manager)
- [Configuration](#configuration)
- [Connection](#connection)
  - [Connection delegate](#connection-delegate)
  - [Reconnection](#reconnection)
- [Subscribing to channels](#subscribing)
  - [Public channels](#public-channels)
  - [Private channels](#private-channels)
  - [Private encrypted channels](#private-encrypted-channels)
  - [Presence channels](#presence-channels)
- [Binding to events](#binding-to-events)
  - [Per-channel](#per-channel-events)
  - [Globally](#global-events)
  - [Callback parameters](#callback-parameters)
  - [Parsing event data](#parsing-event-data)
  - [Receiving errors](#receiving-errors)
- [Triggering events](#triggering-events)
- [Testing](#testing)
- [Extensions](#extensions)
- [Communication](#communication)
- [Credits](#credits)
- [License](#license)

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects and is our recommended method of installing PusherSwift and its dependencies.

If you don't already have the Cocoapods gem installed, run the following command:

```bash
$ gem install cocoapods
```

To integrate PusherSwift into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

pod 'PusherSwift', '~> 9.0'
```

Then, run the following command:

```bash
$ pod install
```

If you find that you're not having the most recent version installed when you run `pod install` then try running:

```bash
$ pod cache clean
$ pod repo update PusherSwift
$ pod install
```

Also you'll need to make sure that you've not got the version of PusherSwift locked to an old version in your `Podfile.lock` file.

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that automates the process of adding frameworks to your Cocoa application.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate PusherSwift into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "pusher/pusher-websocket-swift"
```

Carthage will produce a number of frameworks. You need to include the following framework binaries in your project from the `Carthage/Build` directory: `PusherSwift` and `TweetNacl`

#### Xcode 12 considerations

Using Carthage under Xcode 12.0 and above currently requires [a workaround](https://github.com/Carthage/Carthage/issues/3019) in order for the build to be successful. You can find an example of the workaround, which is used for running the 'Consumption-Tests' [here](Consumption-Tests/Shared/carthage.sh).

### Swift Package Manager

To integrate PusherSwift into your project using [Swift Package Manager](https://swift.org/package-manager/), you can add the library as a dependency in Xcode (11 and above) – see the [docs](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app). The package repository URL is:

```bash
https://github.com/pusher/pusher-websocket-swift.git
```

Alternatively, you can add PusherSwift as a dependency in your `Package.swift` file. For example:

```swift
// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "YourPackage",
    products: [
        .library(
            name: "YourPackage",
            targets: ["YourPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pusher/pusher-websocket-swift.git", from: "9.1.1"),
    ],
    targets: [
        .target(
            name: "YourPackage",
            dependencies: ["PusherSwift"]),
    ]
)
```

You will then need to include an `import PusherSwift` statement in any source files where you wish to use the SDK.

## Configuration

There are a number of configuration parameters which can be set for the Pusher client. For Swift usage they are:

- `authMethod (AuthMethod)` - the method you would like the client to use to authenticate subscription requests to channels requiring authentication (see below for more details)
- `useTLS (Bool)` - whether or not you'd like to use TLS encrypted transport or not, default is `true`
- `autoReconnect (Bool)` - set whether or not you'd like the library to try and automatically reconnect upon disconnection (where possible). See [Reconnection](#reconnection) for more info
- `host (PusherHost)` - set a custom value for the host you'd like to connect to, e.g. `PusherHost.host("ws-test.pusher.com")`
- `port (Int)` - set a custom value for the port that you'd like to connect to
- `activityTimeout (TimeInterval)` - after this time (in seconds) without any messages received from the server, a ping message will be sent to check if the connection is still working; the default value is supplied by the server, low values will result in unnecessary traffic.

<details><summary>View legacy configuration options</summary>

- `attemptToReturnJSONObject (Bool)` - whether or not you'd like the library to try and parse your data as JSON (or not, and just return a string)

</details>

The `authMethod` parameter must be of the type `AuthMethod`. This is an enum defined as:

```swift
public enum AuthMethod {
    case endpoint(authEndpoint: String)
    case authRequestBuilder(authRequestBuilder: AuthRequestBuilderProtocol)
    case inline(secret: String)
    case authorizer(authorizer: Authorizer)
    case noMethod
}
```

- `endpoint(authEndpoint: String)` - the client will make a `POST` request to the endpoint you specify with the socket ID of the client and the channel name attempting to be subscribed to
- `authRequestBuilder(authRequestBuilder: AuthRequestBuilderProtocol)` - you specify an object that conforms to the `AuthRequestBuilderProtocol` (defined below), which must generate an `URLRequest` object that will be used to make the auth request
- `inline(secret: String)` - your app's secret so that authentication requests do not need to be made to your authentication endpoint and instead subscriptions can be authenticated directly inside the library (this is mainly designed to be used for development)
- `authorizer(authorizer: Authorizer)` - you specify an object that conforms to the `Authorizer` protocol which must be able to provide the appropriate auth information
- `noMethod` - if you are only using public channels then you do not need to set an `authMethod` (this is the default value)

This is the `AuthRequestBuilderProtocol` definition:

```swift
public protocol AuthRequestBuilderProtocol {
    func requestFor(socketID: String, channelName: String) -> URLRequest?
}
```

This is the `Authorizer` protocol definition:

```swift
public protocol Authorizer {
    func fetchAuthValue(socketID: String, channelName: String, completionHandler: (PusherAuth?) -> ())
}
```

where `PusherAuth` is defined as:

```swift
public class PusherAuth: NSObject {
    public let auth: String
    public let channelData: String?
    public let sharedSecret: String?

    public init(auth: String, channelData: String? = nil, sharedSecret: String? = nil) {
        self.auth = auth
        self.channelData = channelData
        self.sharedSecret = sharedSecret
    }
}
```

Provided the authorization process succeeds you need to then call the supplied `completionHandler` with a `PusherAuth` object so that the subscription process can complete.

If for whatever reason your authorization process fails then you just need to call the `completionHandler` with `nil` as the only parameter.

Note that if you want to specify the cluster to which you want to connect then you use the `host` property as follows:

#### Swift

```swift
let options = PusherClientOptions(
    host: .cluster("eu")
)
```

#### Objective-C

```objc
OCAuthMethod *authMethod = [[OCAuthMethod alloc] initWithAuthEndpoint:@"https://your.authendpoint/pusher/auth"];
OCPusherHost *host = [[OCPusherHost alloc] initWithCluster:@"eu"];
PusherClientOptions *options = [[PusherClientOptions alloc]
                                initWithOcAuthMethod:authMethod
                                autoReconnect:YES
                                ocHost:host
                                port:nil
                                useTLS:YES
                                activityTimeout:nil];
```

All of these configuration options need to be passed to a `PusherClientOptions` object, which in turn needs to be passed to the Pusher object, when instantiating it, for example:

#### Swift

```swift
let options = PusherClientOptions(
    authMethod: .endpoint(authEndpoint: "http://localhost:9292/pusher/auth")
)

let pusher = Pusher(key: "APP_KEY", options: options)
```

#### Objective-C

```objc
OCAuthMethod *authMethod = [[OCAuthMethod alloc] initWithAuthEndpoint:@"https://your.authendpoint/pusher/auth"];
OCPusherHost *host = [[OCPusherHost alloc] initWithCluster:@"eu"];
PusherClientOptions *options = [[PusherClientOptions alloc]
                                initWithOcAuthMethod:authMethod
                                autoReconnect:YES
                                ocHost:host
                                port:nil
                                useTLS:YES
                                activityTimeout:nil];
pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY" options:options];
```

As you may have noticed, this differs slightly for Objective-C usage. The main changes are that you need to use `OCAuthMethod` and `OCPusherHost` in place of `AuthMethod` and `PusherHost`. The `OCAuthMethod` class has the following functions that you can call in your Objective-C code.

```swift
public init(authEndpoint: String)

public init(authRequestBuilder: AuthRequestBuilderProtocol)

public init(secret: String)

public init()
```

```objc
OCAuthMethod *authMethod = [[OCAuthMethod alloc] initWithSecret:@"YOUR_APP_SECRET"];
PusherClientOptions *options = [[PusherClientOptions alloc] initWithAuthMethod:authMethod];
```

The case is similar for `OCPusherHost`. You have the following functions available:

```objc
public init(host: String)

public init(cluster: String)
```

```objc
[[OCPusherHost alloc] initWithCluster:@"YOUR_CLUSTER_SHORTCODE"];
```

Authenticated channel example:

#### Swift

```swift
class AuthRequestBuilder: AuthRequestBuilderProtocol {
    func requestFor(socketID: String, channelName: String) -> URLRequest? {
        var request = URLRequest(url: URL(string: "http://localhost:9292/builder")!)
        request.httpMethod = "POST"
        request.httpBody = "socket_id=\(socketID)&channel_name=\(channel.name)".data(using: String.Encoding.utf8)
        request.addValue("myToken", forHTTPHeaderField: "Authorization")
        return request
    }
}

let options = PusherClientOptions(
    authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: AuthRequestBuilder())
)
let pusher = Pusher(
  key: "APP_KEY",
  options: options
)
```

#### Objective-C

```objc
@interface AuthRequestBuilder : NSObject <AuthRequestBuilderProtocol>

- (NSURLRequest *)requestForSocketID:(NSString *)socketID channelName:(NSString *)channelName;

@end

@implementation AuthRequestBuilder

- (NSURLRequest *)requestForSocketID:(NSString *)socketID channelName:(NSString *)channelName {
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"http://localhost:9292/pusher/auth"]];
    NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc] initWithURL: [[NSURL alloc] initWithString:@"http://localhost:9292/pusher/auth"]];

    NSString *dataStr = [NSString stringWithFormat: @"socket_id=%@&channel_name=%@", socketID, channelName];
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    mutableRequest.HTTPBody = data;
    mutableRequest.HTTPMethod = @"POST";
    [mutableRequest addValue:@"myToken" forHTTPHeaderField:@"Authorization"];

    request = [mutableRequest copy];

    return request;
}

@end

OCAuthMethod *authMethod = [[OCAuthMethod alloc] initWithAuthRequestBuilder:[[AuthRequestBuilder alloc] init]];
PusherClientOptions *options = [[PusherClientOptions alloc] initWithAuthMethod:authMethod];
```

Where `"Authorization"` and `"myToken"` are the field and value your server is expecting in the headers of the request.

## Connection

A Websocket connection is established by providing your API key to the constructor function:

#### Swift

```swift
let pusher = Pusher(key: "APP_KEY")
pusher.connect()
```

#### Objective-C

```objc
Pusher *pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY"];
[pusher connect];
```

This returns a client object which can then be used to subscribe to channels and then calling `connect()` triggers the connection process to start.

**Important:** You must keep a strong reference to the `Pusher` client. You could achieve that by making `pusher` a property of your app delegate, for example.

You can also set a `userDataFetcher` on the connection object.

- `userDataFetcher (() -> PusherPresenceChannelMember)` - if you are subscribing to an authenticated channel and wish to provide a function to return user data

You set it like this:

#### Swift

```swift
let pusher = Pusher(key: "APP_KEY")

pusher.connection.userDataFetcher = { () -> PusherPresenceChannelMember in
    return PusherPresenceChannelMember(userId: "123", userInfo: ["twitter": "hamchapman"])
}
```

#### Objective-C

```objc
Pusher *pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY"];

pusher.connection.userDataFetcher = ^PusherPresenceChannelMember* () {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    return [[PusherPresenceChannelMember alloc] initWithUserId:uuid userInfo:nil];
};
```

### Connection delegate

There is a `PusherDelegate` that you can use to get notified of connection-related information. These are the functions that you can optionally implement when conforming to the `PusherDelegate` protocol:

```swift
@objc optional func changedConnectionState(from old: ConnectionState, to new: ConnectionState)
@objc optional func subscribedToChannel(name: String)
@objc optional func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?)
@objc optional func debugLog(message: String)
@objc(receivedError:) optional func receivedError(error: PusherError)
@objc optional func failedToDecryptEvent(eventName: String, channelName: String, data: String?)
```

The names of the functions largely give away what their purpose is but just for completeness:

- `changedConnectionState` - use this if you want to use connection state changes to perform different actions / UI updates
- `subscribedToChannel` - use this if you want to be informed of when a channel has successfully been subscribed to, which is useful if you want to perform actions that are only relevant after a subscription has succeeded, e.g. logging out the members of a presence channel
- `failedToSubscribeToChannel` - use this if you want to be informed of a failed subscription attempt, which you could use, for example, to then attempt another subscription or make a call to a service you use to track errors
- `debugLog` - use this if you want to log Pusher-related events, e.g. the underlying websocket receiving a message
- `receivedError` - use this if you want to be informed of errors received from Pusher Channels e.g. `Application is over connection quota`. You can find some of the possible errors listed [here](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol#error-codes).
- `failedToDecryptEvent` - only used with private encrypted channels - use this if you want to be notified if any messages fail to decrypt.

Setting up a delegate looks like this:

#### Swift

```swift
class ViewController: UIViewController, PusherDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        let pusher = Pusher(key: "APP_KEY")
        pusher.connection.delegate = self
        // ...
    }
}
```

#### Objective-C

```objc
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.client = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY"];

    self.client.connection.delegate = self;
    // ...
}
```

Here are examples of setting up a class with functions for each of the optional protocol functions:

#### Swift

```swift
class DummyDelegate: PusherDelegate {
    func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        // ...
    }

    func debugLog(message: String) {
        // ...
    }

    func subscribedToChannel(name: String) {
        // ...
    }

    func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?) {
        // ...
    }

    func receivedError(error: PusherError) {
        let message = error.message
        if let code = error.code {
            // ...
        }
    }

    func failedToDecryptEvent(eventName: String, channelName: String, data: String?) {
      // ...
    }

}
```

#### Objective-C

```objc
@interface DummyDelegate : NSObject <PusherDelegate>

- (void)changedConnectionState:(enum ConnectionState)old to:(enum ConnectionState)new_
- (void)debugLogWithMessage:(NSString *)message
- (void)subscribedToChannelWithName:(NSString *)name
- (void)failedToSubscribeToChannelWithName:(NSString *)name response:(NSURLResponse *)response data:(NSString *)data error:(NSError *)error
- (void)receivedError:(PusherError *)error
- (void)failedToDecryptEventWithEventName:(NSString *)eventName channelName:(NSString *)channelName data:(NSString *)data

@end

@implementation DummyDelegate

- (void)changedConnectionState:(enum ConnectionState)old to:(enum ConnectionState)new_ {
    // ...
}

- (void)debugLogWithMessage:(NSString *)message {
    // ...
}

- (void)subscribedToChannelWithName:(NSString *)name {
    // ...
}

- (void)failedToSubscribeToChannelWithName:(NSString *)name response:(NSURLResponse *)response data:(NSString *)data error:(NSError *)error {
    // ...
}

- (void)receivedError:(PusherError *)error {
    NSNumber *code = error.codeOC;
    NSString *message = error.message;
    // ...
}

- (void)failedToDecryptEventWithEventName:(NSString *)eventName channelName:(NSString *)channelName data:(NSString *)data {
  // ...
}

@end
```

The different states that the connection can be in are (Objective-C integer enum cases in brackets):

- `connecting (0)` - the connection is about to attempt to be made
- `connected (1)` - the connection has been successfully made
- `disconnecting (2)` - the connection has been instructed to disconnect and it is just about to do so
- `disconnected (3)` - the connection has disconnected and no attempt will be made to reconnect automatically
- `reconnecting (4)` - an attempt is going to be made to try and re-establish the connection

There is a `stringValue()` function that you can call on `ConnectionState` objects in order to get a `String` representation of the state, for example `"connecting"`.

### Reconnection

There are three main ways in which a disconnection can occur:

- The client explicitly calls disconnect and a close frame is sent over the websocket connection
- The client experiences some form of network degradation which leads to a heartbeat (ping/pong) message being missed and thus the client disconnects
- The Pusher server closes the websocket connection; typically this will only occur during a restart of the Pusher socket servers and an almost immediate reconnection should occur

In the case of the first type of disconnection the library will (as you'd hope) not attempt a reconnection.

The library uses [NWWebSocket](https://github.com/pusher/NWWebSocket) which attempts to detect network degradation events that lead to disconnection. If this is detected then the library will attempt to reconnect (by default) with an exponential backoff, indefinitely (the maximum time between reconnect attempts is, by default, capped at 120 seconds). The value of `reconnectAttemptsMax` is a public property on the `PusherConnection` and so can be changed if you wish to set a maximum number of reconnect attempts.

If the Pusher servers close the websocket, or if a disconnection happens due to network events that aren't covered by NWWebSocket, then the library will still attempt to reconnect as described above.

All of this is the case if you have the client option of `autoReconnect` set as `true`, which it is by default. If the reconnection strategies are not suitable for your use case then you can set `autoReconnect` to `false` and implement your own reconnection strategy based on the connection state changes.

N.B: If the Pusher servers close the websocket with a [Channels Protocol closure code](https://pusher.com/docs/channels/library_auth_reference/pusher-websockets-protocol#connection-closure), then the `autoReconnect` option is ignored, and the reconnection strategy is determined by the specific closure code that was received.

There are a couple of properties on the connection (`PusherConnection`) that you can set that affect how the reconnection behavior works. These are:

- `public var reconnectAttemptsMax: Int? = 6` - if you set this to `nil` then there is no maximum number of reconnect attempts and so attempts will continue to be made with an exponential backoff (based on number of attempts), otherwise only as many attempts as this property's value will be made before the connection's state moves to `.disconnected`
- `public var maxReconnectGapInSeconds: Double? = nil` - if you want to set a maximum length of time (in seconds) between reconnect attempts then set this property appropriately

Note that the number of reconnect attempts gets reset to 0 as soon as a successful connection is made.

## Subscribing

### Public channels

The default method for subscribing to a channel involves invoking the `subscribe` method of your client object:

#### Swift

```swift
let myChannel = pusher.subscribe("my-channel")
```

#### Objective-C

```objc
PusherChannel *myChannel = [pusher subscribeWithChannelName:@"my-channel"];
```

This returns PusherChannel object, which events can be bound to.

### Private channels

Private channels are created in exactly the same way as public channels, except that they reside in the 'private-' namespace. This means prefixing the channel name:

#### Swift

```swift
let myPrivateChannel = pusher.subscribe("private-my-channel")
```

#### Objective-C

```objc
PusherChannel *myPrivateChannel = [pusher subscribeWithChannelName:@"private-my-channel"];
```

Subscribing to private channels involves the client being authenticated. See the [Configuration](#configuration) section for the authenticated channel example for more information.

### Private encrypted channels

Similar to Private channels, you can also subscribe to a [private encrypted channel](https://pusher.com/docs/channels/using_channels/encrypted-channels). This library now fully supports end-to-end encryption. This means that only you and your connected clients will be able to read your messages. Pusher cannot decrypt them.

Like with private channels, you must provide an authentication endpoint. That endpoint must be using a [server client that supports end-to-end encryption](https://pusher.com/docs/channels/using_channels/encrypted-channels#server). There is a [demonstration endpoint to look at using nodejs](https://github.com/pusher/pusher-channels-auth-example#using-e2e-encryption). 

The shared secret used to decrypt events is loaded from the same auth endpoint request that is used to authorize your subscription. There is also a mechanism for reloading the shared secret if your encryption master key changes. If an event is encountered that cannot be decrypted, a request is made to your auth endpoint to attempt to load the new shared secret. If that request fails or if the returned secret still cannot decrypt the event then that event will be skipped, the `failedToDecryptEvent` connection delegate function will be called, and the next received event will be processed. 

Because of the requirement to reload the shared secret on demand, you can only use the following [auth methods](#configuration): `endpoint`, `authRequestBuilder`, `authorizer`. It is not possible to pass an instance of `PusherAuth` to the `subscribe` function if you are subscribing to an encrypted channel.

#### Limitations

* Is not safe for use in extensions
* Client events are not supported on encrypted channels

#### Swift

```swift
let privateEncryptedChannel = pusher.subscribe(channelName: "private-encrypted-my-channel")
```

#### Objective-C

```objc
PusherChannel *privateEncryptedChannel = [pusher subscribeWithChannelName:@"private-encrypted-my-channel"];
```

There is also an optional callback in the connection delegate when you can listen for
any failed decryption events:

```swift
optional func failedToDecryptEvent(eventName: String, channelName: String, data: String?)
```

### Presence channels

Presence channels are channels whose names are prefixed by `presence-`.

The recommended way of subscribing to a presence channel is to use the `subscribeToPresenceChannel` function, as opposed to the standard `subscribe` function. Using the `subscribeToPresenceChannel` function means that you get a `PusherPresenceChannel` object returned, as opposed to a standard `PusherChannel`. This `PusherPresenceChannel` object has some extra, presence-channel-specific functions available to it, such as `members`, `me`, and `findMember`.

#### Swift

```swift
let myPresenceChannel = pusher.subscribeToPresenceChannel(channelName: "presence-my-channel")
```

#### Objective-C

```objc
PusherPresenceChannel *myPresenceChannel = [pusher subscribeToPresenceChannelWithChannelName:@"presence-my-channel"];
```

As alluded to, you can still subscribe to presence channels using the `subscribe` method, but the channel object you get back won't have access to the presence-channel-specific functions, unless you choose to cast the channel object to a `PusherPresenceChannel`.

#### Swift

```swift
let myPresenceChannel = pusher.subscribe("presence-my-channel")
```

#### Objective-C

```objc
PusherChannel *myPresenceChannel = [pusher subscribeWithChannelName:@"presence-my-channel"];
```

You can also provide functions that will be called when members are either added to or removed from the channel. These are available as parameters to both `subscribe` and `subscribeToPresenceChannel`.

#### Swift

```swift
let onMemberChange = { (member: PusherPresenceChannelMember) in
    print(member)
}

let chan = pusher.subscribeToPresenceChannel("presence-channel", onMemberAdded: onMemberChange, onMemberRemoved: onMemberChange)
```

#### Objective-C

```objc
void (^onMemberChange)(PusherPresenceChannelMember*) = ^void (PusherPresenceChannelMember *member) {
    NSLog(@"%@", member);
};

PusherChannel *myPresenceChannel = [pusher subscribeWithChannelName:@"presence-my-channel" onMemberAdded:onMemberChange onMemberRemoved:onMemberChange];
```

**Note**: The `members` and `myId` properties of `PusherPresenceChannel` objects (and functions that get the value of these properties) will only be set once subscription to the channel has succeeded.

The easiest way to find out when a channel has been successfully subscribed to is to bind to the event named `pusher:subscription_succeeded` on the channel you're interested in. It would look something like this:

#### Swift

```swift
let pusher = Pusher(key: "YOUR_APP_KEY")

let chan = pusher.subscribeToPresenceChannel("presence-channel")

chan.bind(eventName: "pusher:subscription_succeeded", eventCallback: { event in
    print("Subscribed!")
    print("I can now access myId: \(chan.myId)")
    print("And here are the channel members: \(chan.members)")
})
```

#### Objective-C

```objc
Pusher *pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY"];
PusherPresenceChannel *chan = [pusher subscribeToPresenceChannelWithChannelName:@"presence-channel"];

[chan bindWithEventName:@"pusher:subscription_succeeded" eventCallback: ^void (PusherEvent *event) {
    NSLog(@"Subscribed!");
    NSLog(@"I can now access myId: %@", chan.myId);
    NSLog(@"And here are my channel members: %@", chan.members);
}];
```

You can also be notified of a successful subscription by using the `subscriptionDidSucceed` delegate method that is part of the `PusherDelegate` protocol.

Here is an example of using the delegate:

#### Swift

```swift
class DummyDelegate: PusherDelegate {
    func subscribedToChannel(name: String) {
        if channelName == "presence-channel" {
            if let presChan = pusher.connection.channels.findPresence(channelName) {
                // in here you can now have access to the channel's members and myId properties
                print(presChan.members)
                print(presChan.myId)
            }
        }
    }
}

let pusher = Pusher(key: "YOUR_APP_KEY")
pusher.connection.delegate = DummyDelegate()
let chan = pusher.subscribeToPresenceChannel("presence-channel")
```

#### Objective-C

```objc
@implementation DummyDelegate

- (void)subscribedToChannelWithName:(NSString *)name {
    if ([channelName isEqual: @"presence-channel"]) {
        PusherPresenceChannel *presChan = [self.client.connection.channels findPresenceWithName:@"presence-channel"];
        NSLog(@"%@", [presChan members]);
        NSLog(@"%@", [presChan myId]);
    }
}

@implementation ViewController

- (void)viewDidLoad {
    // ...

    Pusher *pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY"];
    pusher.connection.delegate = [[DummyDelegate alloc] init];
    PusherChannel *chan = [pusher subscribeToPresenceChannelWithChannelName:@"presence-channel"];
```

Note that both private and presence channels require the user to be authenticated in order to subscribe to the channel. This authentication can either happen inside the library, if you configured your Pusher object with your app's secret, or an authentication request is made to an authentication endpoint that you provide, again when instantiating your Pusher object.

We recommend that you use an authentication endpoint over including your app's secret in your app in the vast majority of use cases. If you are completely certain that there's no risk to you including your app's secret in your app, for example if your app is just for internal use at your company, then it can make things easier than setting up an authentication endpoint.

### Subscribing with self-provided auth values

It is possible to subscribe to channels that require authentication by providing the auth information at the point of calling `subscribe` or `subscribeToPresenceChannel`. This is done as shown below:

#### Swift

```swift
let pusherAuth = PusherAuth(auth: yourAuthString, channelData: yourOptionalChannelDataString)
let chan = self.pusher.subscribe(channelName, auth: pusherAuth)
```

This PusherAuth object can be initialized with just an auth (String) value if the subscription is to a private channel, or both an `auth (String)` and `channelData (String)` pair of values if the subscription is to a presence channel.

These `auth` and `channelData` values are the values that you received if the json object created by a call to pusher.authenticate(...) in one of our various server libraries.

Keep in mind that in order to generate a valid auth value for a subscription the `socketId` (i.e. the unique identifier for a web socket connection to the Pusher servers) must be present when the auth value is generated. As such, the likely flow for using this is something like this would involve checking for when the connection state becomes `connected` before trying to subscribe to any channels requiring authentication.

## Binding to events

Events can be bound to at 2 levels; globally and per channel. When binding to an event you can choose to save the return value, which is a unique identifier for the event handler that gets created. The only reason to save this is if you're going to want to unbind from the event at a later point in time. There is an example of this below.

### Per-channel events

These are bound to a specific channel, and mean that you can reuse event names in different parts of your client application. 

#### Swift

```swift
let pusher = Pusher(key: "YOUR_APP_KEY")
let myChannel = pusher.subscribe("my-channel")

myChannel.bind(eventName: "new-price", eventCallback: { (event: PusherEvent) -> Void in
    if let data: String = event.data {
        // `data` is a string that you can parse if necessary.
    }
})
```

The callback is passed a `PusherEvent`  (see [docs](#pusherevent)).

<details><summary>View legacy approach</summary>

```swift
let pusher = Pusher(key: "YOUR_APP_KEY")
let myChannel = pusher.subscribe("my-channel")

myChannel.bind(eventName: "new-price", callback: { (data: Any?) -> Void in
    if let data = data as? [String : AnyObject] {
        if let price = data["price"] as? String, company = data["company"] as? String {
            print("\(company) is now priced at \(price)")
        }
    }
})
```
</details>

#### Objective-C

```objc
Pusher *pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY"];
PusherChannel *chan = [pusher subscribeWithChannelName:@"my-channel"];

[chan bindWithEventName:@"new-price" eventCallback:^void (PusherEvent *event) {
    NSString *data = event.data;
    // `data` is a string that you can parse if necessary.
}];
```
<details><summary>View legacy approach</summary>

```objc
Pusher *pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY"];
PusherChannel *chan = [pusher subscribeWithChannelName:@"my-channel"];

[chan bindWithEventName:@"new-price" callback:^void (NSDictionary *data) {
    NSString *price = data[@"price"];
    NSString *company = data[@"company"];

    NSLog(@"%@ is now priced at %@", company, price);
}];
```
</details>

### Global events

You can attach behavior to these events regardless of the channel the event is broadcast to. 

#### Swift

```swift
let pusher = Pusher(key: "YOUR_APP_KEY")
pusher.subscribe("my-channel")

pusher.bind(eventCallback: { (event: PusherEvent) -> Void in
    if let data: String = event.data {
        // `data` is a string that you can parse if necessary.
    }
})
```
The callback is passed a `PusherEvent`  (see [docs](#pusherevent)).

<details><summary>View legacy approach</summary>

```swift
let pusher = Pusher(key: "YOUR_APP_KEY")
pusher.subscribe("my-channel")

pusher.bind(callback: { (event: Any?) -> Void in
    if let data = event["data"] as? [String : AnyObject] {
        if let commenter = data["commenter"] as? String, message = data["message"] as? String {
            print("\(commenter) wrote \(message)")
        }
    }
})
```
</details>

#### Objective-C

```objc
Pusher *pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY"];
PusherChannel *chan = [pusher subscribeWithChannelName:@"my-channel"];

[pusher bindWithEventCallback: ^void (PusherEvent *event) {
    // `data` is a string that you can parse if necessary.
    NSString *data = event.data;
}];
```
<details><summary>View legacy approach</summary>

```objc
Pusher *pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY"];
PusherChannel *chan = [pusher subscribeWithChannelName:@"my-channel"];

[pusher bind: ^void (NSDictionary *event) {
    NSDictionary *data = event[@"data"];
    NSString *commenter = data[@"commenter"];
    NSString *message = data[@"message"];

    NSLog(@"%@ wrote %@", commenter, message);
}];
```
</details>

### Callback parameters

#### PusherEvent

The callbacks you bind receive a `PusherEvent`:

|  Property            | Type           | Description  |
| ------------------ |--------------| ------------
| `eventName`       | `String`      | The name of the event. |
| `channelName`   | `String?`    | The name of the channel that the event was triggered on. |
| `data`                | `String?`     | The data that was passed to `trigger`, encoded as a string. If you passed an object then that will have been serialized to a JSON string which you can parse as necessary. See [parsing event data](#parsing-event-data). |
| `userId`            | `String?`     | The ID of the user who triggered the event. This is only available for client events triggered on presence channels. |

| Function            | Parameters                                                    |  Return Type           | Description                                                                                                                                                                                                     |
| -----------------  |---------------------------------------------------| -----------------------| ----------------------------------------------------------------------------------------------------------------------------------------------------------|
| `property`   | `withKey: String` - The key of the property |  `Any?`                      | A helper function for accessing raw properties from the websocket event. Data returned by this function should not be considered stable and it is recommended that you use the properties above instead. |

### Parsing event data

The `data` property of  [`PusherEvent`](#pusherevent) contains the string representation of the data that you passed when you triggered the event. If you passed an object then that object will have been serialized to JSON. You can parse that JSON as appropriate. You can make use of [`JSONSerialization`](https://developer.apple.com/swift/blog/?id=37), or you can use the `JSONDecoder` to decode the JSON into a Codable Class or Struct. See the Apple docs: [Encoding and Decoding Custom Types](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types).

For example, the following might be an example of a stock tracking app publishing price updates for companies. You can decode the "price-update" event into a struct in Swift:

```swift
struct PriceUpdate: Codable {
    public let company: String,
    public let price: Int,
}

let pusher = Pusher(key: "YOUR_APP_KEY")
let myChannel = pusher.subscribe("my-channel")
let decoder = JSONDecoder()

myChannel.bind(eventName: "price-update", eventCallback: { (event: PusherEvent) -> Void in
    guard let json: String = event.data,
        let jsonData: Data = json.data(using: .utf8)
    else{
        print("Could not convert JSON string to data")
        return
    }

    let decoded = try? decoder.decode(PriceUpdate.self, from: jsonData)
    guard let priceUpdate = decoded else {
        print("Could not decode price update")
        return
    }

    print("\(priceUpdate.company) is now priced at \(priceUpdate.price)")
})

```

Alternatively, you could use [`JSONSerialization`](https://developer.apple.com/documentation/foundation/jsonserialization) to decode the JSON into Swift data types: 

#### Swift

```swift
let pusher = Pusher(key: "YOUR_APP_KEY")
let myChannel = pusher.subscribe("my-channel")

myChannel.bind(eventName: "price-update", eventCallback: { (event: PusherEvent) -> Void in
    guard let json: String = event.data,
        let jsonData: Data = json.data(using: .utf8)
    else{
        print("Could not convert JSON string to data")
        return
    }

    let decoded = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
    guard let priceUpdate = decoded else {
        print("Could not decode price update")
        return
    }

    if let company = priceUpdate["company"] as? String, let price = priceUpdate["price"] as? String {
        print("\(company) is now priced at \(price)")
    }
})
```
#### Objective-C

```objc
Pusher *pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY"];
PusherChannel *chan = [pusher subscribeWithChannelName:@"my-channel"];

[chan bindWithEventName:@"price-update" eventCallback:^void (PusherEvent *event) {
    NSString *dataString = event.data;
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];

    NSError *error;
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];

    NSString *price = jsonObject[@"price"];
    NSString *company = jsonObject[@"company"];

    NSLog(@"%@ is now priced at %@", company, price);
}];
```

### Receiving errors

Errors received from Pusher Channels can be accessed via the [connection delegate](#connection-delegate). This was previously done by binding callbacks.

<details><summary>View legacy approach</summary>

Errors are sent to the client for which they are relevant with an event name of `pusher:error`. These can be received and handled using code as follows. Obviously the specifics of how to handle them are left up to the developer but this displays the general pattern.

#### Swift

```swift
pusher.bind({ (message: Any?) in
    if let message = message as? [String: AnyObject], eventName = message["event"] as? String where eventName == "pusher:error" {
        if let data = message["data"] as? [String: AnyObject], errorMessage = data["message"] as? String {
            print("Error message: \(errorMessage)")
        }
    }
})
```

#### Objective-C
    
```objc
[pusher bind:^void (NSDictionary *data) {
    NSString *eventName = data[@"event"];

    if ([eventName isEqualToString:@"pusher:error"]) {
        NSString *errorMessage = data[@"data"][@"message"];
        NSLog(@"Error message: %@", errorMessage);
    }
}];
```

The sort of errors you might get are:

```bash
# if attempting to subscribe to an already subscribed-to channel

"{\"event\":\"pusher:error\",\"data\":{\"code\":null,\"message\":\"Existing subscription to channel presence-channel\"}}"

# if the auth signature generated by your auth mechanism is invalid

"{\"event\":\"pusher:error\",\"data\":{\"code\":null,\"message\":\"Invalid signature: Expected HMAC SHA256 hex digest of 200557.5043858:presence-channel:{\\\"user_id\\\":\\\"200557.5043858\\\"}, but got 8372e1649cf5a45a2de3cd97fe11d85de80b214243e3a9e9f5cee502fa03f880\"}}"
```

You can see that the general form they take is:

```bash
{
  "event": "pusher:error",
  "data": {
    "code": null,
    "message": "Error message here"
  }
}
```

</details>

### Unbind event handlers

You can remove previously-bound handlers from an object by using the `unbind` function. For example,

#### Swift

```swift
let pusher = Pusher(key: "YOUR_APP_KEY")
let myChannel = pusher.subscribe("my-channel")

let eventHandlerId = myChannel.bind(eventName: "new-price", eventCallback: { (event: PusherEvent) -> Void in
  //...
})

myChannel.unbind(eventName: "new-price", callbackId: eventHandlerId)
```

#### Objective-C

```objc
Pusher *pusher = [[Pusher alloc] initWithAppKey:@"YOUR_APP_KEY"];
PusherChannel *chan = [pusher subscribeWithChannelName:@"my-channel"];

NSString *callbackId = [chan bindWithEventName:@"new-price" eventCallback:^void (PusherEvent *event) {
    //...
}];

[chan unbindWithEventName:@"new-price" callbackId:callbackId];
```

You can unbind from events at both the global and per channel level. For both objects you also have the option of calling `unbindAll`, which, as you can guess, will unbind all eventHandlers on the object.

## Triggering events

Once a [private](https://pusher.com/docs/channels/using_channels/private-channels) or [presence](https://pusher.com/docs/channels/using_channels/presence-channels) subscription has been authorized (see [authenticating users](https://pusher.com/docs/channels/server_api/authenticating-users)) and the subscription has succeeded, it is possible to trigger events on those channels.

```swift
chan.trigger(eventName: "client-myEvent", data: ["myName": "Bob"])
```

Events triggered by clients are called [client events](https://pusher.com/docs/channels/using_channels/events#triggering-client-events). Because they are being triggered from a client which may not be trusted there are a number of enforced rules when using them. Some of these rules include:

* Event names must have a `client-` prefix
* Rate limits
* You can only trigger an event when the subscription has succeeded

For full details see the [client events documentation](https://pusher.com/docs/channels/using_channels/events#triggering-client-events).

## Testing

There are a set of tests for the library that can be run using the standard method (Command-U in Xcode).

The tests also get run on [Travis-CI](https://travis-ci.org/pusher/pusher-websocket-swift). See [.travis.yml](https://github.com/pusher/pusher-websocket-swift/blob/master/.travis.yml) for details on how the Travis tests are run.

## Extensions

- [RxPusherSwift](https://github.com/jondwillis/RxPusherSwift)

## Communication

- If you have found a bug, please open an issue.
- If you have a feature request, please open an issue.
- If you want to contribute, please submit a pull request (preferably with some tests 🙂 ).

## Credits

PusherSwift is owned and maintained by [Pusher](https://pusher.com). It was originally created by [Hamilton Chapman](https://github.com/hamchapman).

It uses code from the following repositories:

- [TweetNacl](https://github.com/bitmark-inc/tweetnacl-swiftwrap)

The individual licenses for these libraries are included in the corresponding Swift files.

## License

PusherSwift is released under the MIT license. See [LICENSE](https://github.com/pusher/pusher-websocket-swift/blob/master/LICENSE.md) for details.
