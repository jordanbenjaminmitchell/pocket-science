#!/usr/bin/env bash
# Compile-checks every script and prints errors with file:line.
GODOT="${GODOT:-/c/Users/JordanMitchell/Documents/Codex/2026-09-08/can/work/godot/Godot_v4.7.2-stable_win64_console.exe}"
cd "$(dirname "$0")"
for f in $(find src tests tools -name "*.gd"); do
  out=$("$GODOT" --headless --path . --check-only --script "res://$f" 2>&1 | grep -E -A2 "Parse Error|SCRIPT ERROR" | grep -vE "Failed to compile depended|Failed to load script" )
  if [ -n "$out" ]; then echo "== $f"; echo "$out" | head -12; fi
done
