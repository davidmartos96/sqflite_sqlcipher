#!/usr/bin/env bash
#
# Cross-version SQLCipher compatibility test on the iOS Simulator.
#
# `flutter test` installs the app, runs the test, then UNINSTALLS it — which
# deletes the per-app sandbox. So we cannot copy the created db out of the
# sandbox afterward, nor inject one before a verify run. Instead:
#
#   * create phases EXPORT the db as base64 over stdout (survives in the log);
#   * verify phases read the db from a bundled ASSET (baked into the app at
#     build time, survives install) and stage it into the sandbox at runtime.
#
#   1. app_v340 (3.4.0 pod) CREATES db_a, exports it           -> db_a.db
#   2. app_v400 (4.0.0 SPM) CREATES db_b, exports it           -> db_b.db
#   3. db_a -> app_v400/assets/incoming.db; app_v400 VERIFIES  (pod -> spm)
#   4. db_b -> app_v340/assets/incoming.db; app_v340 VERIFIES  (spm -> pod)
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST="integration_test/cross_version_test.dart"
PASSWORD="Cr0ss-V3rsion!SQLCipher_Key"
WORK="/tmp/sqlcipher_xtest_ios"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
red() { printf '\033[31m%s\033[0m\n' "$*"; }

# --- pick & boot a simulator -------------------------------------------------
UDID="${XTEST_SIM_UDID:-}"
[[ -z "$UDID" ]] && UDID="$(xcrun simctl list devices booted 2>/dev/null | grep -oE '[0-9A-Fa-f-]{36}' | head -1 || true)"
[[ -z "$UDID" ]] && UDID="$(xcrun simctl list devices available 2>/dev/null | grep -E 'iPhone' | grep -oE '[0-9A-Fa-f-]{36}' | head -1)"
[[ -n "$UDID" ]] || { red "No iOS simulator found."; exit 1; }
xcrun simctl boot "$UDID" 2>/dev/null || true
open -a Simulator 2>/dev/null || true

rm -rf "$WORK"; mkdir -p "$WORK"

# Keep shared/xtest_scenario.dart the single source of truth.
cp "$HERE/shared/xtest_scenario.dart" "$HERE/app_v340/integration_test/cross_version_test.dart"
cp "$HERE/shared/xtest_scenario.dart" "$HERE/app_v400/integration_test/cross_version_test.dart"

# run_create_export <app> <dbname> <creator> <out_db>
run_create_export() {
  local app="$1" dbname="$2" creator="$3" out="$4"
  local logf="$WORK/${app}_create.log"
  ( cd "$HERE/$app" && flutter test "$TEST" -d "$UDID" \
      --dart-define=MODE=create \
      --dart-define=DB_NAME="$dbname" \
      --dart-define=CREATOR="$creator" \
      --dart-define=PASSWORD="$PASSWORD" \
      --dart-define=EXPORT_B64=1 ) >"$logf" 2>&1
  grep -q "All tests passed" "$logf" || { red "    create failed for $app (see $logf)"; tail -30 "$logf"; exit 1; }
  grep -a "XTEST_B64:" "$logf" | sed -E 's/.*XTEST_B64://' | tr -d '\r\n' | base64 -D > "$out"
  [[ -s "$out" ]] || { red "    failed to reconstruct db from $logf"; exit 1; }
  green "    OK  (created + exported $(wc -c <"$out" | tr -d ' ') bytes)"
}

# run_verify_asset <app> <dbname> <db_in> <desc>
run_verify_asset() {
  local app="$1" dbname="$2" dbin="$3" desc="$4"
  local logf="$WORK/${app}_verify.log"
  bold ">>> $desc"
  cp "$dbin" "$HERE/$app/assets/incoming.db"
  ( cd "$HERE/$app" && flutter test "$TEST" -d "$UDID" \
      --dart-define=MODE=verify \
      --dart-define=DB_NAME="$dbname" \
      --dart-define=PASSWORD="$PASSWORD" \
      --dart-define=INPUT_ASSET=assets/incoming.db ) >"$logf" 2>&1
  if grep -q "All tests passed" "$logf"; then
    green "    OK: $desc"; grep "XTEST " "$logf" | sed 's/^/      /'
  else
    red "    FAIL: $desc (see $logf)"; tail -40 "$logf"; exit 1
  fi
  echo
}

assert_spm_v400() {
  bold ">>> Confirming app_v400 actually resolved SQLCipher.swift via SPM (iOS)"
  local hits
  hits="$(grep -rl "SQLCipher.swift" "$HERE/app_v400/ios" 2>/dev/null || true)"
  [[ -n "$hits" ]] || { red "    FAIL: no SPM artifacts referencing SQLCipher.swift in app_v400/ios."; exit 1; }
  green "    OK: SPM resolved SQLCipher.swift"; echo "$hits" | sed 's/^/      /'; echo
}

bold "=================================================================="
bold " Cross-version SQLCipher test (iOS Simulator)  UDID=$UDID"
bold " v3.4.0 = CocoaPods SQLCipher   |   v4.0.0 = SPM SQLCipher.swift"
bold "=================================================================="

bold ">>> Phase 1/4: v3.4.0 (pod) CREATES + exports db_a"
run_create_export app_v340 db_a.db 'v3.4.0 (CocoaPods pod)' "$WORK/db_a.db"; echo

bold ">>> Phase 2/4: v4.0.0 (SPM) CREATES + exports db_b"
run_create_export app_v400 db_b.db 'v4.0.0 (SPM SQLCipher.swift)' "$WORK/db_b.db"; echo

assert_spm_v400

run_verify_asset app_v400 db_a.db "$WORK/db_a.db" \
  "Phase 3/4: v4.0.0 (SPM) READS+VERIFIES db_a  [pod -> spm]"

run_verify_asset app_v340 db_b.db "$WORK/db_b.db" \
  "Phase 4/4: v3.4.0 (pod) READS+VERIFIES db_b  [spm -> pod]"

# Restore placeholder assets so the working tree stays clean.
printf 'placeholder' > "$HERE/app_v340/assets/incoming.db"
printf 'placeholder' > "$HERE/app_v400/assets/incoming.db"

bold "=================================================================="
green " ALL PHASES PASSED (iOS Simulator)"
bold " A SQLCipher database written by the CocoaPods 3.4.0 build was read"
bold " by the SPM 4.0.0 build, and vice versa, using the same key."
bold "=================================================================="
