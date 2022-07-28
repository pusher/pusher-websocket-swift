Pod::Spec.new do |s|
  s.name             = 'PusherSwiftWithEncryption'
  s.version          = '10.1.1'
  s.summary          = 'A Pusher client library in Swift that supports encrypted channels'
  s.homepage         = 'https://github.com/pusher/pusher-websocket-swift'
  s.license          = 'MIT'
  s.author           = { "Pusher Limited" => "support@pusher.com" }
  s.source           = { git: "https://github.com/pusher/pusher-websocket-swift.git", tag: s.version.to_s }
  s.social_media_url = 'https://twitter.com/pusher'

  s.swift_version = '5.0'
  s.requires_arc  = true
  s.source_files  = ['Sources/**/*.swift']

  s.dependency 'TweetNacl', '~> 1.0.0'
  s.dependency 'NWWebSocket', '~> 0.5.2'

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.tvos.deployment_target = '13.0'
  s.watchos.deployment_target = '6.0'
end
