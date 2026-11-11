class_name Sfx
extends Node
## Procedurally synthesised sound effects: no audio files required.
## Each sound is rendered once into an AudioStreamWAV and played from a pool.

const RATE := 44100

var streams := {}
var players: Array[AudioStreamPlayer] = []
var next := 0
var volume := 0.8
var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var music_volume := 0.55
var current_track := ""
var variants := {}        # id -> several renders, picked at random so repeats never sound identical
var roll_player: AudioStreamPlayer
var roll_level := 0.0
## Mood or table id -> file under res://assets/music/. Every table has its own loop
## (made by tools/compose_score.py); the screens between tables keep their tracks.
const TRACKS := {
	"title": "velvet-orbit.mp3", "shop": "static-picnic.mp3", "endless": "mass-driver-groove.mp3", "victory": "solar-syncopation.mp3",
	"local": "boards/the-local.ogg", "frozen": "boards/frozen-lake.ogg", "spring_st": "boards/spring-street.ogg",
	"drift": "boards/the-drift.ogg", "slate": "boards/old-slate.ogg", "cramped": "boards/the-back-room.ogg",
	"parlor": "boards/pinball-parlor.ogg", "posts": "boards/twin-posts.ogg", "sinkhole": "boards/the-sinkhole.ogg",
	"hump": "boards/the-hump.ogg", "nineball": "boards/rotation-night.ogg", "magnet": "boards/the-magnet-room.ogg",
	"smoke": "boards/the-smoke-room.ogg", "blackice": "boards/black-ice.ogg", "tilted": "boards/the-tilted-table.ogg",
	"two": "boards/two-pockets.ogg", "closing": "boards/closing-time.ogg", "iron": "boards/the-iron-rack.ogg",
	"lights": "boards/lights-out.ogg", "hustler": "boards/the-hustler.ogg", "elements": "boards/the-element-table.ogg",
	"final": "boards/the-grand-final.ogg",
}


func _ready() -> void:
	music_a = AudioStreamPlayer.new()
	music_b = AudioStreamPlayer.new()
	add_child(music_a)
	add_child(music_b)
	music_a.volume_db = -80
	music_b.volume_db = -80
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	# Ball on ball: a hard phenolic sphere rings at a few inharmonic modes for a few
	# milliseconds. Each variant draws its own modes so a break never repeats a sample.
	variants["click"] = []
	variants["click_soft"] = []
	for k in 5:
		variants["click"].append(_render(0.07, _ball_click(91 + k, 1.0)))
		variants["click_soft"].append(_render(0.06, _ball_click(301 + k, 0.45)))
	streams["click"] = variants["click"][0]
	streams["click_soft"] = variants["click_soft"][0]
	variants["rail"] = []
	for k in 3:
		variants["rail"].append(_render(0.2, _cushion(17 + k)))
	streams["rail"] = variants["rail"][0]
	streams["pocket"] = _render(0.75, _pocket_drop(5))
	streams["cue"] = _render(0.14, _cue_tip(3))
	streams["portal"] = _render(0.45, _portal_whoosh(8))
	streams["wall"] = _render(0.18, func(t): return sin(TAU * (260.0 + 900.0 * t) * t) * exp(-t * 18.0) * 0.45 + _noise() * exp(-t * 200.0) * 0.3)
	streams["pause"] = _render(0.22, func(t): return sin(TAU * (660.0 - 300.0 * t) * t) * exp(-t * 11.0) * 0.3)
	streams["resume"] = _render(0.22, func(t): return sin(TAU * (420.0 + 400.0 * t) * t) * exp(-t * 11.0) * 0.3)
	roll_player = AudioStreamPlayer.new()
	add_child(roll_player)
	roll_player.stream = _rolling_loop(2.0)
	roll_player.volume_db = -80.0
	streams["tick"] = _render(0.09, func(t): return sin(TAU * 880.0 * t) * exp(-t * 40.0) * 0.5)
	streams["mult"] = _render(0.14, func(t): return (sin(TAU * 660.0 * t) + 0.5 * sin(TAU * 990.0 * t)) * exp(-t * 22.0) * 0.4)
	streams["xmult"] = _render(0.3, func(t): return (sin(TAU * 440.0 * t * (1.0 + t * 2.0)) + 0.4 * sin(TAU * 1320.0 * t)) * exp(-t * 9.0) * 0.45)
	streams["coin"] = _render(0.35, func(t): return (sin(TAU * 1568.0 * t) * (1.0 if t < 0.07 else 0.0) + sin(TAU * 2093.0 * t) * (0.0 if t < 0.07 else 1.0)) * exp(-t * 8.0) * 0.35)
	streams["bad"] = _render(0.35, func(t): return (sin(TAU * 220.0 * t) + sin(TAU * 233.0 * t)) * exp(-t * 7.0) * 0.3)
	streams["score"] = _render(0.5, func(t): return (sin(TAU * 523.25 * t) + sin(TAU * 659.25 * t) + sin(TAU * 783.99 * t)) * exp(-t * 6.0) * 0.25)
	streams["clear"] = _render(1.4, _fanfare)
	streams["ui"] = _render(0.05, func(t): return sin(TAU * 1200.0 * t) * exp(-t * 80.0) * 0.3)
	streams["bumper"] = _render(0.25, func(t): return sin(TAU * (300.0 + 500.0 * exp(-t * 20.0)) * t) * exp(-t * 12.0) * 0.5)


