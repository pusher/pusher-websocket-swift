source 'https://github.com/CocoaPods/Specs.git'

workspace 'PusherSwift'
xcodeproj 'PusherSwift'

use_frameworks!

target 'PusherSwift', exclusive: true do
  pod 'PusherSwift', path: './'
  pod 'Starscream'
  pod 'CryptoSwift'
  pod 'ReachabilitySwift'
  xcodeproj 'PusherSwift'
end

target 'PusherSwiftTests', exclusive: true do
  pod 'PusherSwift', path: './'
  pod 'Quick', '~> 0.3.0'
  pod 'Nimble'
  pod 'Starscream'
  pod 'CryptoSwift'
  pod 'ReachabilitySwift'
  xcodeproj 'PusherSwift'
end