#!/usr/bin/env bash
# Runs every headless suite; fails on any script error.
GODOT="${GODOT:-/c/Users/JordanMitchell/Documents/Codex/2026-09-08/can/work/godot/Godot_v4.7.2-stable_win64_console.exe}"
GODOT_TIMEOUT_BIN="${GODOT_TIMEOUT_BIN:-/usr/bin/timeout}"
cd "$(dirname "$0")"
# Tests write saves and settings, so run them against a throwaway profile:
# Godot derives user:// from APPDATA, and the player's real data stays untouched.
TEST_HOME="$(mktemp -d)"
export APPDATA="$(cygpath -w "$TEST_HOME")"
status=0
"$GODOT" --headless --path . --import >/dev/null 2>&1
for t in tests/test_*.gd; do
  out=$("$GODOT_TIMEOUT_BIN" 300 "$GODOT" --headless --fixed-fps 60 --path . --script "res://$t" 2>&1)
  code=$?
  echo "$out" | grep -vE "^(Godot Engine|$)" | grep -vE "Plugin is not attached|editor_debugger_plugin"
  if [ $code -ne 0 ] || echo "$out" | grep -qE "SCRIPT ERROR|Parse Error"; then
    echo "### $t FAILED"; status=1
  fi
done
exit $status
