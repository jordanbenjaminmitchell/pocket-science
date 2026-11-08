#!/usr/bin/env bash
# Builds the standalone Windows game in export/windows using the official templates.
cd "$(dirname "$0")"
GODOT="./runtime/GodotConsole.exe"
mkdir -p export/windows
rm -f export/windows/PocketScience.exe export/windows/PocketScience.pck
"$GODOT" --headless --path . --import >/dev/null 2>&1
"$GODOT" --headless --path . --export-release "Windows Desktop" export/windows/PocketScience.exe 2>&1 | grep -E "ERROR|failed" | grep -vE "Plugin is not attached|still in use"
cp -r licenses export/windows/
ls -la export/windows
