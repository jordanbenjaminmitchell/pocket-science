class_name GameSettings
extends RefCounted
## Player preferences, persisted in user://settings.cfg (section "settings").
## Personal bests live in the same file under "best" and are left untouched.

const PATH := "user://settings.cfg"

var master := 1.0
var music := 0.55
var sfx := 0.8
var fullscreen := false
var vsync := true
var shake := 1.0            # 0..1.5 multiplier on screen shake
var reduced_motion := false # no shake, zoom punches or confetti
var aim_speed := 1.0        # keyboard fine-aim speed multiplier
var pull := 1.0             # drag distance for full power (0.6 short .. 1.6 long)

const KEYS := ["master", "music", "sfx", "fullscreen", "vsync", "shake", "reduced_motion", "aim_speed", "pull"]


func load_file() -> void:
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return
	# Migrate the old on/off audio toggles if present.
	if c.has_section_key("audio", "sfx") and not c.has_section_key("settings", "sfx"):
		sfx = float(c.get_value("audio", "sfx", 0.8))
		music = float(c.get_value("audio", "music", 0.55))
	for k in KEYS:
		if c.has_section_key("settings", k):
			set(k, c.get_value("settings", k))
	_clamp()


func save_file() -> void:
	var c := ConfigFile.new()
	c.load(PATH)
	for k in KEYS:
		c.set_value("settings", k, get(k))
	c.save(PATH)


func _clamp() -> void:
	master = clampf(float(master), 0.0, 1.0)
	music = clampf(float(music), 0.0, 1.0)
	sfx = clampf(float(sfx), 0.0, 1.0)
	shake = clampf(float(shake), 0.0, 1.5)
	aim_speed = clampf(float(aim_speed), 0.25, 3.0)
	pull = clampf(float(pull), 0.6, 1.6)
	fullscreen = bool(fullscreen)
	vsync = bool(vsync)
	reduced_motion = bool(reduced_motion)


func reset() -> void:
	master = 1.0
	music = 0.55
	sfx = 0.8
	fullscreen = false
	vsync = true
	shake = 1.0
	reduced_motion = false
	aim_speed = 1.0
	pull = 1.0
