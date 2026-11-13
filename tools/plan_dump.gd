extends SceneTree
## Reconstructs deterministic nine-board plans for archived playtest seeds.
## Godot --headless --path . --script res://tools/plan_dump.gd -- <seed0> <count> <out.jsonl>

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("Expected seed0 count out.jsonl")
		quit(1)
		return
	var out := FileAccess.open(String(args[2]), FileAccess.WRITE)
	if out == null:
		push_error("Cannot open " + String(args[2]))
		quit(1)
		return
	for seed_value in range(int(args[0]), int(args[0]) + int(args[1])):
		var state := RunState.new()
		state.start(seed_value)
		out.store_line(JSON.stringify({"seed": seed_value, "boards": state.plan.map(func(t): return t.id)}))
	out.close()
	quit()
