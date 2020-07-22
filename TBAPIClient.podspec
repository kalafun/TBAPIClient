#
# Be sure to run `pod lib lint TBAPIClient.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TBAPIClient'
  s.version          = '0.1.1'
  s.summary          = 'Lightweight API Client'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
"A lightweight API Client that leverages the use of Swift's Decodable and automatically returns objects in predefined types."
                       DESC

  s.homepage         = 'https://github.com/kalafun/TBAPIClient'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Tomáš Bobko' => 'kalafun@gmail.com' }
  s.source           = { :git => 'https://github.com/kalafun/TBAPIClient.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'TBAPIClient/Classes/*'

  s.swift_versions = '5'
  
  # s.resource_bundles = {
  #   'TBAPIClient' => ['TBAPIClient/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
