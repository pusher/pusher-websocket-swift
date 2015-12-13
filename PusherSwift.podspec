Pod::Spec.new do |s|
  s.name             = 'PusherSwift'
  s.version          = '0.1.6'
  s.summary          = 'A Pusher client library in Swift'
  s.homepage         = 'https://github.com/pusher-community/pusher-websocket-swift'
  s.license          = 'MIT'
  s.author           = { "Hamilton Chapman" => "hamchapman@gmail.com" }
  s.source           = { git: "https://github.com/pusher/pusher-websocket-swift.git", tag: s.version.to_s }
  s.social_media_url = 'https://twitter.com/pusher'

  s.requires_arc = true
  s.source_files = 'Sources/*.swift'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'

  s.dependency 'Starscream', '~> 1.0.2'
  s.dependency 'CryptoSwift', '~> 0.1.1'
  s.dependency 'ReachabilitySwift', '~> 2.3'
end
