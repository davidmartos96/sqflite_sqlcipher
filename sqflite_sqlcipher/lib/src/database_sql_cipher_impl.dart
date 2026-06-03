import 'package:sqflite_sqlcipher/src/sqflite_import.dart';
import 'package:sqflite_sqlcipher/src/sql_cipher_constant.dart';
import 'package:sqflite_sqlcipher/src/sql_cipher_open_options.dart';

/// Sql Cipher database impl.
class SqfileSqlCipherDatabaseImpl extends SqfliteDatabaseBase {
  /// Sql Cipher database ctor.
  SqfileSqlCipherDatabaseImpl(super.openHelper, super.path);

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) =>
      method == methodOpenDatabase
          ? _invokeOpenDatabaseMethod(method, arguments)
          : factory.invokeMethod(method, arguments);

  Future<T> _invokeOpenDatabaseMethod<T>(String method, [dynamic arguments]) {
    // Inject password parameter if needed
    final options = this.options;
    if (options is SqfliteSqlCipherOpenDatabaseOptions) {
      if (options.password != null) {
        (arguments as Map)[paramPassword] = options.password;
      }
    }
    return factory.invokeMethod(method, arguments);
  }
}
