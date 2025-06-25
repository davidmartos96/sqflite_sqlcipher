## 3.2.0
* Update SQLCipher version to [4.9.0](https://www.zetetic.net/blog/2025/05/15/sqlcipher-4.9.0-release-security-update/)

## 3.1.0
* Update SQLCipher version to [4.5.7](https://www.zetetic.net/blog/2024/04/24/sqlcipher-4.5.7-release/)

## 3.0.0
* Update SQLCipher version to [4.5.6](https://www.zetetic.net/blog/2024/01/17/sqlcipher-4.5.6-release/)
* Android minimum required SDK 21 and use `compileSdk` 34.
* Ensure the provided password is valid when opening the database. This now makes it possible to differentiate between failing to cipher_migrate and opening a database with the wrong password.
* On iOS/macOS, if you have sqflite as a transitive dependency with version 2.3.2 or greater, the `fmdb_override` workaround in the `dependency_overrides` is not needed anymore.
* Add iOS/MacOS privacy manifest
* Dart >= 3.3.0

## 2.2.1
* Update minimum deployment targets for iOS (11.0) and macOS (10.13) to use SQLCipher 4.5.4

## 2.2.0
* SQLCipher version 4.5.4

## 2.1.1
* SQLCipher version 4.5.0
* Update Android build version
* Update example project

## 2.1.0
* Remove references to deprecated android plugin embedding v1

## 2.0.0
* Stable version with NNBD support

## 2.0.0-nullsafety.0
* NNBD support

## 1.1.4

* Update names in ios native implementation to avoid conflicts with the `sqflite` package

## 1.1.3

* Update SQLCipher version to [4.4.2](https://www.zetetic.net/blog/2020/11/25/sqlcipher-442-release/)

## 1.1.2

* Update SQLCipher version to [4.4.1](https://www.zetetic.net/blog/2020/11/06/sqlcipher-441-release/)
* Fix Handler constructor deprecation

## 1.1.1

* Remove unnecessary logs

## 1.1.0+1

* Update SQLCipher version to [4.4.0](https://www.zetetic.net/blog/2020/05/12/sqlcipher-440-release/)

## 1.0.0+6

* Initial package release, using `sqflite_common` as a dependency under the hood.
