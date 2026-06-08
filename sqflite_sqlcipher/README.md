# sqflite_sqlcipher

[![pub package](https://img.shields.io/pub/v/sqflite_sqlcipher.svg)](https://pub.dev/packages/sqflite_sqlcipher)

This is a fork from the plugin [sqflite](https://github.com/tekartik/sqflite).

 **[sqflite_common version 1.0.0](https://pub.dev/packages/sqflite_common)**

This fork makes use of the Dart package `sqflite_common` but with a native implementation which uses the SqlCipher library on both iOS and Android. The API is the same as the `sqflite` plugin, only that the `openDatabase` method includes an optional parameter `password`. 

The SQLCipher version of the plugin is 4.x If you try to open a database encrypted with a lower version of SQLCipher, the plugin will try to migrate it to a new version using the operation `PRAGMA cipher_migrate` (This automatic migration to version 4 is only done in Android. PR welcome for this feature in iOS).

### Install and use

To add it in your project include this in the `pubspec.yml`.
```
dependencies:
  sqflite_sqlcipher: {latest version}
```

```dart
import 'package:sqflite_sqlcipher/sqflite.dart';

Database db = await openDatabase(
  path,
  password: "my password",
  // onCreate, onUpgrade...
);
```

### Android
**REQUIRED:** Flutter now enables code shrinking by default when building an APK in release mode, so you need to add the following ProGuard rules to the file `android/app/proguard-rules.pro`. If it does not exist, create it:

```
-keep class net.sqlcipher.** { *; }
```

### If using `sqflite` version < 2.3.2 as direct or transitive dependency

If you use sqflite v2.3.2 or greater you can ignore this, because it doesn't use the `FMDB` pod anymore.

If any of your project's dependencies uses sqflite (e.g: cached_network_image, flutter_cache_manager...), then for iOS to link correctly the SQLCipher libraries you need to override it in your `pubspec.yaml` file:

```yaml
dependency_overrides:
  sqflite:
    git:
      url: https://www.github.com/davidmartos96/sqflite_sqlcipher.git
      path: sqflite
      ref: fmdb_override
```

The reason for this is that in iOS, the `FMDB` and `FMDB/SQLCipher` pods cannot be used at the same time. The override only changes that reference. The rest is the full `sqflite` package. 
If anyone knows about a better way to handle this, PRs are welcome :D


---

## Sqflite documentation

* [Documentation](https://github.com/tekartik/sqflite/blob/master/sqflite/README.md)