## Crossfades to the named mood ("title", "shop"...) or table id ("local", "final"...).
func play_music(mood: String) -> void:
	var file: String = TRACKS.get(mood, TRACKS["local"])
	if file == current_track:
		return
	current_track = file
	var path := "res://assets/music/%s" % file
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	var incoming := music_b if music_a.playing else music_a
	var outgoing := music_a if incoming == music_b else music_b
	incoming.stream = stream
	incoming.volume_db = -60
	incoming.play()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(incoming, "volume_db", _music_db(), 1.2)
	if outgoing.playing:
		tw.tween_property(outgoing, "volume_db", -60.0, 1.2)
		tw.chain().tween_callback(outgoing.stop)


func _music_db() -> float:
	return linear_to_db(maxf(music_volume, 0.0001))


## Pull the music down while the score tallies, then bring it back.
func duck(on: bool) -> void:
	var target := _music_db() - (7.0 if on else 0.0)
	var tw := create_tween()
	tw.set_parallel(true)
	for p in [music_a, music_b]:
		if p.playing and p.stream != null and p == _current_player():
			tw.tween_property(p, "volume_db", target, 0.2)
	if tw.get_total_elapsed_time() == 0.0 and not (music_a.playing or music_b.playing):
		tw.kill()


func _current_player() -> AudioStreamPlayer:
	return music_b if music_b.playing and music_b.volume_db > music_a.volume_db else music_a


func set_music_volume(v: float) -> void:
	music_volume = v
	for p in [music_a, music_b]:
		if p.playing:
			p.volume_db = _music_db()


var last_click_ms := 0


func play(id: String, vol: float = 1.0, pitch: float = 1.0) -> void:
	if not streams.has(id) or volume <= 0.0:
		return
	# On a break dozens of clicks land at once; a few per moment sound better.
	if id.begins_with("click"):
		var now := Time.get_ticks_msec()
		if now - last_click_ms < 12:
			return
		last_click_ms = now
	var p := players[next]
	next = (next + 1) % players.size()
	var pool: Array = variants.get(id, [])
	p.stream = pool[randi() % pool.size()] if not pool.is_empty() else streams[id]
	p.volume_db = linear_to_db(clampf(vol * volume, 0.001, 2.0))
	p.pitch_scale = clampf(pitch, 0.25, 4.0)
	p.play()


