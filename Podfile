source 'https://github.com/CocoaPods/Specs.git'

workspace 'PusherSwift'

use_frameworks!

def import_pods
  pod 'PusherSwift', path: './'
end

def import_test_pods
  import_pods
  pod 'Quick', '0.9.1'
  pod 'Nimble', '3.2.0'
end

target 'PusherSwift-iOS' do
  project 'PusherSwift'
  platform :ios, '9.0'
  import_pods
end

target 'PusherSwift-tvOS' do
  project 'PusherSwift'
  platform :tvos, '9.0'
  import_pods
end

target 'PusherSwift-OSX' do
  project 'PusherSwift'
  platform :osx, '10.11'
  import_pods
end

target 'PusherSwiftTests-iOS' do
  project 'PusherSwift'
  platform :ios, '9.0'
  import_test_pods
end

target 'PusherSwiftTests-tvOS' do
  project 'PusherSwift'
  platform :tvos, '9.0'
  import_test_pods
end

target 'PusherSwiftTests-OSX' do
  project 'PusherSwift'
  platform :osx, '10.11'
  import_test_pods
end

target 'iOS Example' do
  project 'iOS Example'
  platform :ios, '9.0'
  import_pods
end