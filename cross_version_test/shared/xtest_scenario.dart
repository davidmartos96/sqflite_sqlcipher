// CANONICAL cross-version SQLCipher compatibility scenario.
//
// This single file is copied verbatim into both test apps
// (app_v340/integration_test/ and app_v400/integration_test/). It compiles
// unchanged against either package version because both expose the same
// `package:sqflite_sqlcipher/sqflite.dart` API.
//
// Behaviour is selected entirely by --dart-define flags so the orchestrator
// scripts can drive create/verify phases without editing source:
//
//   MODE       create | verify        (what to do)
//   DB_DIR     directory holding the db file (empty => getDatabasesPath())
//   DB_NAME    db file name, e.g. db_a.db
//   CREATOR    free-text label recorded in the `metadata` table on create
//   PASSWORD   SQLCipher key (defaults to a fixed shared key)
//
// The dataset below is the single source of truth: `create` inserts exactly
// it, and `verify` asserts the opened database matches it byte-for-byte,
// including INTEGER/REAL/TEXT/BLOB/NULL types and a unicode string.

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart'; // also re-exports Uint8List
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';

// ---------------------------------------------------------------------------
// Configuration (from --dart-define)
// ---------------------------------------------------------------------------
const String kMode = String.fromEnvironment('MODE', defaultValue: 'verify');
const String kDbDir = String.fromEnvironment('DB_DIR', defaultValue: '');
const String kDbName = String.fromEnvironment('DB_NAME', defaultValue: 'xtest.db');
const String kCreator = String.fromEnvironment('CREATOR', defaultValue: 'unknown');
const String kPassword =
    String.fromEnvironment('PASSWORD', defaultValue: 'Cr0ss-V3rsion!SQLCipher_Key');
// iOS only: the app sandbox is destroyed when `flutter test` finishes, so the
// db file can neither be copied out afterward nor injected before a verify run.
// Instead, create exports the db as base64 over stdout (EXPORT_B64=1) and verify
// stages the db from a bundled asset (INPUT_ASSET=assets/incoming.db). On macOS
// these are unset and the db is shared directly via DB_DIR.
const String kExportB64 = String.fromEnvironment('EXPORT_B64', defaultValue: '');
const String kInputAsset = String.fromEnvironment('INPUT_ASSET', defaultValue: '');

// ---------------------------------------------------------------------------
// The dataset — shared by create and verify.
// ---------------------------------------------------------------------------
final Uint8List _avatar1 = Uint8List.fromList([1, 2, 3, 4, 255, 0, 128]);
final Uint8List _avatar2 = Uint8List.fromList([10, 20, 30]);

/// users: exercises INTEGER, TEXT, REAL, BLOB and NULL (age, avatar, bio).
final List<Map<String, Object?>> usersData = [
  {
    'id': 1,
    'name': 'Ada Lovelace',
    'age': 36,
    'height': 165.5,
    'active': 1,
    'avatar': _avatar1,
    'bio': 'First programmer',
  },
  {
    'id': 2,
    'name': 'Alan Turing',
    'age': 41,
    'height': 178.25,
    'active': 1,
    'avatar': _avatar2,
    'bio': null, // NULL text
  },
  {
    'id': 3,
    'name': 'Grace Hopper',
    'age': null, // NULL integer
    'height': 170.0,
    'active': 0,
    'avatar': null, // NULL blob
    'bio': 'Compiler pioneer',
  },
];

/// notes: exercises a foreign-key-style relation and a unicode string.
final List<Map<String, Object?>> notesData = [
  {'id': 1, 'user_id': 1, 'title': 'Note A', 'body': 'unicode: café ☕ 数据 🔐', 'created_at': 1700000000},
  {'id': 2, 'user_id': 1, 'title': 'Note B', 'body': 'second note', 'created_at': 1700000100},
  {'id': 3, 'user_id': 2, 'title': 'Note C', 'body': 'turing note', 'created_at': 1700000200},
];

/// metadata: simple key/value, plus provenance written by the creator.
List<Map<String, Object?>> metadataData(String creator) => [
      {'key': 'schema_version', 'value': '1'},
      {'key': 'app', 'value': 'sqflite_sqlcipher_xtest'},
      {'key': 'creator', 'value': creator},
    ];

const String createUsers = '''
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  age INTEGER,
  height REAL,
  active INTEGER NOT NULL,
  avatar BLOB,
  bio TEXT
)''';

const String createNotes = '''
CREATE TABLE notes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  created_at INTEGER NOT NULL
)''';

const String createMetadata = '''
CREATE TABLE metadata (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)''';

/// On macOS we pass DB_DIR (a shared /tmp dir, sandbox disabled). On iOS the
/// app is sandboxed, so DB_DIR is left empty and we fall back to the per-app
/// `getDatabasesPath()`; the db is then moved between apps via base64 export
/// (EXPORT_B64) and asset injection (INPUT_ASSET) — see run_ios.sh.
Future<String> _dbPath() async {
  final dir = kDbDir.isNotEmpty ? kDbDir : await getDatabasesPath();
  return p.join(dir, kDbName);
}

void _log(String msg) {
  // Prefixed so the orchestrator can grep it out of `flutter test` output.
  debugPrint('XTEST $msg');
}

