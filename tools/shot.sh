#!/usr/bin/env bash
# Renders a capture scenario using a throwaway profile: tools/shot.sh <scenario> [crop x y w h]
GODOT="${GODOT:-/c/Users/JordanMitchell/Documents/Codex/2026-09-08/can/work/godot/Godot_v4.7.2-stable_win64_console.exe}"
cd "$(dirname "$0")/.."
s="$1"; shift
APPDATA="$(cygpath -w "$(mktemp -d)")" timeout 120 "$GODOT" --path . --resolution "${SHOT_RES:-1600x900}" --script res://tools/capture.gd -- "$s" "$(pwd -W)/shots/$s.png" "$@" 2>&1 | grep -E "SCRIPT ERROR|CAPTURED"
