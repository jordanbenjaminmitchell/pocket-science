#!/usr/bin/env bash
# Runs every headless suite; fails on any script error.
GODOT="${GODOT:-/c/Users/JordanMitchell/Documents/Codex/2026-09-08/can/work/godot/Godot_v4.7.2-stable_win64_console.exe}"
cd "$(dirname "$0")"
status=0
for t in tests/test_*.gd; do
  out=$(timeout 300 "$GODOT" --headless --fixed-fps 60 --path . --script "res://$t" 2>&1)
  code=$?
  echo "$out" | grep -vE "^(Godot Engine|$)" | grep -vE "Plugin is not attached|editor_debugger_plugin"
  if [ $code -ne 0 ] || echo "$out" | grep -qE "SCRIPT ERROR|Parse Error"; then
    echo "### $t FAILED"; status=1
  fi
done
exit $status
