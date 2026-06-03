import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// delete the db, create the folder and returnes its path
Future<String> initDeleteDb(String dbName) async {
  final databasePath = await getDatabasesPath();
  // print(databasePath);
  final path = join(databasePath, dbName);

  if (await File(path).exists()) {
    await deleteDatabase(path);
  }

  final parent = Directory(dirname(path));

  // make sure the folder exists
  if (!(await parent.exists())) {
    await parent.create(recursive: true);
  }
  return path;
}
