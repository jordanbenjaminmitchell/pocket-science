extends SceneTree
## Sound: every sound the code plays exists, the modelled bank loads, the mix is set up.

var failures := 0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func _initialize() -> void:
	call_deferred("_go")


func _scan(dir: String, ids: Dictionary) -> void:
	var d := DirAccess.open(dir)
	for f in d.get_files():
		if f.ends_with(".gd"):
			var text := FileAccess.get_file_as_string(dir + "/" + f)
			var re := RegEx.new()
			re.compile("sfx\\.play\\(\"(\\w+)\"")
			for m in re.search_all(text):
				ids[m.get_string(1)] = dir + "/" + f
	for sub in d.get_directories():
		_scan(dir + "/" + sub, ids)


func _go() -> void:
	var sfx := Sfx.new()
	root.add_child(sfx)
	await process_frame
	print("every sound the game plays exists")
	var ids := {}
	_scan("res://src", ids)
	check(ids.size() >= 10, "found the sounds the code plays (%d)" % ids.size())
	for id in ids:
		check(sfx.streams.has(id), "%s exists (played in %s)" % [id, ids[id]])
	print("the modelled sounds")
	for id in SfxBank.FILES:
		if id != "roll":
			check(sfx.variants.has(id) and (sfx.variants[id] as Array).size() == (SfxBank.FILES[id] as Array).size(), "%s loads all %d variants" % [id, (SfxBank.FILES[id] as Array).size()])
	check(sfx.roll_player.stream is AudioStreamOggVorbis and (sfx.roll_player.stream as AudioStreamOggVorbis).loop, "the rolling sound is the looping cloth recording")
	check(Sfx.layered("click", 0.1) == "click_soft" and Sfx.layered("click", 0.5) == "click" and Sfx.layered("click", 0.9) == "click_hard", "impact strength picks the soft, normal or hard click")
	check(Sfx.layered("rail", 0.9) == "rail_hard" and Sfx.layered("cue", 0.2) == "cue_soft", "and the same for cushions and the cue")
	print("the mix")
	for bus in ["Music", "SFX", "UI", "SFX_P0", "SFX_P4"]:
		check(AudioServer.get_bus_index(bus) >= 0, "%s bus exists" % bus)
	check(AudioServer.get_bus_effect_count(AudioServer.get_bus_index("SFX")) >= 1, "table sounds go through a room reverb")
	check(AudioServer.get_bus_effect_count(AudioServer.get_bus_index("Master")) >= 1, "the Master has a limiter, so nothing clips")
	print("sfx tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
