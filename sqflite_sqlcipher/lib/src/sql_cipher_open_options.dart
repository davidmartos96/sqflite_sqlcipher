import 'package:sqflite_sqlcipher/sqlite_api.dart';

///
/// Options to open a database
/// See [openDatabase] for details
///
class SqfliteSqlCipherOpenDatabaseOptions
    implements SqlCipherOpenDatabaseOptions {
  /// See [openDatabase] for details
  SqfliteSqlCipherOpenDatabaseOptions({
    this.version,
    this.onConfigure,
    this.onCreate,
    this.onUpgrade,
    this.onDowngrade,
    this.onOpen,
    this.password,
    this.readOnly = false,
    this.singleInstance = true,
  });
  
  @override
  int? version;
  @override
  OnDatabaseConfigureFn? onConfigure;
  @override
  OnDatabaseCreateFn? onCreate;
  @override
  OnDatabaseVersionChangeFn? onUpgrade;
  @override
  OnDatabaseVersionChangeFn? onDowngrade;
  @override
  OnDatabaseOpenFn? onOpen;
  @override
  String? password;
  @override
  bool readOnly;
  @override
  bool singleInstance;

  @override
  String toString() {
    final map = <String, dynamic>{};
    if (version != null) {
      map['version'] = version;
    }
    map['readOnly'] = readOnly;
    map['singleInstance'] = singleInstance;
    return map.toString();
  }
}
