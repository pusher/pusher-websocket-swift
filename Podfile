source 'https://github.com/CocoaPods/Specs.git'

workspace 'PusherSwift'
project 'PusherSwift'

use_frameworks!

def import_pods
  pod 'PusherSwift', path: './'
  pod 'Starscream', '~> 1.1.3'
  pod 'CryptoSwift', '~> 0.3.1'
  pod 'ReachabilitySwift', '~> 2.3.3'
end

def import_test_pods
  import_pods
  pod 'Quick', '0.9.1'
  pod 'Nimble', '3.2.0'
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
