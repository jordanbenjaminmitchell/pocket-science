#!/usr/bin/env bash
# One command to verify everything before a commit or release:
# all test suites, a short run by one simulated player (all six with FULL=1),
# and the Windows and Android builds.
set -u
GODOT="${GODOT:-/c/Users/JordanMitchell/Documents/Codex/2026-09-08/can/work/godot/Godot_v4.7.2-stable_win64_console.exe}"
GODOT_TIMEOUT_BIN="${GODOT_TIMEOUT_BIN:-/usr/bin/timeout}"
cd "$(dirname "$0")/.."
fail=0
test_out="$(./run_tests.sh 2>&1)"
test_code=$?
echo "$test_out" | grep -E "tests: |FAILED" || true
[ $test_code -eq 0 ] || fail=1
REAL_APPDATA="$APPDATA"
export APPDATA="$(cygpath -w "$(mktemp -d)")"
OUT="$(mktemp -d)"
# One simulated player is enough to prove a build plays through; FULL=1 runs all
# six for a balance pass.
PERSONAS="expert"
[ "${FULL:-0}" = "1" ] && PERSONAS="novice casual builder saver gambler expert"
for p in $PERSONAS; do
  if ! "$GODOT_TIMEOUT_BIN" 200 "$GODOT" --headless --path . --script res://tools/playtest.gd -- "$p" 2 7000 "$(cygpath -w "$OUT")\$p.jsonl" 2>&1 | grep -q "PLAYTEST DONE"; then
    echo "### persona $p failed"; fail=1
  fi
done
export APPDATA="$REAL_APPDATA"   # the builds need the real export templates
rm -f export/android/PocketScience.apk   # a stale APK must not pass the check below
./build_windows.sh >/dev/null 2>&1 || fail=1
./build_android.sh >/dev/null 2>&1 || fail=1
[ -s export/windows/PocketScience.pck ] || { echo "### Windows build missing"; fail=1; }
[ -s export/android/PocketScience.apk ] || { echo "### Android build missing"; fail=1; }
[ $fail -eq 0 ] && echo "CI PASSED" || echo "CI FAILED"
exit $fail
