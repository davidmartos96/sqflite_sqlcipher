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
  # Sources live under sqflite_sqlcipher/Sources/sqflite_sqlcipher so the same tree is
  # shared with the Swift Package Manager build (see Package.swift). FMDB is only vendored
  # for SPM, so it is excluded here — CocoaPods uses the FMDB/SQLCipher pod instead.
  s.source_files     = 'sqflite_sqlcipher/Sources/sqflite_sqlcipher/**/*.{h,m}'
  s.exclude_files = 'sqflite_sqlcipher/Sources/sqflite_sqlcipher/fmdb/**/*'
  s.public_header_files = 'sqflite_sqlcipher/Sources/sqflite_sqlcipher/include/**/*.h'
  s.dependency 'FlutterMacOS'
  s.dependency 'FMDB/SQLCipher', '~> 2.7.5'
  s.dependency 'SQLCipher', '4.10.0'

  s.platform = :osx, '10.13'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'HEADER_SEARCH_PATHS' => 'SQLCipher'
  }
  s.swift_version = '5.0'
  s.resource_bundles = {'sqflite_sqlcipher_ios_privacy' => ['sqflite_sqlcipher/Sources/sqflite_sqlcipher/Resources/PrivacyInfo.xcprivacy']}
end
