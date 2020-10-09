Pod::Spec.new do |s|
  s.name             = 'PusherSwift'
  s.version          = '8.0.0'
  s.summary          = 'A Pusher client library in Swift'
  s.homepage         = 'https://github.com/pusher/pusher-websocket-swift'
  s.license          = 'MIT'
  s.author           = { "Pusher Limited" => "support@pusher.com" }
  s.source           = { git: "https://github.com/pusher/pusher-websocket-swift.git", tag: s.version.to_s }
  s.social_media_url = 'https://twitter.com/pusher'

  s.swift_version = '5.0'
  s.requires_arc  = true
  s.source_files  = ['Sources/**/*.swift']
  s.exclude_files = ['Sources/PusherSwiftWithEncryption-Only/**/*.swift']

  s.dependency 'ReachabilitySwift', '~> 5.0'

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.tvos.deployment_target = '13.0'
end
