import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:sqflite_sqlcipher/src/sqflite_import.dart' as impl;

import 'package:sqflite_sqlcipher_example/utils.dart';
import 'package:test/test.dart';

void main() {
  final factory = databaseFactory as impl.SqfliteDatabaseFactoryMixin;
  group('impl', () {
    if (Platform.isIOS || Platform.isAndroid) {
      group('debug_info', () {

        // test('verbose')

        test('simple', () async {
          // await devVerbose();
          var path = 'simple.db';
          await deleteDatabase(path);

          var info = await factory.getDebugInfo();
          expect(info.databases, isNull);

          var sw = Stopwatch()..start();
          var db = await openDatabase(path) as impl.SqfliteDatabaseMixin;
          expect(db.id, greaterThan(0));
          print('Sqflite opening database: ${sw.elapsed}');
          try {
            info = await factory.getDebugInfo();
            expect(info.databases!.length, 1);
            var dbInfo = info.databases!.values.first;
            expect(dbInfo.singleInstance, isTrue);
            expect(dbInfo.path, join(await factory.getDatabasesPath(), path));
            // expect(dbInfo.logLevel, isNull);

            // open again
            var previousDb = db;
            var id = db.id;
            db = await openDatabase(path) as impl.SqfliteDatabaseMixin;
            expect(db.id, id);
            expect(db, previousDb);
          } finally {
            sw = Stopwatch()..start();
            await db.close();
            print('Sqflite closing database: ${sw.elapsed}');
          }

          info = await factory.getDebugInfo();
          expect(info.databases, isNull);

          // reopen
          var id = db.id!;
          sw = Stopwatch()..start();
          var db3 = await openDatabase(path) as impl.SqfliteDatabaseMixin;
          print('Sqflite opening database: ${sw.elapsed}');
          try {
            expect(db3.id, id + 1);
          } finally {
            sw = Stopwatch()..start();
            await db3.close();
            print('Sqflite closing database: ${sw.elapsed}');

            // close again
            print('Sqflite closing again');
            await db3.close();
          }
        });
      });
    }
  });
}
