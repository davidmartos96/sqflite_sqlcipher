import 'dart:async';

import 'package:sqflite_common/utils/utils.dart' as utils;
import 'package:sqflite_sqlcipher/sqlite_api.dart';
import 'package:sqflite_sqlcipher/src/factory_sql_cipher_impl.dart'
    show databaseFactory;
import 'package:sqflite_sqlcipher/src/sqflite_import.dart' as impl;
import 'package:sqflite_sqlcipher/src/sqflite_import.dart';
import 'package:sqflite_sqlcipher/src/sqflite_sql_cipher_impl.dart';

export 'package:sqflite_sqlcipher/src/factory_sql_cipher_impl.dart'
    show databaseFactory;

export 'sqlite_api.dart';

///
/// sqflite plugin
///
class Sqflite {
  //static MethodChannel get _channel => channel;

  /// deprecated
  @Deprecated('internal use only')
  static Future<String?> get platformVersion =>
      invokeMethod<String>(methodGetPlatformVersion);

  /// Turns on debug mode if you want to see the SQL query
  /// executed natively.
  static Future<void> setDebugModeOn([bool on = true]) async {
    await invokeMethod<dynamic>(methodSetDebugModeOn, on);
  }

  /// Planned Deprecated for 1.1.7
  static Future<bool> getDebugModeOn() async {
    return impl.debugModeOn;
  }

  /// deprecated on purpose to remove from code.
  ///
  /// To use during developpment/debugging
  /// Set extra dart and nativate debug logs
  @Deprecated('Debug only')
  static Future<void> devSetDebugModeOn([bool on = true]) {
    impl.debugModeOn = on;
    return setDebugModeOn(on);
  }


  /// Testing only
  @Deprecated('Testing only')
  static Future<void> devInvokeMethod(String method,
      [dynamic arguments]) async {
    await invokeMethod<dynamic>(method, arguments);
  }

  /// helper to get the first int value in a query
  /// Useful for COUNT(*) queries
  static int? firstIntValue(List<Map<String, dynamic>> list) =>
      utils.firstIntValue(list);

  /// Utility to encode a blob to allow blow query using
  /// 'hex(blob_field) = ?', Sqlite.hex([1,2,3])
  static String hex(List<int> bytes) => utils.hex(bytes);

  /// Sqlite has a dead lock warning feature that will print some text
  /// after 10s, you can override the default behavior
  static void setLockWarningInfo(
      {Duration? duration, void Function()? callback}) {
    utils.setLockWarningInfo(duration: duration, callback: callback);
  }
}

///
/// Open the database at a given path
///
/// [version] (optional) specifies the schema version of the database being
/// opened. This is used to decide whether to call [onCreate], [onUpgrade],
/// and [onDowngrade]
///
/// The optional callbacks are called in the following order:
///
/// 1. [onConfigure]
/// 2. [onCreate] or [onUpgrade] or [onDowngrade]
/// 5. [onOpen]
///
/// [onConfigure] is the first callback invoked when opening the database. It
/// allows you to perform database initialization such as enabling foreign keys
/// or write-ahead logging
///
/// If [version] is specified, [onCreate], [onUpgrade], and [onDowngrade] can
/// be called. These functions are mutually exclusive — only one of them can be
/// called depending on the context, although they can all be specified to
/// cover multiple scenarios
///
/// [onCreate] is called if the database did not exist prior to calling
/// [openDatabase]. You can use the opportunity to create the required tables
/// in the database according to your schema
///
/// [onUpgrade] is called if either of the following conditions are met:
///
/// 1. [onCreate] is not specified
/// 2. The database already exists and [version] is higher than the last
/// database version
///
/// In the first case where [onCreate] is not specified, [onUpgrade] is called
/// with its [oldVersion] parameter as `0`. In the second case, you can perform
/// the necessary migration procedures to handle the differing schema
///
/// [onDowngrade] is called only when [version] is lower than the last database
/// version. This is a rare case and should only come up if a newer version of
/// your code has created a database that is then interacted with by an older
/// version of your code. You should try to avoid this scenario
///
/// [onOpen] is the last optional callback to be invoked. It is called after
/// the database version has been set and before [openDatabase] returns
///
/// When [readOnly] (false by default) is true, all other parameters are
/// ignored and the database is opened as-is
///
/// When [singleInstance] is true (the default), a single database instance is
/// returned for a given path. Subsequent calls to [openDatabase] with the
/// same path will return the same instance, and will discard all other
/// parameters such as callbacks for that invocation.
///
Future<Database> openDatabase(String path,
    {int? version,
    OnDatabaseConfigureFn? onConfigure,
    OnDatabaseCreateFn? onCreate,
    OnDatabaseVersionChangeFn? onUpgrade,
    OnDatabaseVersionChangeFn? onDowngrade,
    OnDatabaseOpenFn? onOpen,
    String? password,
    bool readOnly = false,
    bool singleInstance = true}) {
  final options = SqlCipherOpenDatabaseOptions(
      version: version,
      onConfigure: onConfigure,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
      onDowngrade: onDowngrade,
      onOpen: onOpen,
      password: password,
      readOnly: readOnly,
      singleInstance: singleInstance);
  return databaseFactory.openDatabase(path, options: options);
}

///
/// Open the database at a given path in read only mode
///
Future<Database> openReadOnlyDatabase(String path, {String? password}) =>
    openDatabase(path, readOnly: true, password: password);

///
/// Get the default databases location.
///
/// On Android, it is typically `data/data/<package_name>/databases`
///
/// On iOS, it is the Documents directory
///
Future<String> getDatabasesPath() => databaseFactory.getDatabasesPath();

///
/// Delete the database at the given path.
///
Future<void> deleteDatabase(String path) =>
    databaseFactory.deleteDatabase(path);

///
/// Check if a database exists at a given path.
///
Future<bool> databaseExists(String path) =>
    databaseFactory.databaseExists(path);
