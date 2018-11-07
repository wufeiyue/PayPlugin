#
# Be sure to run `pod lib lint PayPlugin.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PayPlugin'
  s.version          = '0.1.0'
  s.summary          = '集成有支付宝,微信,银联,建行支付渠道的开源库'

  s.description      = <<-DESC
如果你使用swift编程, 此刻正在为集成各种支付SDK复杂的配置烦恼时, 试着在Podfile中执行命令 pod 'PayPlugin'并在头文件中引入它, 你会发现原来支付功能集成也可以这么轻松easy~. 所有厂商SDK共用一套支付逻辑, 仅调用一个API就能完成支付回调结果的通知. 从此生活潇潇洒洒, 来去如风~
                       DESC

  s.homepage         = 'https://github.com/wufeiyue/PayPlugin'
  
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'eppeo' => 'ieppeo@163.com' }
  s.source           = { :git => 'https://github.com/wufeiyue/PayPlugin.git', :tag => s.version.to_s }
  
  s.swift_version = '4.0'
  s.requires_arc = true
  s.platform = :ios
  s.ios.deployment_target = '8.0'
  
  s.pod_target_xcconfig = { 'OTHER_LDFLAGS' => '"-ObjC"' }
  
  s.ios.resource_bundle = { 'PayAssets' => 'PayPlugin/Assets/PayAssets.bundle/Images' }
  
  s.frameworks = 'CoreTelephony', 'CoreMotion', 'CFNetwork', 'SystemConfiguration', 'Security', 'UIKit'
  s.libraries ='z', 'c++', 'sqlite3.0'
  
  s.source_files = 'PayPlugin/Classes/*.swift'
  
  s.ios.vendored_frameworks = 'PayPlugin/Framework/*.framework'
  s.ios.vendored_libraries = 'PayPlugin/Framework/*.a'
  
  s.preserve_paths = 'PayPlugin/Framework/module.modulemap', 'PayPlugin/Framework/*.h'
  
  s.dependency 'SYWechatOpenSDK'
end
