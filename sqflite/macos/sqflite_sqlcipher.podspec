#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'sqflite_sqlcipher'
  s.version          = '0.0.1'
  s.summary          = 'SQLite plugin with SqlCipher support.'
  s.description      = <<-DESC
Access SQLite database.
                       DESC
  s.homepage         = 'https://github.com/davidmartos96/sqflite_sqlcipher'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'David' => 'davidmartos96@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'FlutterMacOS'
  s.dependency 'FMDB/SQLCipher', '~> 2.7.5'
  s.dependency 'SQLCipher', '4.10.0'

  s.platform = :osx, '10.13'
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES',
    'HEADER_SEARCH_PATHS' => 'SQLCipher'
  }
  s.swift_version = '5.0'
  s.resource_bundles = {'sqflite_sqlcipher_ios_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
