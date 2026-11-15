# Sound plan: from beeps to a real pool hall

## Where it stands

- About 20 effects, all built at start-up from sine waves and noise in `src/audio/sfx.gd`.
- One sound, `bad`, covers 17 different events (scratch, miss, early 8, failed purchase...).
- One pocket sound, a few click and cushion variants, and no sense of space: no room, no stereo, no mixing.
- Sharks, moving parts, Catalysts and the shaped boards make no sound of their own.
- The score-equation notes are fixed pitches that ignore the music playing underneath.

The music is the strongest part of the presentation; the effects should reach the same standard.

## 1. Physically modelled core sounds (the biggest win)

A new offline tool, `tools/compose_sfx.py`, built like `compose_score.py`. It renders every effect with NumPy, using models of the real materials, writes small `.ogg` files to `assets/sfx/`, and keeps everything original and synthesized: no samples, no licences.

| Sound | How it is modelled | Variation |
|---|---|---|
| **Ball on ball** | Modal synthesis of a phenolic-resin sphere: a sharp contact transient plus 4–6 high resonant modes (about 2–9 kHz) that ring briefly. Harder hits bring out more of the high modes | 6 variants × 3 impact strengths, pitch jitter ±3% |
| **Cushion** | A dull rubber thump (low, heavily damped) plus the wooden rail body resonating underneath | 4 variants × 3 strengths |
| **Pocket** | A sequence, not a single hit: the rim knock, two or three rattles as the ball drops through the jaw, then the ball rolling down the return gutter and clacking into the others | 5 variants; corner and side pockets sound different |
| **Cue strike** | A leather tip on phenolic (soft, short) plus a wooden cue thrum; a hard break adds a crack | 3 power layers, plus break and miscue |
| **Rolling** | A loop of filtered cloth noise whose volume and brightness follow how fast the balls are moving | One loop, driven live |
| **Rails by material** | Each board's rail material (see the visual pass) changes the cushion sound: chrome rings, stone is dead, glass chimes, wood is warm | One set per material family (about 8) |

## 2. The mix: making it sound like a room

- **Audio buses:** Master → Music, SFX, UI. A short **pool-hall reverb** on SFX only, and a **limiter** on Master so big break shots never clip.
- **Stereo:** effects pan by where they happen on the table (left pocket from the left speaker).
- **Strength curves:** volume and brightness follow impact speed, so a gentle kiss is quiet and dull and a break is loud and bright.
- **Voice limits:** at most a few simultaneous clicks, the loudest kept. A break then sounds full, not a buzz.
- **Ducking:** music dips slightly under big moments (big sums, clears, boss hits) and comes back smoothly.
- **Loudness targets:** every effect is normalised so nothing jumps out (peaks at most −1 dBFS, consistent loudness by category).

## 3. Sounds that carry meaning

- **The score equation plays in the board's key.** Each piece takes the next note of a pentatonic scale in the current track's key, so the sum becomes a little melody over the music. The final total lands on the root, louder. Multipliers get a brighter timbre than added points.
- **Heat:** each Heat tier adds a soft layer (a low crackle when On fire, a shimmer at Dead stroke) that fades out when the Heat drops.
- **Replace `bad` with specific sounds:** scratch (the cue ball dropping with a hollow thunk), miss (a soft, low "nothing"), the 8 sinking early (a dark sting), a failed purchase (a dry UI buzz), Chalk lost (a chalk-crumble tick).
- **Sharks:** a swim swish as they move, a rubbery thud when hit (rising in pitch as their health drops), a satisfying knock-out pop, a chomp when one swallows a ball, a till-ring for the Loan Shark.
- **Moving parts:** the Clockwork sweeper ticks, the pendulum whooshes, conveyors hum, turntables whirr, Maxwell's Demon's gate clicks. All of them stop when you pause.
- **Catalysts:** one signature sound each, matching the science: Time Reversal is a tape rewind, Wormhole a phased swoop, Event Horizon a deep hum, Newton's Cradle a clean double click, Golden Ratio a rising fifth, Force Field an electric hum.
- **UI set:** hover, click, buy, sell, reroll (cards shuffling), cards dealt into the shop, an Isotope applied (a crystalline tone), page turns.

## 4. How it gets checked (I can't hear it)

- **Measured, not guessed:** the tool writes a loudness and peak report and a spectrogram for each effect, and fails on clipping or anything far louder or quieter than its category.
- **A test** that every `sfx.play("...")` in the code names a sound that exists.
- **A listening page** for you: every new sound with a play button, what it's for and a 1–5 rating box. Your ratings decide what gets re-rendered.
- The app size barely changes: about 150 short effects come to about 1–2 MB as Ogg.

## Order

1. **Ball, cushion, pocket, cue and rolling sounds,** plus buses, reverb, limiter and stereo. This is what you hear every second, and is the biggest change for the least work.
2. **The score equation in key,** and the specific foul sounds replacing `bad`.
3. **Sharks, moving parts, Catalysts and the UI set.**
4. **Rail materials per board,** and the Heat layers.

Each step ships as its own release, with the listening page updated, so you can judge it on the phone.
