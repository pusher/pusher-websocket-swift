# PusherSwift (pusher-websocket-swift)

[![Build Status](https://travis-ci.org/pusher/pusher-websocket-swift.svg?branch=master)](https://travis-ci.org/pusher/pusher-websocket-swift)
[![Cocoapods Compatible](https://img.shields.io/cocoapods/v/PusherSwift.svg)](https://img.shields.io/cocoapods/v/PusherSwift.svg)
[![Platform](https://img.shields.io/cocoapods/p/PusherSwift.svg?style=flat)](http://cocoadocs.org/docsets/PusherSwift)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Twitter](https://img.shields.io/badge/twitter-@Pusher-blue.svg?style=flat)](http://twitter.com/Pusher)
[![GitHub license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/pusher/pusher-websocket-swift/master/LICENSE.md)


## I just want to copy and paste some code to get me started

What else would you want? Head over to the example app [ViewController.swift](https://github.com/pusher/pusher-websocket-swift/blob/master/Example/ViewController.swift) to get some code you can drop in to get started.

## Looking for the push notifications beta?

Head over to the [push-notifications](https://github.com/pusher/pusher-websocket-swift/tree/push-notifications) branch.


## Table of Contents

* [Installation](#installation)
* [Configuration](#configuration)
* [Connection](#connection)
  * [Connection state changes](#connection-state-changes)
  * [Reconnection](#reconnection)
* [Subscribing to channels](#subscribing)
* [Binding to events](#binding-to-events)
  * [Globally](#global-events)
  * [Per-channel](#per-channel-events)
  * [Receiving errors](#receiving-errors)
* [Presence channel specifics](#presence-channel-specifics)
* [Testing](#testing)
* [Communication](#communication)
* [Credits](#credits)
* [License](#license)


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
platform :ios, '8.0'
use_frameworks!

pod 'PusherSwift'
```

Then, run the following command:

```bash
$ pod install
```

If you find that you're having the most recent version installed when you run `pod install` then try running:

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


## Configuration

There are a number of configuration parameters which can be set for the Pusher client. They are:

- `authMethod (AuthMethod)` - the method you would like the client to use to authenticate subscription requests to channels requiring authentication (see below for more details)
- `attemptToReturnJSONObject (Bool)` - whether or not you'd like the library to try and parse your data as JSON (or not, and just return a string)
- `encrypted (Bool)` - whether or not you'd like to use encypted transport or not, default is `true`
- `autoReconnect (Bool)` - set whether or not you'd like the library to try and autoReconnect upon disconnection
- `host (PusherHost)` - set a custom value for the host you'd like to connect to, e.g. `PusherHost.Host("ws-test.pusher.com")`
- `port (Int)` - set a custom value for the port that you'd lilke to connect to

The `authMethod` parameter must be of the type `AuthMethod`. This is an enum defined as:

```swift
public enum AuthMethod {
    case Endpoint(authEndpoint: String)
    case AuthRequestBuilder(authRequestBuilder: AuthRequestBuilderProtocol)
    case Internal(secret: String)
    case NoMethod
}
```

- `Endpoint(authEndpoint: String)` - the client will make a `POST` request to the endpoint you specify with the socket ID of the client and the channel name attempting to be subscribed to
- `AuthRequestBuilder(authRequestBuilder: AuthRequestBuilderProtocol)` - you specify an object that conforms to the `AuthRequestBuilderProtocol` (defined below), which must generate an `NSURLRequest` object that will be used to make the auth request
- `Internal(secret: String)` - your app's secret so that authentication requests do not need to be made to your authentication endpoint and instead subscriptions can be authenticated directly inside the library (this is mainly desgined to be used for development)
- `NoMethod` - if you are only using public channels then you do not need to set an `authMethod` (this is the default value)

This is the `AuthRequestBuilderProtocol` definition:

```swift
public protocol AuthRequestBuilderProtocol {
    func requestFor(socketID: String, channel: PusherChannel) -> NSMutableURLRequest
}
```

Note that if you want to specify the cluster to which you want to connect then you use the `host` property as follows:

```swift
let options = PusherClientOptions(
    host: .Cluster("eu")
)
```

All of these configuration options need to be passed to a `PusherClientOptions` object, which in turn needs to be passed to the Pusher object, when instantiating it, for example:

```swift
let options = PusherClientOptions(
    authMethod: .Endpoint(authEndpoint: "http://localhost:9292/pusher/auth")
)

let pusher = Pusher(key: "APP_KEY", options: options)
```

Authenticated channel example:

```swift
struct AuthRequestBuilder: AuthRequestBuilderProtocol {
    func requestFor(socketID: String, channel: PusherChannel) -> NSMutableURLRequest {
        let request = NSMutableURLRequest(URL: NSURL(string: "http://localhost:9292/builder")!)
        request.HTTPMethod = "POST"
        request.HTTPBody = "socket_id=\(socketID)&channel_name=\(channel.name)".dataUsingEncoding(NSUTF8StringEncoding)
        request.addValue("myToken", forHTTPHeaderField: "Authorization")
        return request
    }
}

let options = PusherClientOptions(
    authMethod: AuthMethod.AuthRequestBuilder(authRequestBuilder: AuthRequestBuilder())
)
let pusher = Pusher(
  key: "APP_KEY",
  options: options
)
```

Where `"Authorization"` and `"myToken"` are the field and value your server is expecting in the headers of the request.

## Connection

A Websocket connection is established by providing your API key to the constructor function:

```swift
let pusher = Pusher(key: "APP_KEY")
pusher.connect()
```

This returns a client object which can then be used to subscribe to channels and then calling `connect()` triggers the connection process to start.

You can also set some useful properties on the connection object. These are the following:

- `debugLogger ((String) -> ())` - provide a logger function that will be passed a string when a message is either sent of received over the websocket connection
- `userDataFetcher (() -> PusherUserData)` - if you are subscribing to an authenticated channel and wish to provide a function to return user data

As you'd expect, you set these like this:

```swift
let pusher = Pusher(key: "APP_KEY")
pusher.connection.debugLogger = { (str: String) in
    print(str)
}
pusher.connection.userDataFetcher = { () -> PusherUserData in
    return PusherUserData(userId: "123", userInfo: ["twitter": "hamchapman"])
}
```


### Connection state changes

There is a connection state change delegate that you can implement if you want to get updated when the connection state changes.

You use it like this:

```swift
class ViewController: UIViewController, ConnectionStateChangeDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        let pusher = Pusher(key: "APP_KEY")
        pusher.connection.stateChangeDelegate = self
        pusher.connect()
        // ...
    }

    func connectionChange(old: ConnectionState, new: ConnectionState) {
        print("old: \(old) -> new: \(new)")
    }
}
```

The different states that the connection can be in are:

* `Connecting` - the connection is about to attempt to be made
* `Connected` - the connection has been successfully made
* `Disconnecting` - the connection has been instructed to disconnect and it is just about to do so
* `Disconnected` - the connection has disconnected and no attempt will be made to reconnect automatically
* `Reconnecting` - an attempt is going to be made to try and re-establish the connection
* `ReconnectingWhenNetworkBecomesReachable` - when the network becomes reachable an attempt will be made to reconnect


### Reconnection

There are three main ways in which a disconnection can occur:

  * The client explicitly calls disconnect and a close frame is sent over the websocket connection
  * The client experiences some form of network degradation which leads to a heartbeat (ping/pong) message being missed and thus the client disconnects
  * The Pusher server closes the websocket connection; typically this will only occur during a restart of the Pusher socket servers and an almost immediate reconnection should occur

In the case of the first type of disconnection the library will (as you'd hope) not attempt a reconnection.

If there is network degradation that leads to a disconnection then the library has the [Reachability](https://github.com/ashleymills/Reachability.swift) library embedded and will be able to automatically determine when to attempt a reconnect based on the changing network conditions.

If the Pusher servers close the websocket then the library will attempt to reconnect (by default) a maximum of 6 times, with an exponential backoff. The value of `reconnectAttemptsMax` is a public property on the `PusherConnection` and so can be changed if you wish.

All of this is the case if you have the client option of `autoReconnect` set as `true`, which it is by default. If the reconnection strategies are not suitable for your use case then you can set `autoReconnect` to `false` and implement your own reconnection strategy based on the connection state changes.

There are a couple of properties on the connection (`PusherConnection`) that you can set that affect how the reconnection behaviour works. These are:

* `public var reconnectAttemptsMax: Int? = 6` - if you set this to `nil` then there is no maximum number of reconnect attempts and so attempts will continue to be made with an exponential backoff (based on number of attempts), otherwise only as many attempts as this property's value will be made before the connection's state moves to `.Disconnected`
* `public var maxReconnectGapInSeconds: Double? = nil` - if you want to set a maximum length of time (in seconds) between reconnect attempts then set this property appropriately

Note that the number of reconnect attempts gets reset to 0 as soon as a successful connection is made.

## Subscribing

### Public channels

The default method for subscribing to a channel involves invoking the `subscribe` method of your client object:

```swift
let myChannel = pusher.subscribe('my-channel')
```

This returns PusherChannel object, which events can be bound to.

### Private channels

Private channels are created in exactly the same way as public channels, except that they reside in the 'private-' namespace. This means prefixing the channel name:

```swift
let myPrivateChannel = pusher.subscribe('private-my-channel')
```

### Presence channels

Presence channels are created in exactly the same way as private channels, except that they reside in the 'presence-' namespace.

```swift
let myPresenceChannel = pusher.subscribe('presence-my-channel')
```

You can also provide functions that will be called when members are either added to or removed from the channel.

```swift
let onMemberChange = { (member: PresenceChannelMember) in
    print(member)
}
let chan = pusher.subscribe("presence-channel", onMemberAdded: onMemberChange, onMemberRemoved: onMemberChange)
```

Note that both private and presence channels require the user to be authenticated in order to subscribe to the channel. This authentication can either happen inside the library, if you configured your Pusher object with your app's secret, or an authentication request is made to an authentication endpoint that you provide, again when instantiaing your Pusher object.

We recommend that you use an authentication endpoint over including your app's secret in your app in the vast majority of use cases. If you are completely certain that there's no risk to you including your app's secret in your app, for example if your app is just for internal use at your company, then it can make things easier than setting up an authentication endpoint.

## Binding to events

Events can be bound to at 2 levels; globally and per channel. When binding to an event you can choose to save the return value, which is a unique identifier for the event handler that gets created. The only reason to save this is if you're going to want to unbind from the event at a later point in time. There is an example of this below.

### Global events

You can attach behaviour to these events regardless of the channel the event is broadcast to. The following is an example of an app that binds to new comments from any channel:

```swift
let pusher = Pusher(key: "MY_KEY")
pusher.subscribe("my-channel")

pusher.bind("new-comment", callback: { (data: AnyObject?) -> Void in
    if let data = data as? [String : AnyObject] {
        if let commenter = data["commenter"] as? String, message = data["message"] as? String {
            print("\(commenter) wrote \(message)")
        }
    }
})
```

### Per-channel events

These are bound to a specific channel, and mean that you can reuse event names in different parts of your client application. The following might be an example of a stock tracking app where several channels are opened for different companies:

```swift
let pusher = Pusher(key: "MY_KEY")
let myChannel = pusher.subscribe("my-channel")

myChannel.bind("new-price", callback: { (data: AnyObject?) -> Void in
    if let data = data as? [String : AnyObject] {
        if let price = data["price"] as? String, company = data["company"] as? String {
            print("\(company) is now priced at \(price)")
        }
    }
})
```

### Receiving errors

Errors are sent to the client for which they are relevant with an event name of `pusher:error`. These can be received and handled using code as follows. Obviously the specifics of how to handle them are left up to the developer but this displays the general pattern.

```swift
pusher.bind({ (message: AnyObject?) in
    if let message = message as? [String: AnyObject], eventName = message["event"] as? String where eventName == "pusher:error" {
        if let data = message["data"] as? [String: AnyObject], errorMessage = data["message"] as? String {
            print("Error message: \(errorMessage)")
        }
    }
})
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


### Unbind event handlers

You can remove previously-bound handlers from an object by using the `unbind` function. For example,

```swift
let pusher = Pusher(key: "MY_KEY")
let myChannel = pusher.subscribe("my-channel")

let eventHandlerId = myChannel.bind("new-price", callback: { (data: AnyObject?) -> Void in
  ...
})

myChannel.unbind(eventName: "new-price", callbackId: eventHandlerId)
```

You can unbind from events at both the global and per channel level. For both objects you also have the option of calling `unbindAll`, which, as you can guess, will unbind all eventHandlers on the object.


## Presence channel specifics

Presence channels have some extra properties and functions available to them. In particular you can access the members who are subscribed to the channel by calling `members` on the channel object, as below.

```swift
let chan = pusher.subscribe("presence-channel")

print(chan.members)
```

You can also search for specific members in the channel by calling `findMember` and providing it with a user id string.

```swift
let chan = pusher.subscribe("presence-channel")
let member = chan.findMember("12345")

print(member)
```

As a special case of `findMember` you can call `me` on the channel to get the member object of the subscribed client.

```swift
let chan = pusher.subscribe("presence-channel")
let me = chan.me()

print(me)
```


## Testing

There are a set of tests for the library that can be run using the standard methods (Command-U in Xcode) when you have one the `PusherSwiftTests-*` schemes active in Xcode.

The tests also get run on [Travis-CI](https://travis-ci.org/pusher/pusher-websocket-swift). See [.travis.yml](https://github.com/pusher/pusher-websocket-swift/blob/master/.travis.yml) for details on how the Travis tests are run.


## Communication

- If you have found a bug, please open an issue.
- If you have a feature request, please open an issue.
- If you want to contribute, please submit a pull request (preferrably with some tests :) ).


## Maintainers

PusherSwift is owned and maintained by [Pusher](https://pusher.com). It was originally created by [Hamilton Chapman](https://github.com/hamchapman)

## License

PusherSwift is released under the MIT license. See [LICENSE](https://github.com/pusher/pusher-websocket-swift/blob/master/LICENSE.md) for details.
