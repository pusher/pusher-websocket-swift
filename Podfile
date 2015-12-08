source 'https://github.com/CocoaPods/Specs.git'

workspace 'PusherSwift'
xcodeproj 'PusherSwift'

use_frameworks!

target 'PusherSwift', exclusive: true do
  pod 'PusherSwift', path: './'
  pod 'Starscream', '~> 1.0.2'
  pod 'CryptoSwift', '~> 0.1.1'
  pod 'ReachabilitySwift', '~> 2.3'
  xcodeproj 'PusherSwift'
end

target 'PusherSwiftTests', exclusive: true do
  pod 'PusherSwift', path: './'
  pod 'Quick', '0.8.0'
  pod 'Nimble', '3.0.0'
  pod 'Starscream', '~> 1.0.2'
  pod 'CryptoSwift', '~> 0.1.1'
  pod 'ReachabilitySwift', '~> 2.3'
  xcodeproj 'PusherSwift'
end
