#!/usr/bin/env bash
# One command to verify everything before a commit or release:
# all test suites, a short run of every simulated player, and a Windows build.
set -u
GODOT="${GODOT:-/c/Users/JordanMitchell/Documents/Codex/2026-09-08/can/work/godot/Godot_v4.7.2-stable_win64_console.exe}"
cd "$(dirname "$0")/.."
fail=0
./run_tests.sh | grep -E "tests: |FAILED" || true
./run_tests.sh >/dev/null 2>&1 || fail=1
export APPDATA="$(cygpath -w "$(mktemp -d)")"
OUT="$(mktemp -d)"
for p in novice casual builder saver gambler expert; do
  if ! timeout 200 "$GODOT" --headless --path . --script res://tools/playtest.gd -- "$p" 2 7000 "$(cygpath -w "$OUT")\$p.jsonl" 2>&1 | grep -q "PLAYTEST DONE"; then
    echo "### persona $p failed"; fail=1
  fi
done
./build_windows.sh >/dev/null 2>&1 || fail=1
[ -s export/windows/PocketScience.pck ] || { echo "### build missing"; fail=1; }
[ $fail -eq 0 ] && echo "CI PASSED" || echo "CI FAILED"
exit $fail
