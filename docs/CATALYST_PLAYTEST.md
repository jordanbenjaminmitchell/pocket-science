# Headless Catalyst bot

`tools/playtest.gd` now buys and uses Catalysts. It tries each available Catalyst on a clone of the current physical table, scores the resulting shot with the production scorer, and spends a charge only when the tested outcome beats the same shot without a Catalyst by at least 10 points or 4% of that table's target. Trial scoring uses a separate deterministic RNG so failed trials do not consume the run's random stream. Successful uses are recorded in each run's `catalysts_used` JSON object; `catalyst_trials` records how often each owned tool had a valid test and a beneficial shot.

Run paired batches with the same persona and starting seeds:

```powershell
& .\runtime\GodotConsole.exe --headless --path . --script res://tools/playtest.gd -- expert 20 1000 catalyst_on.jsonl 1
& .\runtime\GodotConsole.exe --headless --path . --script res://tools/playtest.gd -- expert 20 1000 catalyst_off.jsonl 0
```

The last argument enables or disables Catalyst purchases and use. Same seeds keep the starting cue and table plan comparable; shop and shot paths may diverge once a purchase or tool use changes the run. These are full headless physics runs, not the synthetic scoring probe.

An optional sixth argument grants one named Catalyst at the start of every run, so a targeted experiment can compare it with a same-seed control. For example, append `goldenratio` to the enabled command. The grant is free and occupies a Kit slot, so this measures an upper bound on usefulness rather than shop value per dollar.

The bot can use all 30 current Catalysts. It has bounded, one-shot lookahead for 28. It tests setup effects such as Focal Point, Event Horizon, Quantum Tunnel, Mass Shift, Entanglement, Fixed Point, Wormhole, Black Hole, Pythagorean Triple and Hooke's Law. Zero Friction is tested both before a shot and on an already rolling ball. It also pauses a cloned shot after 0.32 simulated seconds to try motion effects such as Impulse, Vector, Golden Ratio, Force Field, Gravity Well, Tidal Pull and others. Fixed Point and Wormhole persist on the board after use, as they do in the game. Each candidate uses a small set of heuristic targets and placements; a failure to use a Catalyst does not prove it is weak for a skilled human.

Time Reversal and Conservation use separate policies because their value spans shots. Conservation returns the highest-value sunk ball when at most three objects remain and the score gap warrants it. Time Reversal retries a scratch or a failed shot at low Chalk with a fresh aim error. These are deliberately simple decisions, and Time Reversal currently uses knowledge of the settled trial shot as a proxy for the game's pause prediction.

For individual Catalyst balance, compare usage and outcomes over many matched seeds, then inspect how often its candidate placements were considered. The current bot is a baseline for testing whether Catalysts help a run, not a measure of each Catalyst's full potential.
