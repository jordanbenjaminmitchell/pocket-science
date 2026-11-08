#!/usr/bin/env bash
# Builds a standalone Windows folder in export/windows: the game as a .pck beside
# a Godot runtime of the same name, which loads it automatically on launch.
# (Official export templates would give a smaller .exe; this needs no download.)
GODOT="${GODOT:-/c/Users/JordanMitchell/Documents/Codex/2026-09-08/can/work/godot/Godot_v4.7.2-stable_win64_console.exe}"
cd "$(dirname "$0")"
mkdir -p export/windows
"$GODOT" --headless --path . --import >/dev/null 2>&1
"$GODOT" --headless --path . --export-pack "Windows Desktop" export/windows/PocketScience.pck 2>&1 | grep -E "ERROR|error" | grep -v "Plugin is not attached"
cp runtime/Godot.exe export/windows/PocketScience.exe
cp -r licenses export/windows/
ls -la export/windows
