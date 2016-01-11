source 'https://github.com/CocoaPods/Specs.git'

workspace 'PusherSwift'
xcodeproj 'PusherSwift'

use_frameworks!

def import_pods
  pod 'PusherSwift', path: './'
  pod 'Starscream', '~> 1.0.2'
  pod 'CryptoSwift', '~> 0.2.2'
  pod 'ReachabilitySwift', '~> 2.3.3'
end

def import_test_pods
  import_pods
  pod 'Quick', '0.8.0'
  pod 'Nimble', '3.0.0'
end

target 'PusherSwift-iOS' do
  platform :ios, '9.0'
  import_pods
end

target 'PusherSwift-tvOS' do
  platform :tvos, '9.0'
  import_pods
end

target 'PusherSwift-OSX' do
  platform :osx, '10.11'
  import_pods
end

target 'PusherSwiftTests-iOS' do
  platform :ios, '9.0'
  import_test_pods
end

target 'PusherSwiftTests-tvOS' do
  platform :tvos, '9.0'
  import_test_pods
end

target 'PusherSwiftTests-OSX' do
  platform :osx, '10.11'
  import_test_pods
end