Future<void> _create() async {
  final path = await _dbPath();
  _log('MODE=create path=$path creator=$kCreator');

  // Fresh start.
  final dir = Directory(p.dirname(path));
  if (!dir.existsSync()) dir.createSync(recursive: true);
  if (File(path).existsSync()) File(path).deleteSync();

  final db = await openDatabase(
    path,
    password: kPassword,
    version: 1,
    onCreate: (db, version) async {
      final batch = db.batch();
      batch.execute(createUsers);
      batch.execute(createNotes);
      batch.execute(createMetadata);
      await batch.commit();
    },
  );

  try {
    for (final u in usersData) {
      await db.insert('users', u);
    }
    for (final n in notesData) {
      await db.insert('notes', n);
    }
    for (final m in metadataData(kCreator)) {
      await db.insert('metadata', m);
    }
  } finally {
    await db.close();
  }

  // Prove the file is genuinely encrypted: a plaintext SQLite db starts with
  // the magic header "SQLite format 3\0".
  final header = await File(path).openRead(0, 16).fold<List<int>>(
        <int>[],
        (acc, chunk) => acc..addAll(chunk),
      );
  final headerStr = String.fromCharCodes(header.takeWhile((b) => b != 0));
  expect(headerStr.startsWith('SQLite format 3'), isFalse,
      reason: 'File header looks like PLAINTEXT SQLite — encryption failed!');
  _log('created OK, encrypted header confirmed (not plaintext)');

  if (kExportB64 == '1') {
    await _exportBase64(path);
  }
}

/// Dumps the db file as chunked base64 to stdout between markers so the iOS
/// orchestrator can reconstruct it after the sandbox is gone.
Future<void> _exportBase64(String path) async {
  final b64 = base64.encode(await File(path).readAsBytes());
  const chunk = 1000;
  print('XTEST_B64_BEGIN len=${b64.length}');
  for (var i = 0; i < b64.length; i += chunk) {
    final end = (i + chunk < b64.length) ? i + chunk : b64.length;
    print('XTEST_B64:${b64.substring(i, end)}');
  }
  print('XTEST_B64_END');
}

void _expectRowEquals(
    Map<String, Object?> actual, Map<String, Object?> expected, String where) {
  for (final entry in expected.entries) {
    final a = actual[entry.key];
    final e = entry.value;
    if (e is Uint8List || a is List<int>) {
      final ab = a == null ? null : Uint8List.fromList((a as List).cast<int>());
      expect(ab, e == null ? isNull : (e as Uint8List),
          reason: '$where blob column "${entry.key}"');
    } else {
      expect(a, e, reason: '$where column "${entry.key}"');
    }
  }
}

Future<void> _verify() async {
  final path = await _dbPath();
  _log('MODE=verify path=$path');

  // iOS: stage the database to verify from a bundled asset into the sandbox.
  if (kInputAsset.isNotEmpty) {
    _log('staging input asset "$kInputAsset" -> $path');
    final data = await rootBundle.load(kInputAsset);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final dir = Directory(p.dirname(path));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    await File(path).writeAsBytes(bytes, flush: true);
  }

  expect(File(path).existsSync(), isTrue,
      reason: 'Database to verify does not exist at $path');

  // 1) Correct key opens and the contents match the canonical dataset.
  //
  // NOTE: every open here uses singleInstance:false. sqflite caches open
  // databases by PATH ONLY (the password is ignored for cache lookups), so a
  // leaked wrong-key handle would otherwise be handed back to a later correct-key
  // open of the same path and every read would fail. singleInstance:false keeps
  // each open fully independent — which is also what we want when emulating "a
  // different app opens this file".
  final db = await openDatabase(path, password: kPassword, singleInstance: false);
  try {
    final tables = (await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name <> 'android_metadata'"))
        .map((r) => r['name'] as String)
        .toSet();
    expect(tables.containsAll({'users', 'notes', 'metadata'}), isTrue,
        reason: 'Missing tables, found: $tables');

    final users = await db.query('users', orderBy: 'id');
    expect(users.length, usersData.length, reason: 'users row count');
    for (var i = 0; i < usersData.length; i++) {
      _expectRowEquals(users[i], usersData[i], 'users[$i]');
    }

    final notes = await db.query('notes', orderBy: 'id');
    expect(notes.length, notesData.length, reason: 'notes row count');
    for (var i = 0; i < notesData.length; i++) {
      _expectRowEquals(notes[i], notesData[i], 'notes[$i]');
    }

    final meta = {
      for (final r in await db.query('metadata'))
        r['key'] as String: r['value'] as String
    };
    expect(meta['schema_version'], '1');
    expect(meta['app'], 'sqflite_sqlcipher_xtest');
    expect(meta['creator'], isNotNull);
    _log('verified OK — database was created by: ${meta['creator']}');
  } finally {
    await db.close();
  }

  // 2) Wrong key must be rejected (proves the key is actually required and the
  //    file is genuinely encrypted). Isolated with singleInstance:false and
  //    always closed so it can neither be served from nor pollute the cache.
  var wrongKeyRejected = false;
  Database? bad;
  try {
    bad = await openDatabase(path,
        password: 'definitely-the-wrong-key', singleInstance: false);
    await bad.rawQuery('SELECT count(*) FROM users');
  } catch (_) {
    wrongKeyRejected = true;
  } finally {
    try {
      await bad?.close();
    } catch (_) {/* opening with the wrong key may leave it unusable */}
  }
  expect(wrongKeyRejected, isTrue,
      reason: 'Database opened/queried with the WRONG key — not encrypted?');
  _log('wrong-key correctly rejected');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cross-version SQLCipher scenario (MODE=$kMode)', (tester) async {
    _log('=== begin MODE=$kMode db=$kDbName ===');
    if (kMode == 'create') {
      await _create();
    } else if (kMode == 'verify') {
      await _verify();
    } else {
      fail('Unknown MODE="$kMode" (expected create|verify)');
    }
    _log('=== PASS MODE=$kMode db=$kDbName ===');
  });
}
