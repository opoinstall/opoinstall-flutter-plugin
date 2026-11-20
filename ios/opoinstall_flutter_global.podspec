#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'opoinstall_flutter_global'
  s.version          = '1.0.0'
  s.summary          = 'opoinstall official Flutter plugin.'
  s.description      = <<-DESC
opoinstall_flutter_global 封装 opoinstall 原生 SDK，提供渠道统计、携带参数安装、快速安装与一键拉起能力。
                       DESC
  s.homepage         = 'https://www.opoinstall.com/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'opoinstall' => 'developer@opoinstall.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.vendored_frameworks = 'OpoInstallSDK.xcframework'
  s.resource_bundles = {
    'opoinstall_flutter_global_privacy' => ['PrivacyInfo.xcprivacy']
  }
  s.frameworks = 'UIKit', 'Foundation', 'Security', 'SystemConfiguration'
  s.static_framework = true

  s.ios.deployment_target = '9.0'
end
