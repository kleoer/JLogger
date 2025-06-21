Pod::Spec.new do |s|
  s.name             = 'JLogger'
  s.version          = '1.0.0'
  s.summary          = '一个轻量级的iOS/macOS日志记录框架'
  s.description      = <<-DESC
                      JLogger是一个简单易用的日志记录框架,提供了灵活的日志级别控制和输出格式化功能。
                      主要特性:
                      * 支持多个日志级别
                      * 自定义日志格式
                      * 文件输出支持
                      * 线程安全
                      DESC
  
  s.homepage         = 'https://github.com/kleoer/JLogger'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'kleoer' => 'kleoer@example.com' }
  s.source           = { :git => 'https://github.com/kleoer/JLogger.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '14.0'
  s.osx.deployment_target = '10.14'
  s.swift_version = '5.0'
  
  s.source_files = 'Sources/**/*'
  
  s.frameworks = 'SwiftUI', 'Foundation'
end 