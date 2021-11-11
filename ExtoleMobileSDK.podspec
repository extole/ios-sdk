Pod::Spec.new do |s|
  s.name = 'ExtoleMobileSDK'
  s.ios.deployment_target = '12.0'
  s.platform = :ios, "12.0"
  s.version = '0.0.2'
  s.source = { :git => 'https://github.com/extole/ios.git', :tag => "#{s.version}" }
  s.authors = 'Extole'
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.homepage = 'https://www.extole.com'
  s.summary = 'Extole iOS SDK'
  s.source_files = 'Sources/ExtoleMobileSDK/**/*.{swift}'
  s.dependency 'ExtoleClientAPI', '~> 0.0.1'
  s.dependency 'ExtoleConsumerAPI', '~> 0.0.1'
  s.swift_version = '5.0'
end
