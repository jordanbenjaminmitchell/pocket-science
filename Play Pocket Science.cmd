@echo off
rem Double-click to play. Uses the bundled Godot 4.7.2 runtime in .\runtime.
set "GAME_DIR=%~dp0"
if not exist "%GAME_DIR%runtime\Godot.exe" (
  echo The Godot runtime is missing. Open project.godot in Godot 4.7.2 and press F5 instead.
  pause
  exit /b 1
)
start "" "%GAME_DIR%runtime\Godot.exe" --path "%GAME_DIR%."
