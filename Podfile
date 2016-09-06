source 'https://github.com/CocoaPods/Specs.git'

workspace 'PusherSwift'

use_frameworks!

def import_test_pods
  pod 'Quick', '0.9.3'
  pod 'Nimble', '4.1.0'
end

target 'PusherSwiftTests-iOS' do
  project 'PusherSwift/PusherSwift'
  platform :ios, '9.0'
  import_test_pods
end

target 'PusherSwiftTests-tvOS' do
  project 'PusherSwift/PusherSwift'
  platform :tvos, '9.0'
  import_test_pods
end

target 'PusherSwiftTests-OSX' do
  project 'PusherSwift/PusherSwift'
  platform :osx, '10.11'
  import_test_pods
end
