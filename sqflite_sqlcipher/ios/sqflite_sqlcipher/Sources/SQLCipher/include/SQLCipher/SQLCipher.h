//
//  SQLCipher.h
//  sqflite_sqlcipher
//
//  Umbrella header for the source-built SQLCipher static C target.
//
//  Historically the Swift Package Manager build pulled SQLCipher from the
//  prebuilt SQLCipher.swift dynamic xcframework, whose module exposed an
//  `<SQLCipher/SQLCipher.h>` umbrella. We now compile the SQLCipher
//  amalgamation from source into a static C target instead, so that the
//  sqlite3_* symbols are *defined* in the app binary and can never be
//  shadowed by the system libsqlite3.dylib. This shim keeps the existing
//  `#import <SQLCipher/SQLCipher.h>` includes (plugin + vendored FMDB)
//  working unchanged.
//
#ifndef SQFLITE_SQLCIPHER_UMBRELLA_H
#define SQFLITE_SQLCIPHER_UMBRELLA_H

#include "sqlite3.h"

#endif /* SQFLITE_SQLCIPHER_UMBRELLA_H */
