# Trick Shot — original score

Six original instrumental compositions, generated from the included melodies, chord sequences and synthesizers. No third-party recordings, samples or copied musical themes are used.

| Track | Runtime | Boards |
| --- | --- | --- |
| Velvet Orbit | 2:20 | Opening and menu |
| Crystal Drift | 2:47 | Black Ice, Cold Circuit |
| Portal Parade | 2:06 | Orbital, Twin Vortex, Orbit Gates |
| Bumper Ballet | 2:10 | Bumper, narrow, current and jump tables |
| Static Picnic | 2:00 | Dynamo and Switchboard |
| The Last Pocket | 1:50 | Other boss tables |

Total duration: approximately 13:12. Each full track has 64 bars with arranged introductions, phrases, variation, a quieter section, a bridge and a return. The game changes music by table and crossfades at changes. The offline HTML embeds all six MP3s. Sound and music start after a user interaction, as browsers require.

`manifest.json` gives exact durations and the authoritative mapping for all 18 boards. `tracks/` contains stereo MP3s. `trailer/trick-shot-theme.mp3` is a separate original thirty-second cue. The companion WAV-master ZIP contains the uncompressed stereo score and trailer stems.

Regenerate the score with `python scripts/media/compose-soundtrack.py --masters /path/to/masters` from the source root. Python, NumPy, SciPy and ffmpeg are required. The trailer scripts use the actual game engine through native Canvas2D; their tool dependencies are documented in `scripts/media/README.md`.

These assets were created for this Trick Shot project and may be included, edited and redistributed with the game. No exclusive copyright registration or third-party clearance is represented by this note.
