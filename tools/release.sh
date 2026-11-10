#!/usr/bin/env bash
# One command to ship: bumps the version, runs every check, builds Windows and
# Android, pushes, and publishes a GitHub release with both downloads.
#   ./tools/release.sh "What changed, in a line"
# Phones update in place because each release raises the Android version code
# and every build is signed with the same key on this PC.
set -eu
cd "$(dirname "$0")/.."
GH="${GH:-/c/Program Files/GitHub CLI/gh.exe}"
NOTES="${1:-Latest build.}"

code=$(grep -oP 'version/code=\K[0-9]+' export_presets.cfg)
code=$((code + 1))
name="1.$code"
sed -i -E "s/version\/code=[0-9]+/version\/code=$code/; s/version\/name=\"[^\"]*\"/version\/name=\"$name\"/" export_presets.cfg
sed -i -E "s/^config\/version=.*/config\/version=\"$name\"/" project.godot
grep -q '^config/version=' project.godot || sed -i -E "s/^(config\/name=.*)$/\1\nconfig\/version=\"$name\"/" project.godot

ci_out="$(./tools/ci.sh 2>&1 || true)"
echo "$ci_out" | tail -3
echo "$ci_out" | grep -q "CI PASSED" || { echo "### checks failed, nothing released"; exit 1; }
[ -s export/android/PocketScience.apk ] && [ -s export/windows/PocketScience.pck ] || { echo "### builds missing, nothing released"; exit 1; }

rm -f export/PocketScience-Windows.zip
powershell -NoProfile -Command "Compress-Archive -Path 'export/windows/*' -DestinationPath 'export/PocketScience-Windows.zip' -Force"

git add -A
git commit -q -m "Release $name" -m "$NOTES" || true
git push -q origin HEAD
"$GH" release create "v$name" export/android/PocketScience.apk export/PocketScience-Windows.zip \
  --title "Pocket Science $name" --notes "$NOTES

**Phone:** download PocketScience.apk on the phone and open it. It installs over the previous version.
**PC:** download PocketScience-Windows.zip, unzip it and run PocketScience.exe (keep the .pck beside it)."
echo "Released v$name"
