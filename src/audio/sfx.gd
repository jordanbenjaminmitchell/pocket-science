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
const TRACKS := {
	"title": "velvet-orbit", "standard": "prism-pocket-jazz", "cryo": "cryo-cool",
	"cyclotron": "cyclotron-bounce", "spring": "bumper-ballet", "gravity": "event-horizon-jam",
	"current": "crystal-drift", "dense": "split-circuit-funk", "magnetlab": "mirror-chrome", "pinball": "spectrum-shuffle", "repulsor": "ion-switch",
	"boss": "last-pocket", "shop": "static-picnic", "endless": "mass-driver-groove", "victory": "solar-syncopation",
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
	streams["click"] = _render(0.09, _click)
	streams["click_soft"] = _render(0.06, func(t): return _click(t) * 0.6)
	streams["rail"] = _render(0.16, _rail)
	streams["pocket"] = _render(0.42, _pocket)
	streams["cue"] = _render(0.12, _cue)
	streams["tick"] = _render(0.09, func(t): return sin(TAU * 880.0 * t) * exp(-t * 40.0) * 0.5)
	streams["mult"] = _render(0.14, func(t): return (sin(TAU * 660.0 * t) + 0.5 * sin(TAU * 990.0 * t)) * exp(-t * 22.0) * 0.4)
	streams["xmult"] = _render(0.3, func(t): return (sin(TAU * 440.0 * t * (1.0 + t * 2.0)) + 0.4 * sin(TAU * 1320.0 * t)) * exp(-t * 9.0) * 0.45)
	streams["coin"] = _render(0.35, func(t): return (sin(TAU * 1568.0 * t) * (1.0 if t < 0.07 else 0.0) + sin(TAU * 2093.0 * t) * (0.0 if t < 0.07 else 1.0)) * exp(-t * 8.0) * 0.35)
	streams["bad"] = _render(0.35, func(t): return (sin(TAU * 220.0 * t) + sin(TAU * 233.0 * t)) * exp(-t * 7.0) * 0.3)
	streams["score"] = _render(0.5, func(t): return (sin(TAU * 523.25 * t) + sin(TAU * 659.25 * t) + sin(TAU * 783.99 * t)) * exp(-t * 6.0) * 0.25)
	streams["clear"] = _render(1.4, _fanfare)
	streams["ui"] = _render(0.05, func(t): return sin(TAU * 1200.0 * t) * exp(-t * 80.0) * 0.3)
	streams["bumper"] = _render(0.25, func(t): return sin(TAU * (300.0 + 500.0 * exp(-t * 20.0)) * t) * exp(-t * 12.0) * 0.5)


## Crossfades to the named mood ("title", a lab id, "boss", "shop"...).
func play_music(mood: String) -> void:
	var file: String = TRACKS.get(mood, "prism-pocket-jazz")
	if file == current_track:
		return
	current_track = file
	var path := "res://assets/music/%s.mp3" % file
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
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
	p.stream = streams[id]
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
		var tail := clampf((length - t) / 0.01, 0.0, 1.0)
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
	for p in [music_a, music_b]:
		p.stop()
		p.stream = null
