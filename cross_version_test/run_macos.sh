#!/usr/bin/env bash
#
# Cross-version SQLCipher compatibility test on macOS.
#
#   Phase 1  app_v340 (pub.dev 3.4.0 -> CocoaPods SQLCipher)  CREATES  db_a
#   Phase 2  app_v400 (local 4.0.0  -> SPM SQLCipher.swift)   VERIFIES db_a   (pod  -> spm)
#   Phase 3  app_v400 (local 4.0.0  -> SPM SQLCipher.swift)   CREATES  db_b
#   Phase 4  app_v340 (pub.dev 3.4.0 -> CocoaPods SQLCipher)  VERIFIES db_b   (spm -> pod)
#
# Both apps run the SAME integration test (integration_test/cross_version_test.dart);
# only the --dart-define MODE/DB_NAME/CREATOR differ. They share one database file
# via a common /tmp directory (the macOS app sandbox is disabled in both apps).
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DBDIR="${XTEST_DBDIR:-/tmp/sqlcipher_xtest}"
DEVICE="macos"
TEST="integration_test/cross_version_test.dart"
PASSWORD="Cr0ss-V3rsion!SQLCipher_Key"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
red() { printf '\033[31m%s\033[0m\n' "$*"; }

run_phase() {
  local app="$1" mode="$2" dbname="$3" creator="$4" desc="$5"
  bold ">>> $desc"
  echo "    app=$app mode=$mode db=$dbname"
  ( cd "$HERE/$app" && flutter test "$TEST" -d "$DEVICE" \
      --dart-define=MODE="$mode" \
      --dart-define=DB_DIR="$DBDIR" \
      --dart-define=DB_NAME="$dbname" \
      --dart-define=CREATOR="$creator" \
      --dart-define=PASSWORD="$PASSWORD" )
  green "    OK: $desc"
  echo
}

assert_spm_v400() {
  bold ">>> Confirming app_v400 actually resolved SQLCipher.swift via SPM"
  local hits
  hits="$(grep -rl "SQLCipher.swift" "$HERE/app_v400/macos" 2>/dev/null || true)"
  if [[ -z "$hits" ]]; then
    red "    FAIL: no SPM artifacts referencing SQLCipher.swift were found."
    red "    app_v400 did not build through Swift Package Manager."
    exit 1
  fi
  green "    OK: SPM resolved SQLCipher.swift"
  echo "$hits" | sed 's/^/      /'
  echo
}

bold "=================================================================="
bold " Cross-version SQLCipher test (macOS)"
bold " v3.4.0 = CocoaPods SQLCipher   |   v4.0.0 = SPM SQLCipher.swift"
bold "=================================================================="
echo "Shared DB directory: $DBDIR"
rm -rf "$DBDIR"
mkdir -p "$DBDIR"

# Keep shared/xtest_scenario.dart the single source of truth.
cp "$HERE/shared/xtest_scenario.dart" "$HERE/app_v340/integration_test/cross_version_test.dart"
cp "$HERE/shared/xtest_scenario.dart" "$HERE/app_v400/integration_test/cross_version_test.dart"
echo

run_phase app_v340 create db_a.db "v3.4.0 (CocoaPods pod)" \
  "Phase 1/4: v3.4.0 (pod) CREATES db_a"

run_phase app_v400 verify db_a.db "v3.4.0 (CocoaPods pod)" \
  "Phase 2/4: v4.0.0 (SPM) READS+VERIFIES db_a  [pod -> spm]"

assert_spm_v400

run_phase app_v400 create db_b.db "v4.0.0 (SPM SQLCipher.swift)" \
  "Phase 3/4: v4.0.0 (SPM) CREATES db_b"

run_phase app_v340 verify db_b.db "v4.0.0 (SPM SQLCipher.swift)" \
  "Phase 4/4: v3.4.0 (pod) READS+VERIFIES db_b  [spm -> pod]"

bold "=================================================================="
green " ALL PHASES PASSED"
bold " A SQLCipher database written by the CocoaPods 3.4.0 build was read"
bold " by the SPM 4.0.0 build, and vice versa, using the same key."
bold "=================================================================="
ls -l "$DBDIR"
