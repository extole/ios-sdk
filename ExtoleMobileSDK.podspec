Pod::Spec.new do |s|
  s.name = 'ExtoleMobileSDK'
  s.ios.deployment_target = '13.0'
  s.platform = :ios, "13.0"
  s.version = '0.0.39'
  s.source = { :git => 'https://github.com/extole/ios-sdk.git', :tag => "#{s.version}" }
  s.authors = 'Extole'
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.homepage = 'https://github.com/extole/ios-sdk'
  s.summary = 'Extole iOS SDK'
  s.source_files = 'Sources/ExtoleMobileSDK/**/*.{swift}'
  s.dependency 'ExtoleConsumerAPI', '~> 0.0.17'
  s.dependency 'Logging', '~> 1.4'
  s.dependency 'ObjectMapper', '~> 4.1.0'
  s.dependency 'SwiftEventBus', '~> 5.0.0'
  s.swift_version = '5.0'
  s.swift_versions = ["5.0"]
end