func _render(length: float, f: Callable) -> AudioStreamWAV:
	var n := int(length * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var seed_state := 12345
	for i in n:
		var t := float(i) / RATE
		var v: float = f.call(t)
		# Short fade-out to avoid clicks.
		var tail := clampf((length - t) / 0.01, 0.0, 1.0) * clampf(t / 0.0007, 0.0, 1.0)
		var s := int(clampf(v * tail, -1.0, 1.0) * 32000.0)
		data.encode_s16(i * 2, s)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w


var _noise_seed := 1


func _noise() -> float:
	_noise_seed = (_noise_seed * 1103515245 + 12345) & 0x7fffffff
	return float(_noise_seed) / float(0x7fffffff) * 2.0 - 1.0


## The cloth hum of rolling balls, louder and brighter the faster they move.
func set_roll(level: float) -> void:
	roll_level = lerpf(roll_level, clampf(level, 0.0, 1.0), 0.25)
	if roll_player == null:
		return
	if roll_level < 0.01 or volume <= 0.0:
		if roll_player.playing:
			roll_player.stop()
		return
	if not roll_player.playing:
		roll_player.play()
	roll_player.volume_db = linear_to_db(roll_level * volume * 0.5)
	roll_player.pitch_scale = 0.8 + roll_level * 0.5


func _ball_click(seed: int, hardness: float) -> Callable:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var base := r.randf_range(2500.0, 3300.0) * lerpf(0.7, 1.0, hardness)
	var modes: Array = []
	for ratio in [1.0, 1.51, 2.07, 2.74, 3.36]:
		var f: float = base * ratio * r.randf_range(0.97, 1.03)
		modes.append([f, r.randf_range(0.35, 1.0) / sqrt(ratio) * (1.0 if ratio < 2.5 else hardness), r.randf_range(120.0, 180.0) * pow(ratio, 0.35), r.randf() * TAU])
	var body := r.randf_range(700.0, 950.0)
	var lp := [0.0]
	return func(t: float) -> float:
		var v := 0.0
		for m in modes:
			v += sin(TAU * m[0] * t + m[3]) * m[1] * exp(-t * m[2])
		lp[0] += (_noise() - lp[0]) * lerpf(0.25, 0.8, hardness)
		return (v * 0.42 + sin(TAU * body * t) * exp(-t * 70.0) * 0.22 + lp[0] * exp(-t * 1400.0) * 0.7) * lerpf(0.6, 1.0, hardness)


## Rubber cushion: a falling low thump with a short woody knock from the rail.
func _cushion(seed: int) -> Callable:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var f0 := r.randf_range(105.0, 135.0)
	var wood := r.randf_range(280.0, 340.0)
	var lp := [0.0]
	return func(t: float) -> float:
		var f := f0 + 70.0 * exp(-t * 45.0)
		lp[0] += (_noise() - lp[0]) * 0.12
		return (sin(TAU * f * t) * exp(-t * 26.0) * 0.85 + sin(TAU * wood * t) * exp(-t * 48.0) * 0.28 + lp[0] * exp(-t * 90.0) * 0.5) * 0.72


## Into the pocket: a leather thud, then the ball rumbling down the return with a
## couple of soft knocks against balls already there.
func _pocket_drop(seed: int) -> Callable:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var lp := [0.0, 0.0]
	var knocks := [0.3 + r.randf() * 0.05, 0.47 + r.randf() * 0.06]
	return func(t: float) -> float:
		var v := sin(TAU * (80.0 + 40.0 * exp(-t * 30.0)) * t) * exp(-t * 11.0) * 0.8
		lp[0] += (_noise() - lp[0]) * 0.09
		v += lp[0] * exp(-t * 45.0) * 0.45
		lp[1] += (_noise() - lp[1]) * 0.025
		var roll := smoothstep(0.06, 0.14, t) * exp(-maxf(t - 0.12, 0.0) * 4.5)
		v += lp[1] * roll * (0.75 + 0.25 * sin(TAU * 11.0 * t)) * 0.9
		for k in knocks.size():
			if t > knocks[k]:
				var u: float = t - knocks[k]
				v += (sin(TAU * 2100.0 * u) * 0.5 + sin(TAU * 3150.0 * u) * 0.3) * exp(-u * 160.0) * (0.22 - k * 0.07)
		return v


## Leather tip on the cue ball: a short woody tock and a puff of chalk.
func _cue_tip(seed: int) -> Callable:
	var lp := [0.0]
	return func(t: float) -> float:
		lp[0] += (_noise() - lp[0]) * 0.5
		return sin(TAU * 720.0 * t) * exp(-t * 85.0) * 0.55 + sin(TAU * 1480.0 * t) * exp(-t * 140.0) * 0.22 + sin(TAU * 190.0 * t) * exp(-t * 45.0) * 0.3 + lp[0] * exp(-t * 900.0) * 0.5


func _portal_whoosh(seed: int) -> Callable:
	var lp := [0.0, 0.0]
	return func(t: float) -> float:
		var a := clampf(t / 0.45, 0.0, 1.0)
		lp[0] += (_noise() - lp[0]) * lerpf(0.02, 0.3, a)
		lp[1] += (lp[0] - lp[1]) * 0.3
		return lp[1] * sin(PI * a) * 0.9 + sin(TAU * (300.0 + 700.0 * a) * t) * sin(PI * a) * 0.18


func _rolling_loop(length: float) -> AudioStreamWAV:
	var lp := [0.0, 0.0]
	var w := _render(length, func(t: float) -> float:
		lp[0] += (_noise() - lp[0]) * 0.035
		lp[1] += (lp[0] - lp[1]) * 0.08
		return lp[1] * (0.85 + 0.15 * sin(TAU * 3.0 * t)) * 2.2)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = int(length * RATE) - 1
	return w


func _click(t: float) -> float:
	# Phenolic ball contact: two bright partials and a tiny noise transient.
	var v := sin(TAU * 3400.0 * t) * 0.55 + sin(TAU * 5100.0 * t) * 0.3 + sin(TAU * 1700.0 * t) * 0.3
	return v * exp(-t * 90.0) + _noise() * exp(-t * 600.0) * 0.5


func _rail(t: float) -> float:
	return sin(TAU * 140.0 * t) * exp(-t * 30.0) * 0.8 + _noise() * exp(-t * 120.0) * 0.25


func _pocket(t: float) -> float:
	var thud := sin(TAU * 90.0 * t) * exp(-t * 14.0) * 0.8
	var rattle := 0.0
	for k in 3:
		var t0 := 0.05 + k * 0.07
		if t > t0:
			var u := t - t0
			rattle += sin(TAU * (2400.0 - k * 500.0) * u) * exp(-u * 70.0) * (0.35 - k * 0.08)
	return thud + rattle + _noise() * exp(-t * 60.0) * 0.15


func _cue(t: float) -> float:
	return (sin(TAU * 950.0 * t) * 0.5 + sin(TAU * 1900.0 * t) * 0.2) * exp(-t * 70.0) + _noise() * exp(-t * 300.0) * 0.4


func _fanfare(t: float) -> float:
	var notes := [523.25, 659.25, 783.99, 1046.5]
	var v := 0.0
	for k in notes.size():
		var t0 := k * 0.11
		if t > t0:
			var u := t - t0
			var f: float = notes[k]
			v += (sin(TAU * f * u) + 0.3 * sin(TAU * f * 2.0 * u)) * exp(-u * 3.0) * 0.18
	return v


## Release the music streams on shutdown so nothing is left playing at exit.
func _exit_tree() -> void:
	if roll_player:
		roll_player.stop()
	for p in [music_a, music_b]:
		p.stop()
		p.stream = null
