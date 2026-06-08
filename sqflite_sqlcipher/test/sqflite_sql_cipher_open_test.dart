import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

const channel = MethodChannel('com.davidmartos96.sqflite_sqlcipher');

class MockMethodCall {
  String? expectedMethod;
  dynamic expectedArguments;
  dynamic response;

  @override
  String toString() => '$expectedMethod $expectedArguments $response';
}

class MockScenario {
  MockScenario(List<List> data) {
    methodsCalls = data
        .map((list) => MockMethodCall()
          ..expectedMethod = list[0]?.toString()
          ..expectedArguments = list[1]
          ..response = list[2])
        .toList(growable: false);
  }

  late List<MockMethodCall> methodsCalls;
  var index = 0;
  dynamic exception;

  void end() {
    expect(exception, isNull, reason: '$exception');
    expect(index, methodsCalls.length);
  }
}

MockScenario startScenario(List<List> data) {
  final scenario = MockScenario(data);

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel,
      (MethodCall methodCall) async {
    final index = scenario.index++;
    // devPrint('$index ${scenario.methodsCalls[index]}');
    final item = scenario.methodsCalls[index];
    try {
      expect(methodCall.method, item.expectedMethod);
      expect(methodCall.arguments, item.expectedArguments);
    } catch (e) {
      scenario.exception ??= '$e $index';
    }
    return item.response;
  });
  return scenario;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sqflite_sql_cipher', () {
    test('open no password', () async {
      final scenario = startScenario([
        [
          'openDatabase',
          {'path': ':memory:', 'singleInstance': true},
          1
        ],
        [
          'closeDatabase',
          {'id': 1},
          null
        ],
      ]);
      final db = await openDatabase(inMemoryDatabasePath);
      await db.close();
      scenario.end();
    });
    test('open with version and password', () async {
      final scenario = startScenario([
        [
          'openDatabase',
          {'path': ':memory:', 'singleInstance': true, 'password': 'my_password'},
          1
        ],
        [
          'query',
          {'sql': 'PRAGMA user_version', 'arguments': null, 'id': 1},
          {}
        ],
        [
          'execute',
          {'sql': 'BEGIN EXCLUSIVE', 'arguments': null, 'id': 1, 'inTransaction': true},
          null
        ],
        [
          'query',
          {'sql': 'PRAGMA user_version', 'arguments': null, 'id': 1},
          {}
        ],
        [
          'execute',
          {'sql': 'PRAGMA user_version = 1', 'arguments': null, 'id': 1},
          null
        ],
        [
          'execute',
          {'sql': 'COMMIT', 'arguments': null, 'id': 1, 'inTransaction': false},
          null
        ],
        [
          'closeDatabase',
          {'id': 1},
          null
        ],
      ]);
      final db =
          await openDatabase(inMemoryDatabasePath, password: 'my_password', version: 1, onCreate: (db, version) {});
      await db.close();
      scenario.end();
    });
  });
}
