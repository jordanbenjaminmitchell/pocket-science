#!/usr/bin/env bash
# Builds export/android/PocketScience.apk (phones plus x86_64 emulators), debug-signed.
GODOT="${GODOT:-$(dirname "$0")/runtime/GodotConsole.exe}"
cd "$(dirname "$0")"
GODOT="./runtime/GodotConsole.exe"
export ANDROID_HOME="$(cygpath -w "$HOME/AppData/Local/Android/Sdk")"
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$(cygpath -w "$HOME/.android/debug.keystore")"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER="androiddebugkey"
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD="android"
# Signed with the local debug key: fine for installing on your own devices.
# A Play Store release needs its own private keystore.
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$GODOT_ANDROID_KEYSTORE_DEBUG_PATH"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="androiddebugkey"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="android"
mkdir -p export/android
"$GODOT" --headless --path . --import >/dev/null 2>&1
"$GODOT" --headless --path . --export-release "Android" export/android/PocketScience.apk 2>&1 | grep -vE "Plugin is not attached|editor_debugger_plugin|^$|leaked|still in use" | tail -25
ls -la export/android
