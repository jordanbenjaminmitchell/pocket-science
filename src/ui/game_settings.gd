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
var invert_drag := false    # push forward instead of pulling back
var click_shoot := false    # set power with wheel/keys, click to shoot
var colorblind := false     # safe guideline palette
var number_tags := false    # flat, always-readable number on every ball
var large_text := false     # bigger small text
var touch_mode := false     # on-screen aim, power and shoot controls
var frame_cap := 0          # index into FRAME_CAPS
var window_size := 1        # index into WINDOW_SIZES
var screen_layout := 0      # index into SCREEN_LAYOUTS
var guide_lines := 1        # index into GUIDE_LINES; All balls by default
var guide_rev := 2          # settings saved before All balls became the default get it once
var pause_on_hit := false   # pause a shot by itself the moment the cue ball first hits a ball
var smooth_arrows := false  # arrow keys sweep at once instead of quarter-degree taps
var fine_drag := false      # touch: dragging turns the aim a little instead of pointing it
var dev_mode := false       # unlocks every Perk, cue and difficulty, and skips the introduction
var invert_aim := false     # touch: Fine aim drags and the FINE AIM strip turn the other way

const SCREEN_LAYOUTS := ["Classic", "Wide"]
## "All balls" also simulates the shot and draws where every ball will end up.
const GUIDE_LINES := ["Standard", "All balls"]
const FRAME_CAPS := [0, 30, 60, 120, 144, 240]
const WINDOW_SIZES := [Vector2i(1280, 720), Vector2i(1440, 810), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]

## Rebindable actions: id -> [label, default key].
const ACTIONS := {
	"shoot": ["Shoot / fast-forward", KEY_SPACE], "power_up": ["Power up", KEY_UP], "power_down": ["Power down", KEY_DOWN],
	"aim_left": ["Aim left", KEY_LEFT], "aim_right": ["Aim right", KEY_RIGHT], "spin_up": ["Spin: follow", KEY_W],
	"spin_down": ["Spin: draw", KEY_S], "spin_left": ["Spin: left", KEY_A], "spin_right": ["Spin: right", KEY_D],
	"place": ["Move cue ball on break", KEY_H], "fine": ["Toggle fine aim", KEY_F],
	"pause_shot": ["Pause or resume a shot", KEY_P], "plan": ["Lock prediction to plan a pause", KEY_L],
	
}

var keys := {}

const KEYS := ["master", "music", "sfx", "fullscreen", "vsync", "shake", "reduced_motion", "aim_speed", "pull", "invert_drag", "click_shoot", "colorblind", "number_tags", "large_text", "touch_mode", "frame_cap", "window_size", "screen_layout", "guide_lines", "pause_on_hit", "guide_rev", "smooth_arrows", "fine_drag", "dev_mode", "invert_aim"]


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
	if not c.has_section_key("settings", "guide_rev"):
		guide_lines = 1
		guide_rev = 2
	_clamp()
	reset_keys()
	for a in ACTIONS:
		if c.has_section_key("keys", a):
			keys[a] = int(c.get_value("keys", a))


func _init() -> void:
	reset_keys()
	_device_defaults()


## Phones and tablets start with touch controls, larger text and the Wide layout.
func _device_defaults() -> void:
	if OS.has_feature("mobile"):
		touch_mode = true
		large_text = true
		screen_layout = 1


func reset_keys() -> void:
	keys = {}
	for a in ACTIONS:
		keys[a] = ACTIONS[a][1]


## Binds a key to an action; if another action had it, they swap.
func bind(action: String, key: int) -> void:
	for other in keys:
		if other != action and keys[other] == key:
			keys[other] = keys[action]
	keys[action] = key


func action_for(key: int) -> String:
	for a in keys:
		if keys[a] == key:
			return a
	return ""


func save_file() -> void:
	var c := ConfigFile.new()
	c.load(PATH)
	for k in KEYS:
		c.set_value("settings", k, get(k))
	for a in keys:
		c.set_value("keys", a, keys[a])
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
	invert_drag = bool(invert_drag)
	click_shoot = bool(click_shoot)
	colorblind = bool(colorblind)
	number_tags = bool(number_tags)
	large_text = bool(large_text)
	touch_mode = bool(touch_mode)
	frame_cap = clampi(int(frame_cap), 0, FRAME_CAPS.size() - 1)
	window_size = clampi(int(window_size), 0, WINDOW_SIZES.size() - 1)
	screen_layout = clampi(int(screen_layout), 0, SCREEN_LAYOUTS.size() - 1)
	guide_lines = clampi(int(guide_lines), 0, GUIDE_LINES.size() - 1)
	pause_on_hit = bool(pause_on_hit)
	smooth_arrows = bool(smooth_arrows)


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
	invert_drag = false
	click_shoot = false
	colorblind = false
	number_tags = false
	large_text = false
	touch_mode = false
	screen_layout = 0
	guide_lines = 1
	pause_on_hit = false
	smooth_arrows = false
	fine_drag = false
	dev_mode = false
	invert_aim = false
	_device_defaults()
	frame_cap = 0
	window_size = 1
	reset_keys()
