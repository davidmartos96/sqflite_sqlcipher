# Cross-version SQLCipher compatibility test

Verifies that an encrypted SQLCipher database created by the **published
`sqflite_sqlcipher` 3.4.0** (CocoaPods `SQLCipher` pod) can be opened and read
by the **local 4.0.0** build (Swift Package Manager `SQLCipher.swift`), and
**vice versa**, using the same key — exercising both Apple backends that 4.0.0
introduced SPM support for.

## Why this matters

| Version | Source | iOS/macOS SQLCipher backend |
|---|---|---|
| `3.4.0` | pub.dev (`app_v340`) | CocoaPods `SQLCipher` / `FMDB/SQLCipher` pods |
| `4.0.0` | local path (`app_v400`) | Swift Package Manager → `SQLCipher.swift` xcframework + vendored FMDB |

Both ship SQLCipher 4.10.0 with the CommonCrypto backend, so on-disk databases
should be byte-compatible. This harness proves it end to end.

## Layout

```
cross_version_test/
├── shared/xtest_scenario.dart   Canonical create/verify scenario (single source of truth)
├── app_v340/                    Flutter app pinned to pub.dev sqflite_sqlcipher: 3.4.0
├── app_v400/                    Flutter app pinned to ../../sqflite_sqlcipher (local 4.0.0)
├── run_macos.sh                 macOS orchestrator (shared /tmp db, sandbox disabled)
└── run_ios.sh                   iOS Simulator orchestrator (simctl file shuttle)
```

`shared/xtest_scenario.dart` is copied verbatim into each app's
`integration_test/`. It compiles unchanged against either version because both
expose the same `package:sqflite_sqlcipher/sqflite.dart` API. Behaviour is
selected by `--dart-define`:

| define | values | meaning |
|---|---|---|
| `MODE` | `create` \| `verify` | create the db, or open it and assert its contents |
| `DB_DIR` | path | directory for the db file (empty ⇒ `getDatabasesPath()`, used on iOS) |
| `DB_NAME` | e.g. `db_a.db` | db file name |
| `CREATOR` | free text | label recorded in the `metadata` table on create |
| `PASSWORD` | string | the SQLCipher key (same on both sides) |

The scenario creates three tables (`users`, `notes`, `metadata`) covering
INTEGER / REAL / TEXT / BLOB / NULL and a unicode string, and on verify asserts
the exact dataset, that the **wrong key is rejected**, and that the file is
**not plaintext** SQLite.

## The four-phase flow

1. v3.4.0 (pod) **creates** `db_a`
2. v4.0.0 (SPM) **reads + verifies** `db_a`   — pod → spm
3. v4.0.0 (SPM) **creates** `db_b`
4. v3.4.0 (pod) **reads + verifies** `db_b`   — spm → pod

The macOS run also asserts that `app_v400` genuinely resolved
`SQLCipher.swift` through SPM (not the fallback podspec).

## Running

Prerequisites: Flutter ≥ 3.44, Xcode, CocoaPods, and **Swift Package Manager
enabled** so `app_v400` uses its `Package.swift`:

```sh
flutter config --enable-swift-package-manager
```

```sh
./run_macos.sh     # headless; both apps share /tmp/sqlcipher_xtest (app sandbox disabled)
./run_ios.sh       # boots a simulator; shuttles the db between app containers via simctl
```

Both exit non-zero on the first failure.

## Result

All four cells pass on macOS — the pod-built and SPM-built backends are fully
cross-compatible in both directions:

| writer ↓ / reader → | pod 3.4.0 | SPM 4.0.0 |
|---|---|---|
| **pod 3.4.0** | ✅ | ✅ |
| **SPM 4.0.0** | ✅ | ✅ |

## Notes / gotchas

- **`flutter config --enable-swift-package-manager` is global.** It is required
  for `app_v400` to build through SPM. `app_v340` has no `Package.swift`, so it
  keeps using CocoaPods regardless (exactly the pod-vs-SPM split we want).
- **macOS app sandbox is disabled** in both apps' `*.entitlements` so they can
  share one database file under `/tmp`. This is a test-harness convenience only.
- **sqflite caches open databases by path, ignoring the password.** Opening the
  same path twice returns the first (cached) handle — so a leaked wrong-key
  connection will be handed back to a later correct-key open and every read
  fails with a misleading `Code=7 "out of memory"`. The verify scenario uses
  `singleInstance: false` and always closes the wrong-key probe to stay
  independent. Keep this in mind when writing your own SQLCipher tests.
