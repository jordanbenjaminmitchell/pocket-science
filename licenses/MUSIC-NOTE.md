# Pocket Science — original score

All music is original and instrumental, made from synthesisers and code. No third-party recordings, samples or copied musical themes are used. These assets were created for Pocket Science and may be included, edited and redistributed with the game. No exclusive copyright registration or third-party clearance is represented by this note.

## Board score

Every table has its own loop, named after the table, in `assets/music/boards/`, rendered by `tools/compose_score.py` (Python with NumPy and SciPy, plus ffmpeg with libvorbis). Each one is chill lo-fi on top and trap underneath: a half-time kit with hat rolls, 808 slides, a snare-roll build and a wobble-bass drop ("womp, a womp womp").

Each song is 64 bars: intro, groove, build, drop, break, second groove, second build, second drop, then an outro that fades back into the intro. The render runs past bar 64 and folds that tail onto the start, so the Ogg Vorbis files loop without a seam. The tables marked tense use harsher harmony, faster hat rolls, darker filters and lab sounds such as Geiger clicks and drones.

Every melody is read from a mathematical sequence:

| Track (named for its table) | BPM | Length | Sequence | Mood |
| --- | --- | --- | --- | --- |
| The Local | 72 | 3:33 | digits of π | chill |
| Frozen Lake | 68 | 3:45 | digits of e | chill |
| Spring Street | 78 | 3:16 | Fibonacci | chill |
| The Drift | 74 | 3:27 | Collatz orbit of 27 | chill |
| Old Slate | 66 | 3:52 | prime gaps | mellow |
| The Back Room | 76 | 3:22 | look-and-say | uneasy |
| Pinball Parlor | 82 | 3:07 | Catalan numbers | chill |
| Twin Posts | 76 | 3:22 | Thue–Morse | mellow |
| The Sinkhole | 70 | 3:39 | Recamán | uneasy |
| The Hump | 74 | 3:27 | digits of √2 | uneasy |
| Rotation Night | 75 | 3:24 | triangular numbers, nine-step arpeggio | uneasy |
| The Magnet Room | 72 | 3:33 | digits of φ | uneasy |
| The Smoke Room | 70 | 3:39 | square numbers | uneasy |
| Black Ice | 68 | 3:45 | digits of √3 | tense |
| The Tilted Table | 74 | 3:27 | digits of ln 2 | tense |
| Two Pockets | 76 | 3:22 | twin primes | tense |
| Closing Time | 80 | 3:12 | 1/7 = 0.142857… | tense |
| The Iron Rack | 66 | 3:52 | cube numbers | tense |
| Lights Out | 72 | 3:33 | digits of √5 | tense |
| The Hustler | 76 | 3:22 | Euler's totient | tense |
| The Element Table | 78 | 3:16 | Pascal's triangle mod 7 | very tense |
| The Grand Final | 80 | 3:12 | 1/81 = 0.012345679…, every digit but the 8 | very tense |

Regenerate with `py -3.12 tools/compose_score.py` (all boards) or name board ids to render only those. `--inspect DIR` also keeps WAV masters and writes spectrograms and a per-bar level report.

## Other music

The title screen (`velvet-orbit.mp3`), Pro Shop (`static-picnic.mp3`), endless mode (`mass-driver-groove.mp3`) and victory (`solar-syncopation.mp3`) use tracks from the earlier score in `assets/music/`.
