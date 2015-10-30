source 'https://github.com/CocoaPods/Specs.git'

workspace 'PusherSwift'
xcodeproj 'PusherSwift'

use_frameworks!

target 'PusherSwift', exclusive: true do
  pod 'PusherSwift', path: './'
  pod 'Starscream', '~> 1.0.0'
  pod 'CryptoSwift', '~> 0.0.14'
  pod 'ReachabilitySwift', '~> 2.1'
  xcodeproj 'PusherSwift'
end

target 'PusherSwiftTests', exclusive: true do
  pod 'PusherSwift', path: './'
  pod 'Quick', git: 'https://github.com/Quick/Quick.git', branch: 'swift-2.0'
  pod 'Nimble', '2.0.0-rc.3'
  pod 'Starscream', '~> 1.0.0'
  pod 'CryptoSwift', '~> 0.0.14'
  pod 'ReachabilitySwift', '~> 2.1'
  xcodeproj 'PusherSwift'
end
