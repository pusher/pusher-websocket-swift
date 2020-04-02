Pod::Spec.new do |s|
  s.name             = 'PusherSwiftWithEncryption'
  s.version          = '7.2.0'
  s.summary          = 'A Pusher client library in Swift that supports encrypted channels'
  s.homepage         = 'https://github.com/pusher/pusher-websocket-swift'
  s.license          = 'MIT'
  s.author           = { "Pusher Limited" => "support@pusher.com" }
  s.source           = { git: "https://github.com/pusher/pusher-websocket-swift.git", tag: s.version.to_s }
  s.social_media_url = 'https://twitter.com/pusher'

  s.swift_version = '4.2'
  s.requires_arc  = true
  s.source_files  = ['Sources/*.swift', 'Sources/PusherSwiftWithEncryption-Only/*.swift']

  s.dependency 'ReachabilitySwift', '4.3.0'
  s.dependency 'Starscream', '~> 3.0.5'
  s.dependency 'Sodium', '~> 0.8.0'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.11'
  s.tvos.deployment_target = '9.0'
end
