# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'
# Uncomment this line if you're using Swift
# use_frameworks!

target 'Points' do
  use_frameworks!
  platform :ios, '9.2'
  #pod 'LzmaSDK-ObjC', '2.0.8'
  #pod 'MPMessagePack', '1.3.5'
  #pod 'YSMessagePack', '1.6.0'
  #pod 'YSMessagePack', :git => 'https://github.com/tempire/YSMessagePack'
  #pod 'RealmSwift', '1.0.2'
  #pod 'TSMessages', '0.9.12'
  pod 'MessageBarManager'
  #pod 'BTree', '2.1.0'
  pod 'M13ProgressSuite', '1.2.7'
  pod 'ChameleonFramework', '2.1.0'
  #pod 'ITDAvatarPlaceholder', '0.1.0'
  pod 'Reveal-iOS-SDK', '1.6.2'
  pod 'MGSwipeTableCell', '1.5.5'
  pod 'Spotify-iOS-SDK', '0.17.0'
  pod 'Realm', :git => 'https://github.com/realm/realm-cocoa.git', :submodules => true
  pod 'RealmSwift', :git => 'https://github.com/realm/realm-cocoa.git', :submodules => true
end

target 'cli' do
  use_frameworks!
  platform :osx, '10.11'
  #pod 'YSMessagePack', '1.6.0'
  #pod 'YSMessagePack', :git => 'https://github.com/tempire/YSMessagePack'
end

# Remove code signing for all pods

require 'pp'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
      config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
      config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end

