class_name TileArt
extends Control
## The top of a Pro Shop offer card, styled after a periodic-table tile but
## carrying only game information:
##
##   top left      what kind of card it is, and under it its rarity (perks),
##                 when it can be used (kit items) or how long it lasts
##   top right     the card's vector motif (imbues: the ball it goes on)
##   middle        a large one- or two-letter symbol, and the name under it
##   bottom left   the headline effect (×2, +1 Chain, 30 pts)
##   bottom right  what it acts on (Pockets, 7-ball, Cue ball)
##
## Symbols are unique across all cards. A card may use a real element's symbol
## when it fits (Gold ball = Au), but the tile never says so.

const F_SEMI: Font = preload("res://assets/fonts/ChakraPetch-SemiBold.ttf")
const F_REG: Font = preload("res://assets/fonts/ChakraPetch-Regular.ttf")
const SIZE := Vector2(172, 118)

## Per card: symbol, headline effect, (non-perks) what it acts on, and the
## lettering effect (see Lettering below). Every card has its own effect, drawn
## on whichever text effects_on picks (the big symbol, by default).
## Perks show their family instead of "on". Symbols are real element symbols
## where one fits the name (Ca, the chalk mineral, for Spare Chalk), invented
## otherwise. Every perk is here; imbues, balls and items have samples so far.
const TILES := {
	# Physics
	"perk:velvet": {"sym": "V", "stat": "−30% friction", "letter": "velvet"},
	"perk:featherweight": {"sym": "F", "stat": "−25% weight", "letter": "feather"},
	"perk:heavyhit": {"sym": "Hs", "stat": "+30% cue weight", "letter": "heavy"},
	"perk:liverails": {"sym": "Lv", "stat": "+10% bounce", "letter": "spring"},
	"perk:slowcloth": {"sym": "Cl", "stat": "Stops 25% sooner", "letter": "brake"},
	"perk:backspin": {"sym": "Ba", "stat": "+50% spin", "letter": "spin"},
	"perk:bigbreak": {"sym": "Br", "stat": "+25% break", "letter": "shatter"},
	"perk:longarm": {"sym": "Lr", "stat": "+15% full power", "letter": "reach"},
	# Cue control
	"perk:kick": {"sym": "K", "stat": "Kicks ×2", "letter": "kick"},
	"perk:power": {"sym": "P", "stat": "85%+: +1 Chain", "letter": "power"},
	"perk:finesse": {"sym": "Ts", "stat": "Soft shots ×2", "letter": "soft"},
	"perk:boomerang": {"sym": "B", "stat": "Return: ×2", "letter": "boomerang"},
	"perk:precision": {"sym": "Cs", "stat": "+1 Chain", "letter": "crosshair"},
	"perk:stun": {"sym": "Mt", "stat": "Stun 60%", "letter": "stun"},
	"perk:afterburner": {"sym": "Ar", "stat": "Break +3 Chain", "letter": "breakup"},
	"perk:masse": {"sym": "Ms", "stat": "×2 swerve", "letter": "swerve"},
	"perk:followthru": {"sym": "Fr", "stat": "+0.5 Chain", "letter": "follow"},
	"perk:drawartist": {"sym": "Ds", "stat": "Draw ×1.5", "letter": "sketch"},
	# Combos & clusters
	"perk:elastic": {"sym": "Ta", "stat": "+0.25/hit", "letter": "loud"},
	"perk:chain": {"sym": "Dy", "stat": "×2", "letter": "links"},
	"perk:multi": {"sym": "Cu", "stat": "+1 Chain", "letter": "cluster"},
	"perk:supernova": {"sym": "Cn", "stat": "3+: ×2", "letter": "sweep"},
	"perk:fusion": {"sym": "Po", "stat": "×3", "letter": "merge"},
	"perk:domino": {"sym": "Dm", "stat": "+30", "letter": "topple"},
	# Streaks
	"perk:streak": {"sym": "Sk", "stat": "+1 Heat", "letter": "stoke"},
	"perk:rhythm": {"sym": "Rh", "stat": "Every 3rd ×2", "letter": "beat"},
	"perk:comeback": {"sym": "La", "stat": "Last Chalk ×2", "letter": "stub"},
	# Heat
	"perk:entropy": {"sym": "Sm", "stat": "Heat <3: +1 Chain", "letter": "simmer"},
	"perk:hothand": {"sym": "Ho", "stat": "Heat 3+: +30", "letter": "shimmer"},
	"perk:migration": {"sym": "At", "stat": "Miss: −1 Heat", "letter": "glow"},
	"perk:coupon": {"sym": "Cd", "stat": "Heat 0: ×2", "letter": "frost"},
	"perk:minimalist": {"sym": "Ir", "stat": "On fire: ×2", "letter": "inferno"},
	# Pockets
	"perk:corner": {"sym": "Cr", "stat": "+0.5 Chain", "letter": "corner"},
	"perk:side": {"sym": "Sd", "stat": "×2", "letter": "door"},
	"perk:jaws": {"sym": "W", "stat": "+12% wider", "letter": "jaws"},
	"perk:heat": {"sym": "Sc", "stat": "Hot ×3, +30", "letter": "scorch"},
	"perk:magnet": {"sym": "Mg", "stat": "Pulls balls in", "letter": "magnet"},
	"perk:collector": {"sym": "Gt", "stat": "+0.5 per pocket", "letter": "tour"},
	# Ball numbers
	"perk:odd": {"sym": "Os", "stat": "Odd +20", "letter": "odd"},
	"perk:even": {"sym": "Ev", "stat": "+0.75 Chain", "letter": "even"},
	"perk:prime": {"sym": "Pr", "stat": "Primes ×2", "letter": "cut"},
	"perk:fibonacci": {"sym": "Lu", "stat": "+35", "letter": "spiral"},
	"perk:rotation": {"sym": "Rn", "stat": "Low = high", "letter": "rotate"},
	"perk:moneyball": {"sym": "Bi", "stat": "Numbers ×3", "letter": "tall"},
	# Solids
	"perk:solids": {"sym": "S", "stat": "+35", "letter": "plate"},
	"perk:solidgold": {"sym": "Sg", "stat": "$1 each", "letter": "ingot"},
	"perk:bedrock": {"sym": "Be", "stat": "+1 Heat", "letter": "strata"},
	"perk:steadyrun": {"sym": "Sr", "stat": "+12 per solid", "letter": "steps"},
	"perk:solidsonly": {"sym": "So", "stat": "×3 / ×0.5", "letter": "only"},
	"perk:lastsolid": {"sym": "Ld", "stat": "×8", "letter": "spotlight"},
	"perk:lowball": {"sym": "Lb", "stat": "1–3: +45", "letter": "limbo"},
	# Stripes
	"perk:stripes": {"sym": "St", "stat": "×1.5", "letter": "band"},
	"perk:racing": {"sym": "Rg", "stat": "60%+: ×2", "letter": "racing"},
	"perk:luckystripe": {"sym": "Li", "stat": "1 in 3: ×3", "letter": "clover"},
	"perk:tiger": {"sym": "Ti", "stat": "+0.25 Chain", "letter": "tiger"},
	"perk:stripesonly": {"sym": "Sy", "stat": "×2 / ×0.5", "letter": "pinstripe"},
	"perk:laststripe": {"sym": "Ls", "stat": "×5", "letter": "laststripe"},
	"perk:highball": {"sym": "Hr", "stat": "13–15: ×2.5", "letter": "dice"},
	# The 8-ball
	"perk:eight": {"sym": "Bh", "stat": "8 safe, $3", "letter": "behind"},
	"perk:darkhorse": {"sym": "Dh", "stat": "8 pays ×8", "letter": "dark"},
	"perk:hushmoney": {"sym": "Hm", "stat": "8 costs $3", "letter": "hush"},
	"perk:kissblack": {"sym": "Kb", "stat": "+0.75 Chain", "letter": "kiss"},
	"perk:steerclear": {"sym": "Ce", "stat": "+0.75 Chain", "letter": "steer"},
	"perk:lastcall": {"sym": "Lc", "stat": "×5 and $5", "letter": "neon"},
	"perk:eightcount": {"sym": "Ec", "stat": "Every 8th ×3", "letter": "tally"},
	"perk:trouble": {"sym": "Tb", "stat": "+3 Heat", "letter": "hazard"},
	# Banks & cushions
	"perk:bank": {"sym": "Bk", "stat": "+1/cushion", "letter": "banknote"},
	"perk:ricochet": {"sym": "Re", "stat": "+0.25/rail", "letter": "ricochet"},
	"perk:cushion": {"sym": "Ra", "stat": "+30", "letter": "pillow"},
	"perk:geometry": {"sym": "Ge", "stat": "×1.5/rail", "letter": "angles"},
	"perk:tracer": {"sym": "Tc", "stat": "Cue +0.25", "letter": "trace"},
	# Utility
	"perk:lever": {"sym": "Ga", "stat": "Long ×1.5", "letter": "long"},
	"perk:chalk": {"sym": "Ca", "stat": "+1 Chalk", "letter": "chalky"},
	"perk:lens": {"sym": "Ln", "stat": "Long +1 Chain", "letter": "lens"},
	"perk:insurance": {"sym": "In", "stat": "2 free misses", "letter": "shield"},
	"perk:oracle": {"sym": "Si", "stat": "See the score", "letter": "eye"},
	# Economy
	"perk:gold": {"sym": "Gd", "stat": "$1 a sink", "letter": "rail"},
	"perk:thrift": {"sym": "Th", "stat": "+$5", "letter": "tag"},
	"perk:venture": {"sym": "Pd", "stat": "+0.25 per $5", "letter": "deep"},
	"perk:hunter": {"sym": "Sh", "stat": "Bets ×2", "letter": "hustle"},
	"perk:overflow": {"sym": "O", "stat": "Carry 25%", "letter": "beaker"},
	# Risk & scaling
	"perk:catalyst": {"sym": "Sb", "stat": "+0.75 each", "letter": "snowball"},
	"perk:golden": {"sym": "Fl", "stat": "First ×2", "letter": "drip"},
	"perk:glasscannon": {"sym": "Al", "stat": "×2, −2 Chalk", "letter": "chips"},
	"perk:echo": {"sym": "Db", "stat": "Pays twice", "letter": "double"},
	# Clearing your set
	"perk:thinrack": {"sym": "Tn", "stat": "+12 each", "letter": "thin"},
	"perk:missing": {"sym": "Mn", "stat": "+0.5 each", "letter": "missing"},
	"perk:cleanhouse": {"sym": "Ch", "stat": "Free", "letter": "clean"},
	# Gear, imbues, special balls
	"perk:packrat": {"sym": "Pa", "stat": "+2 slots", "letter": "slots"},
	"perk:quartermaster": {"sym": "Qm", "stat": "Items −$1", "letter": "stencil"},
	"perk:tinkerer": {"sym": "Te", "stat": "Free consumable", "letter": "cog"},
	"perk:enchanter": {"sym": "Er", "stat": "Imbues −$2", "letter": "enchant"},
	"perk:secondcoat": {"sym": "Co", "stat": "Imbued ×1.5", "letter": "coat"},
	"perk:goldrush": {"sym": "Ru", "stat": "Specials ×2", "letter": "nuggets"},
	"perk:menagerie": {"sym": "Me", "stat": "+0.25 each", "letter": "menagerie"},
	"perk:alchemy": {"sym": "Am", "stat": "+1 special", "letter": "transmute"},
	# Pausing
	"perk:stillness": {"sym": "Sl", "stat": "+0.5 a pause", "letter": "still"},
	"perk:quickhands": {"sym": "Qh", "stat": "1 free use", "letter": "blur"},
	"perk:afterimage": {"sym": "Ag", "stat": "+1 Chain", "letter": "chroma"},
	"perk:overclock": {"sym": "Oc", "stat": "2 charges", "letter": "chip"},
	# Samples of the other kinds
	"imbue:vein": {"sym": "Vn", "stat": "+20, spreads", "letter": "mirror"},
	"ball:gold": {"sym": "Au", "stat": "45 pts", "on": "Cushions", "letter": "gold"},
	"item:secondstrike": {"sym": "Ss", "stat": "Hit again", "on": "Cue ball", "letter": "echo"},
	"item:trapdoor": {"sym": "Td", "stat": "+1 pocket", "on": "Cushion", "letter": "drop"},
}
const WHEN_SHORT := {"setup": "While aiming", "pause": "While paused", "after": "After a shot", "any": "Any time"}
const PAPER := Color(0.97, 0.95, 0.9)

## Which text carries the lettering effect: "symbol" (chosen) or "name". The
## other is plain. "name" is kept for comparison in tools/tile_preview.gd.
static var effects_on := "symbol"

var kind := ""   # perk, imbue, ball, item
var id := ""
var ball := 0    # imbues: which numbered ball
var tint := Color.WHITE
var data := {}
var motif := ""


static func has_tile(k: String, i: String) -> bool:
	return TILES.has(k + ":" + i)


func setup(k: String, i: String, b := 0) -> TileArt:
	kind = k
	id = i
	ball = b
	data = TILES.get(k + ":" + i, {"sym": "?", "stat": ""})
	match k:
		"perk":
			tint = IconArt.FAMILY_COLORS.get(Catalog.PERKS[i].get("fam", "utility"), Color.WHITE)
			motif = IconArt.motif_for(i)
		"imbue":
			tint = Catalog.IMBUES[i].color
		"ball":
			var bt: Dictionary = Catalog.BALL_TYPES[i]
			tint = bt.color if (bt.color as Color).get_luminance() > 0.3 else bt.accent
			motif = bt.motif
		"item":
			tint = Catalog.WHEN_COLORS[Catalog.ITEMS[i].when]
			motif = IconArt.motif_for(i)
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var recipe: String = data.get("letter", "")
	if effects_on == "symbol":
		add_child(Lettering.new(data.sym, recipe, tint, 46, 74.0, PAPER))
	else:
		add_child(Lettering.new(_name(), recipe, tint, 14, 93.0, tint.lerp(Color.WHITE, 0.55)))
	return self


## Draws text left (align -1), centred (0) or right (1) of pos; returns its width.
func _text(f: Font, txt: String, pos: Vector2, fs: int, col: Color, align := 0) -> float:
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x := pos.x - (w * 0.5 if align == 0 else (w if align > 0 else 0.0))
	draw_string(f, Vector2(x, pos.y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	return w


func _draw() -> void:
	var w := size.x
	var box := StyleBoxFlat.new()
	box.bg_color = tint.darkened(0.82)
	box.border_color = Color(tint, 0.9)
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	draw_rect(Rect2(2, 34, w - 4, 48), Color(tint, 0.07))
	var light := tint.lerp(Color.WHITE, 0.55)
	# Top left: card kind, then rarity / timing / duration.
	_text(F_SEMI, _kind_name().to_upper(), Vector2(9, 16), 11, light, -1)
	var sub := _sub()
	_text(F_REG, sub[0], Vector2(9, 29), 10, sub[1], -1)
	# Top right: motif, or for imbues the ball it goes on.
	if kind == "imbue":
		_mini_ball(Vector2(w - 20, 19), 10.0)
	elif motif != "":
		IconArt.paint(self, motif, Vector2(w - 20, 20), 0.27, tint, tint.darkened(0.82), F_SEMI, 1.7)
	# Symbol and name: whichever does not carry the effect is drawn plain here.
	if effects_on == "symbol":
		_text(F_SEMI, _name(), Vector2(w * 0.5, 93), 14, light)
	else:
		_text(F_SEMI, data.sym, Vector2(w * 0.5, 74), 46, PAPER)
	# Bottom row: effect left, what it acts on right.
	draw_line(Vector2(8, 101), Vector2(w - 8, 101), Color(tint, 0.25), 1.0)
	var on_w := _text(F_REG, _acts_on().to_upper(), Vector2(w - 9, 113), 10, light, 1)
	_text(F_SEMI, data.stat, Vector2(9, 113), stat_size(data.stat, on_w), tint, -1)


## The headline effect's font size: 12, or down to 10 when it would otherwise
## run into what it acts on (on_w wide) at the right.
static func stat_size(stat: String, on_w: float) -> int:
	var fs := 12
	while fs > 10 and F_SEMI.get_string_size(stat, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + on_w > SIZE.x - 26:
		fs -= 1
	return fs


func _kind_name() -> String:
	match kind:
		"perk": return "Perk"
		"imbue": return "Imbue"
		"ball": return "Special ball"
		"item": return "Tool" if Catalog.ITEMS[id].kind == "tool" else "Consumable"
	return ""


## The second line, top left, and its colour.
func _sub() -> Array:
	var dim := Color(tint.lerp(Color.WHITE, 0.55), 0.75)
	match kind:
		"perk":
			var r: int = Catalog.PERKS[id].r
			return [Catalog.rarity_name(r), Catalog.rarity_color(r)]
		"imbue":
			return ["Whole run", dim]
		"ball":
			return ["Joins your set", dim]
		"item":
			var it: Dictionary = Catalog.ITEMS[id]
			var when: String = WHEN_SHORT[it.when]
			return [when + (" · 1 per table" if it.kind == "tool" else " · 1 use"), dim]
	return ["", dim]


func _acts_on() -> String:
	match kind:
		"perk": return Catalog.family_name(id)
		"imbue": return "%d-ball" % ball
	return data.get("on", "")


func _name() -> String:
	match kind:
		"perk": return Catalog.PERKS[id].name
		"imbue": return "%s %d-ball" % [Catalog.IMBUES[id].name, ball]
		"ball": return Catalog.BALL_TYPES[id].name + " ball"
		"item": return Catalog.ITEMS[id].name
	return id


## The imbued ball, small, ringed in the imbue colour.
func _mini_ball(c: Vector2, r: float) -> void:
	draw_arc(c, r + 2.5, 0, TAU, 28, tint, 1.6, true)
	var col := Catalog.ball_color(ball)
	if Catalog.is_stripe(ball):
		draw_circle(c, r, Color(0.95, 0.93, 0.88))
		draw_rect(Rect2(c + Vector2(-r + 1, -r * 0.5), Vector2(r * 2 - 2, r)), col)
	else:
		draw_circle(c, r, col)
	draw_circle(c, r * 0.55, Color(0.97, 0.95, 0.9))
	_text(F_SEMI, str(ball), c + Vector2(0, 3.5), 9, Color(0.06, 0.06, 0.08))


## Text on a tile drawn with the card's own lettering effect: the name (14px)
## or, with TileArt.effects_on = "symbol", the big symbol (46px). Every card
## uses the same font; the effect is what makes each one unique. Offsets scale
## with the text size (s = 1 for the name, u = 1 for the symbol).
##   door    the last word (or letter) swings open on a hinge (Side Door)
##   mirror  a faint upside-down reflection below, as on a polished surface
##   gold    metal gradient with a dark edge and a glint sweeping across
##   echo    faded copies trailing behind, like a second hit
##   drop    the end of the word slips down, as if through a trapdoor
## The perks' effects are the _r_<name> methods further down, one per perk,
## each drawing something from what the perk does. Letters drawn in INK are
## painted by the fill shader with that effect's pattern (see _fill_for).
class Lettering extends Control:
	static var _gold_shader: Shader
	static var _fill_shader: Shader
	## Letters drawn in exactly this colour are painted by the fill shader.
	const INK := Color(1, 1, 1)
	## Sparkles: nearly white, but never INK.
	const SPARK := Color(1, 1, 0.94)
	const EIGHT_BLACK := Color(0.05, 0.05, 0.06)

	var text := ""
	var recipe := ""
	var tint := Color.WHITE
	var colour := Color.WHITE
	var fs := 14
	var baseline := 93.0
	var s := 1.0
	var u := 1.0      # 1 at the symbol's 46px
	var cap := 10.0   # capital height
	var xh := 7.0     # lower-case height
	var bg := Color.BLACK   # the tile behind the text, for cut-outs
	var fill := []
	var font: Font = TileArt.F_SEMI
	# The text's box, set at the start of each draw.
	var x0 := 0.0
	var x1 := 0.0
	var top := 0.0
	var cx := 0.0
	var cy := 0.0

	func _init(t: String, r: String, tile_tint: Color, size_px: int, base_y: float, col: Color) -> void:
		text = t
		recipe = r
		tint = tile_tint
		fs = size_px
		baseline = base_y
		colour = col
		s = fs / 14.0
		u = fs / 46.0
		cap = fs * 0.7
		xh = fs * 0.52
		var base := tile_tint.darkened(0.82)
		bg = base.lerp(tile_tint, 0.07) if base_y < 82.0 else base
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill = _fill_for(recipe)
		if recipe == "gold":
			material = _gold_material()
		elif not fill.is_empty():
			material = _fill_material()

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _col() -> Color:
		return colour

	## The colour for the main letters: INK when a fill paints them.
	func _ink() -> Color:
		return INK if not fill.is_empty() else colour

	func _width(t: String) -> float:
		return font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x

	func _draw() -> void:
		var pos := Vector2(size.x * 0.5 - _width(text) * 0.5, baseline)
		x0 = pos.x
		x1 = pos.x + _width(text)
		top = baseline - cap
		cx = size.x * 0.5
		cy = baseline - cap * 0.5
		match recipe:
			"door":
				_door()
			"mirror":
				# Mirror line, then the reflection squashed and flipped below it.
				# The big symbol sits a little higher to leave its reflection room.
				var squash := 0.5
				if s >= 1.5:
					squash = 0.3
					pos.y -= 8.0
				var floor_y := pos.y + 2.0
				draw_line(Vector2(pos.x - 4 * s, floor_y), Vector2(pos.x + _width(text) + 4 * s, floor_y), Color(tint, 0.35), maxf(1.0, s * 0.6))
				draw_set_transform(Vector2(0, floor_y + 1.0), 0.0, Vector2(1, -squash))
				draw_string(font, Vector2(pos.x, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(_col(), 0.25))
				draw_set_transform(Vector2.ZERO)
				draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _col())
			"gold":
				# Black marks the edge; the shader turns it dark gold.
				draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(3 * s), Color(0, 0, 0, 1))
				draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
			"echo":
				draw_string(font, pos - Vector2(10, 0) * minf(s, 1.6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(tint, 0.18))
				draw_string(font, pos - Vector2(5, 0) * minf(s, 1.6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(tint, 0.4))
				draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _col())
			"drop":
				var x := pos.x
				var n := text.length()
				for i in n:
					var ch := text[i]
					var k := float(i - n / 2 + 1)
					if k <= 0.0:
						draw_char(font, Vector2(x, pos.y), ch, fs, _col())
					else:
						var fall := 1.6 if s < 1.5 else 2.6   # the big symbol drops further
						draw_char(font, Vector2(x, pos.y + k * fall * s), ch, fs, Color(_col(), 1.0 - k * 0.16))
					x += font.get_char_size(ch.unicode_at(0), fs).x
			_:
				if has_method("_r_" + recipe):
					call("_r_" + recipe)
				else:
					draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _col())

	## The front part stands normally; the last word (or, with no space, the
	## last letter) is squeezed and sloped as if swung away on a hinge at its
	## left edge, and a little in shadow.
	func _door() -> void:
		var split := text.rfind(" ") + 1
		if split == 0:
			split = text.length() - 1
		var front := text.substr(0, split)
		var back := text.substr(split)
		var squeeze := 0.8
		var total := _width(front) + _width(back) * squeeze
		var x := size.x * 0.5 - total * 0.5
		draw_string(font, Vector2(x, baseline), front, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _col())
		var hinge := Vector2(x + _width(front) + 1.5 * s, baseline)
		draw_line(hinge + Vector2(-1, 2), hinge + Vector2(-1, -12 * s), Color(tint, 0.6), 1.2 * s)
		draw_set_transform_matrix(Transform2D(Vector2(squeeze, -0.09), Vector2(0, 1), hinge))
		draw_string(font, Vector2.ZERO, back, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _col().darkened(0.2))
		draw_set_transform(Vector2.ZERO)

	# --- Drawing helpers ------------------------------------------------------

	## The whole text at its place, moved by off.
	func _text_at(col: Color, off := Vector2.ZERO) -> void:
		draw_string(font, Vector2(x0, baseline) + off, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

	## An outline round the whole text, px wide.
	func _edge(col: Color, px: float, off := Vector2.ZERO) -> void:
		draw_string_outline(font, Vector2(x0, baseline) + off, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(1, roundi(px)), col)

	## The letters laid out centred, spacing apart and stretched sx wide:
	## [{ch, x, w (as laid out), w0 (natural)}].
	func _layout(spacing := 0.0, sx := 1.0) -> Array:
		var out := []
		var total := 0.0
		for i in text.length():
			var ch := text[i]
			var w0 := font.get_char_size(ch.unicode_at(0), fs).x
			out.append({"ch": ch, "w": w0 * sx, "w0": w0, "x": 0.0})
			total += w0 * sx
		total += spacing * maxf(0.0, text.length() - 1)
		var x := size.x * 0.5 - total * 0.5
		for g: Dictionary in out:
			g.x = x
			x += g.w + spacing
		return out

	## The height of a letter: capitals and ascenders reach cap, the rest xh.
	func _gh(ch: String) -> float:
		return cap if ch == ch.to_upper() or "bdfhklt".contains(ch) else xh

	## The top of the letter over x, or of the text.
	func _top_at(x: float) -> float:
		for g: Dictionary in _layout():
			if x >= g.x and x <= g.x + g.w:
				return baseline - _gh(g.ch)
		return top

	## One letter of a _layout(), moved by off and turned, scaled and sheared
	## about a pivot pv of the way up its height (0.5 its centre, 0 its foot).
	func _put(g: Dictionary, col: Color, off := Vector2.ZERO, rot := 0.0, sc := Vector2.ONE, skew := 0.0, bold := 0.0, pv := 0.5) -> void:
		var h := _gh(g.ch)
		var w0: float = g.w0
		var c := Vector2(g.x + g.w * 0.5, baseline - h * pv) + off
		draw_set_transform_matrix(Transform2D(rot, sc, skew, c) * Transform2D(0.0, Vector2(-w0 * 0.5, h * pv)))
		if bold > 0.0:
			draw_char_outline(font, Vector2.ZERO, g.ch, fs, maxi(1, roundi(bold)), col)
		draw_char(font, Vector2.ZERO, g.ch, fs, col)
		draw_set_transform_matrix(Transform2D.IDENTITY)

	## A filled polygon, its edge smoothed when it is opaque.
	func _poly(pts: PackedVector2Array, col: Color) -> void:
		draw_colored_polygon(pts, col)
		if col.a > 0.9:
			var ring := pts.duplicate()
			ring.append(pts[0])
			draw_polyline(ring, col, 1.0, true)

	func _oval(c: Vector2, rx: float, ry: float, n := 32) -> PackedVector2Array:
		return _oval_arc(c, rx, ry, 0.0, TAU * (n - 1.0) / n, n)

	func _oval_arc(c: Vector2, rx: float, ry: float, a0: float, a1: float, n := 24) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in n:
			var a := lerpf(a0, a1, i / (n - 1.0))
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		return pts

	func _oval_line(c: Vector2, rx: float, ry: float, col: Color, w: float) -> void:
		var pts := _oval(c, rx, ry)
		pts.append(pts[0])
		draw_polyline(pts, col, w, true)

	## Points turned by ang about c.
	func _turned(pts: PackedVector2Array, c: Vector2, ang: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p in pts:
			out.append(c + (p - c).rotated(ang))
		return out

	## A solid arrowhead with its tip at tip, pointing along dir.
	func _head(tip: Vector2, dir: Vector2, sz: float, col: Color) -> void:
		var d := dir.normalized()
		var n := d.orthogonal()
		_poly(PackedVector2Array([tip + d * sz * 0.4, tip - d * sz * 0.6 + n * sz * 0.5, tip - d * sz * 0.6 - n * sz * 0.5]), col)

	## A dashed line along pts.
	func _dashes(pts: PackedVector2Array, col: Color, w: float, dash: float, gap: float) -> void:
		var on := true
		var left := dash
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var seg := a.distance_to(b)
			var d := 0.0
			while d < seg - 0.001:
				var step := minf(left, seg - d)
				if on:
					draw_line(a.lerp(b, d / seg), a.lerp(b, (d + step) / seg), col, w, true)
				d += step
				left -= step
				if left <= 0.001:
					on = not on
					left = dash if on else gap

	## A four-pointed sparkle.
	func _star(c: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 8:
			var a := -PI * 0.5 + PI * 0.25 * i
			pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.3))
		_poly(pts, col)

	## A rounded rectangle, filled or (border > 0) outlined.
	func _rr(r: Rect2, radius: float, col: Color, border := 0.0) -> void:
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(maxi(0, roundi(radius)))
		if border > 0.0:
			sb.draw_center = false
			sb.border_color = col
			sb.set_border_width_all(maxi(1, roundi(border)))
		else:
			sb.bg_color = col
		draw_style_box(sb, r)

	## A flame tongue rising h from base, hw wide each side.
	func _flame(base: Vector2, hw: float, h: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 9:
			var t := i / 8.0
			pts.append(Vector2(base.x - hw * pow(1.0 - t, 0.8) + t * t * 1.5 * u, base.y - h * t))
		for i in range(7, -1, -1):
			var t := i / 8.0
			pts.append(Vector2(base.x + hw * pow(1.0 - t, 0.8) + t * t * 1.5 * u, base.y - h * t))
		for i in range(1, 8):
			var a := PI * i / 8.0
			pts.append(base + Vector2(cos(a) * hw, sin(a) * hw * 0.8))
		draw_colored_polygon(pts, col)

	# --- Fills ------------------------------------------------------------------

	## The pattern the fill shader paints on INK letters, per effect:
	## [mode, a, b, c, p1, p2] (see FILL_CODE). Empty for none.
	func _fill_for(r: String) -> Array:
		var lt := tint.lerp(colour, 0.5)
		match r:
			"velvet": return [0, colour, tint.lerp(colour, 0.45)]
			"brake": return [3, colour, colour.darkened(0.2), colour, 3.0 * u, 0.5]
			"spin": return [0, colour.lerp(Color.WHITE, 0.7), tint.lerp(colour, 0.5)]
			"sketch": return [3, colour, Color(colour, 0.0), colour, 3.2 * u, 0.5]
			"stoke": return [0, colour, Color(1, 0.5, 0.22)]
			"stub": return [9, colour, colour, colour, 1.0, 0.38]
			"simmer": return [0, colour, Color(1, 0.66, 0.36)]
			"glow": return [0, Color(1, 0.95, 0.84), Color(1, 0.78, 0.5)]
			"frost": return [0, Color(0.95, 0.99, 1), Color(0.55, 0.8, 1)]
			"inferno": return [8, Color(1, 0.36, 0.12), Color(1, 0.72, 0.22), Color(1, 0.96, 0.74)]
			"scorch": return [0, colour, Color(0.6, 0.27, 0.1)]
			"strata": return [7, Color(0.95, 0.87, 0.68), Color(0.84, 0.6, 0.4), Color(0.62, 0.57, 0.56)]
			"spotlight": return [0, Color(1, 1, 0.94), lt]
			"band": return [4, colour, tint, colour, 8.0, 0.42]
			"racing": return [11, colour, tint.darkened(0.1)]
			"clover": return [3, colour, tint.lerp(colour, 0.35), colour, 9.0 * u, 0.3]
			"tiger": return [6, Color(1, 0.74, 0.32), Color(0.42, 0.2, 0.05), colour, 13.0 * u, 0.68]
			"pinstripe": return [2, colour, tint, colour, 4.5 * u, 0.3]
			"banknote": return [2, colour, colour.darkened(0.3), colour, 2.4 * u, 0.35]
			"trace": return [12, colour, colour, colour, 4.0 * u, 0.4]
			"chalky": return [5, Color(0.62, 0.8, 1.0), colour, colour, 2.0 * u, 0.3]
			"rail": return [0, colour, Color(1, 0.84, 0.45)]
			"deep": return [9, colour, colour, colour, -1.0, 0.18]
			"beaker": return [0, colour, tint.lerp(colour, 0.35)]
			"drip": return [0, colour, Color(1, 0.5, 0.5)]
			"clean": return [13, colour, Color(1, 1, 1), colour, 0.0, 0.45]
			"stencil": return [0, tint.lerp(colour, 0.7), tint.lerp(colour, 0.3)]
			"enchant": return [0, colour, Color(0.86, 0.72, 1.0)]
			"coat": return [0, colour, lt]
			"nuggets": return [0, Color(1, 0.93, 0.6), Color(0.86, 0.56, 0.12)]
			"transmute": return [1, Color(0.64, 0.66, 0.72), Color(1, 0.82, 0.3)]
			"chip": return [10, tint.lerp(colour, 0.7), tint.lerp(colour, 0.25), colour, 3.0 * u, 0.55]
		return []

	const FILL_CODE := """
shader_type canvas_item;
// Paints only pixels drawn in pure white (Lettering.INK); all else passes.
uniform int mode = 0;
uniform vec4 a : source_color = vec4(1.0);
uniform vec4 b : source_color = vec4(1.0);
uniform vec4 c : source_color = vec4(1.0);
uniform float top = 0.0;
uniform float bottom = 1.0;
uniform float left = 0.0;
uniform float right = 1.0;
uniform float p1 = 8.0;
uniform float p2 = 0.5;
varying vec2 lp;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void vertex() { lp = VERTEX; }
void fragment() {
	if (COLOR.r > 0.999 && COLOR.g > 0.999 && COLOR.b > 0.999) {
		float ty = clamp((lp.y - top) / (bottom - top), 0.0, 1.0);
		float tx = clamp((lp.x - left) / (right - left), 0.0, 1.0);
		vec4 col = a;
		if (mode == 0) { col = mix(a, b, ty); }                                   // a top, b bottom
		else if (mode == 1) { col = mix(a, b, tx); }                              // a left, b right
		else if (mode == 2) { col = mod(lp.y - top, p1) < p1 * p2 ? b : a; }      // level stripes
		else if (mode == 3) { col = mod(lp.x + lp.y, p1) < p1 * p2 ? b : a; }     // slanted stripes
		else if (mode == 4) { col = abs(ty - 0.5) < p2 * 0.5 ? b : a; }           // a stripe-ball band
		else if (mode == 5) { if (hash(floor(lp / p1)) < p2) { col.a *= 0.3; } }  // chalky speckle
		else if (mode == 6) {                                                     // tiger stripes
			float w = sin((lp.x - left) * 6.2832 / p1 + sin(lp.y * 0.3) * 1.3 + ty * 2.0);
			col = w > p2 ? b : a;
		}
		else if (mode == 7) {                                                     // rock layers
			float y = ty + 0.07 * sin(lp.x * 0.22);
			col = y < 0.36 ? a : (y < 0.68 ? b : c);
		}
		else if (mode == 8) {                                                     // flame
			float y = ty + 0.09 * sin(lp.x * 0.45 + ty * 6.0);
			col = y < 0.5 ? mix(a, b, y * 2.0) : mix(b, c, (y - 0.5) * 2.0);
		}
		else if (mode == 9) {                                                     // worn away (p1 > 0: top, < 0: bottom)
			float t = p1 > 0.0 ? ty : 1.0 - ty;
			col.a *= smoothstep(p2 - 0.2, p2 + 0.25, t);
		}
		else if (mode == 10) { col = mod(lp.y, p1) < p1 * p2 ? a : b; }           // screen lines
		else if (mode == 11) { col = (abs(tx - 0.4) < 0.055 || abs(tx - 0.6) < 0.055) ? b : a; } // racing stripes
		else if (mode == 12) { if (mod(lp.x + lp.y * 0.6, p1) < p1 * p2) { col.a = 0.0; } }      // dashes
		else if (mode == 13) {                                                    // a sheen across
			float d = tx - (1.0 - ty) * 0.35 - p2;
			col = mix(a, b, smoothstep(0.12, 0.0, abs(d)));
		}
		COLOR = vec4(col.rgb, col.a * COLOR.a);
	}
}
"""

	func _fill_material() -> ShaderMaterial:
		if _fill_shader == null:
			_fill_shader = Shader.new()
			_fill_shader.code = FILL_CODE
		var m := ShaderMaterial.new()
		m.shader = _fill_shader
		var w := _width(text)
		var l := TileArt.SIZE.x * 0.5 - w * 0.5
		m.set_shader_parameter("mode", fill[0])
		m.set_shader_parameter("a", fill[1])
		m.set_shader_parameter("b", fill[2] if fill.size() > 2 else fill[1])
		m.set_shader_parameter("c", fill[3] if fill.size() > 3 else fill[1])
		m.set_shader_parameter("p1", fill[4] if fill.size() > 4 else 8.0)
		m.set_shader_parameter("p2", fill[5] if fill.size() > 5 else 0.5)
		m.set_shader_parameter("top", baseline - cap)
		m.set_shader_parameter("bottom", baseline)
		m.set_shader_parameter("left", l)
		m.set_shader_parameter("right", l + w)
		return m

	# --- Perks: Physics -----------------------------------------------------------

	## Velvet Cloth: a soft nap of colour all round.
	func _r_velvet() -> void:
		for i in 12:
			var a := TAU * i / 12.0
			_text_at(Color(tint, 0.07), Vector2(cos(a), sin(a)) * 2.8 * u)
		_text_at(_ink())

	## Featherweight: floating free of its own shadow, drifting.
	func _r_feather() -> void:
		_poly(_oval(Vector2(cx, baseline + 4 * u), (x1 - x0) * 0.42, 2.2 * u), Color(0, 0, 0, 0.3))
		var gl := _layout(2 * u)
		for i in gl.size():
			_put(gl[i], _ink(), Vector2(0, -6 * u - 2 * u * i), deg_to_rad(-9 + 9 * i))
		for k in 2:
			var c := Vector2(x0 - (9 + 3 * k) * u, top + (6 + 11 * k) * u)
			draw_arc(c, 5 * u, PI * 0.15, PI * 0.85, 10, Color(tint, 0.55 - 0.2 * k), 1.4 * u, true)

	## Heavy Hitter: squat, bold letters bowing the line they stand on.
	func _r_heavy() -> void:
		var gl := _layout(2 * u, 1.12)
		var a: float = gl[0].x - 9 * u
		var b: float = gl[-1].x + gl[-1].w + 9 * u
		var pts := PackedVector2Array()
		for i in 13:
			var t := i / 12.0
			pts.append(Vector2(lerpf(a, b, t), baseline + 3 * u + sin(t * PI) * 3.5 * u))
		draw_polyline(pts, Color(tint, 0.75), 2.4 * u, true)
		for g: Dictionary in gl:
			var t := clampf((g.x + g.w * 0.5 - a) / (b - a), 0.0, 1.0)
			_put(g, _ink(), Vector2(0, sin(t * PI) * 3.5 * u), 0.0, Vector2(1.12, 0.88), 0.0, 2.0 * u, 0.0)

	## Live Rails: hopping along a coiled spring.
	func _r_spring() -> void:
		var pts := PackedVector2Array()
		var n := 16
		for i in n + 1:
			pts.append(Vector2(lerpf(x0 - 7 * u, x1 + 7 * u, float(i) / n), baseline + 5 * u + (2.4 * u if i % 2 else -2.4 * u)))
		draw_polyline(pts, Color(tint, 0.7), 1.5 * u, true)
		var gl := _layout(2 * u)
		for i in gl.size():
			_put(gl[i], _ink(), Vector2(0, -7 * u if i % 2 else -1 * u), deg_to_rad(6 if i % 2 else -4))

	## Slow Cloth: cloth weave in tightly braked letters, skid marks behind.
	func _r_brake() -> void:
		for k in 3:
			var y := top + (8 + 9 * k) * u
			var l := (26 - 6 * k) * u
			draw_polyline_colors(PackedVector2Array([Vector2(x0 - 4 * u - l, y), Vector2(x0 - 3 * u, y)]), PackedColorArray([Color(tint, 0), Color(tint, 0.75)]), 2 * u, true)
		for g: Dictionary in _layout(-2.5 * u):
			_put(g, _ink())

	## Backspin Wax: a backspin arrow curling round behind waxed letters.
	func _r_spin() -> void:
		var pts := _oval_arc(Vector2(cx, cy), (x1 - x0) * 0.5 + 11 * u, cap * 0.5 + 7 * u, PI * 1.9, PI * 0.3, 40)
		draw_polyline(pts, Color(tint, 0.65), 2 * u, true)
		_head(pts[pts.size() - 1], pts[pts.size() - 1] - pts[pts.size() - 2], 6 * u, Color(tint, 0.9))
		_text_at(_ink())

	## Big Break: cracked through, with chips flying off.
	func _r_shatter() -> void:
		_text_at(_ink())
		var w := x1 - x0
		var crack := PackedVector2Array([Vector2(x0 + w * 0.28, top - 3 * u), Vector2(x0 + w * 0.4, top + cap * 0.3), Vector2(x0 + w * 0.32, top + cap * 0.55), Vector2(x0 + w * 0.48, top + cap * 0.78), Vector2(x0 + w * 0.44, baseline + 3 * u)])
		draw_polyline(crack, bg, 2.4 * u, true)
		draw_line(crack[2], crack[2] + Vector2(-7, 4) * u, bg, 1.6 * u, true)
		for sh in [[Vector2(x1 + 6 * u, top + 5 * u), 0.3, 3.4], [Vector2(x1 + 12 * u, top + 14 * u), -0.7, 2.6], [Vector2(x1 + 7 * u, baseline - 5 * u), 1.2, 2.2]]:
			var c: Vector2 = sh[0]
			var pts := PackedVector2Array()
			for k in 3:
				var a: float = sh[1] + [0.0, 2.3, 4.1][k]
				pts.append(c + Vector2(cos(a), sin(a)) * sh[2] * u * [1.0, 0.7, 0.9][k])
			_poly(pts, Color(tint, 0.85))

	## Long Arm: a long cue reaching in to letters leaning into the shot.
	func _r_reach() -> void:
		var tip := Vector2(x0 - 5 * u, cy + 2 * u)
		var butt := Vector2(9 * u, cy + 7 * u)
		var d := (tip - butt).normalized()
		var n := d.orthogonal()
		_poly(PackedVector2Array([butt + n * 2.6 * u, tip - d * 3 * u + n * 1.1 * u, tip - d * 3 * u - n * 1.1 * u, butt - n * 2.6 * u]), Color(colour, 0.6))
		_poly(PackedVector2Array([tip - d * 3 * u + n * 1.1 * u, tip + n * 1.1 * u, tip - n * 1.1 * u, tip - d * 3 * u - n * 1.1 * u]), Color(tint, 0.95))
		for g: Dictionary in _layout(1 * u):
			_put(g, _ink(), Vector2.ZERO, 0.0, Vector2.ONE, -0.16)

	# --- Perks: Cue control ---------------------------------------------------------

	## Kick Drum: on a drumhead, with the beat ringing out both sides.
	func _r_kick() -> void:
		_oval_line(Vector2(cx, baseline + 3 * u), (x1 - x0) * 0.5 + 10 * u, 3.5 * u, Color(tint, 0.65), 1.6 * u)
		for side in [-1.0, 1.0]:
			for k in 2:
				var c := Vector2(cx + side * ((x1 - x0) * 0.5 - 4 * u), cy)
				var a0 := 0.0 if side > 0 else PI
				draw_arc(c, (10 + 6 * k) * u, a0 - 0.34, a0 + 0.34, 10, Color(tint, 0.65 - 0.25 * k), 1.6 * u, true)
		_text_at(Color(colour, 0.22), Vector2(0, -2.5 * u))
		_text_at(_ink())

	## Power Stroke: bold, leaning hard into the shot, speed lines behind.
	func _r_power() -> void:
		for k in 3:
			var y := top + (7 + 9 * k) * u
			var l := (16 + 8 * (1 - absi(k - 1))) * u
			draw_line(Vector2(x0 - 6 * u - l, y), Vector2(x0 - 6 * u, y), Color(tint, 0.7), 2 * u, true)
		for g: Dictionary in _layout():
			_put(g, _ink(), Vector2.ZERO, 0.0, Vector2.ONE, -0.24, 1.6 * u)

	## Soft Touch: hollow letters in a soft glow, the lightest touch.
	func _r_soft() -> void:
		_edge(Color(tint, 0.12), 11 * u)
		_edge(Color(colour, 0.9), 4 * u)
		_text_at(bg)

	## Boomerang: a path leaves the letter, loops out and comes back to it.
	func _r_boomerang() -> void:
		var pts := _oval_arc(Vector2(x1 + 9 * u, cy), 13 * u, cap * 0.5 + 2 * u, -PI * 0.62, PI * 0.62, 28)
		_dashes(pts, Color(tint, 0.8), 1.6 * u, 4 * u, 3 * u)
		_head(pts[pts.size() - 1] + (pts[pts.size() - 1] - pts[pts.size() - 2]).normalized() * 2 * u, pts[pts.size() - 1] - pts[pts.size() - 2], 6 * u, Color(tint, 0.95))
		_text_at(_ink())

	## Clean Stroke: dead centre in a crosshair.
	func _r_crosshair() -> void:
		var c := Vector2(cx, cy)
		var r := cap * 0.64
		draw_arc(c, r, 0, TAU, 48, Color(tint, 0.5), 1.4 * u, true)
		for d: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			draw_line(c + d * (r - 5 * u), c + d * (r + (7 if d.y == 0 else 4) * u), Color(tint, 0.85), 1.6 * u, true)
		_text_at(_ink())

	## Stun Master: dazed, stars circling over the letters.
	func _r_stun() -> void:
		var c := Vector2(cx, top - 1 * u)
		var rx := (x1 - x0) * 0.45
		_dashes(_oval_arc(c, rx, 3.5 * u, 0, TAU, 40), Color(tint, 0.5), 1 * u, 2.5 * u, 2 * u)
		_text_at(_ink())
		for k in 3:
			var a := PI * (0.2 + 0.65 * k)
			_star(c + Vector2(cos(a) * rx, sin(a) * 3.5 * u), (4.2 - 0.6 * k) * u, SPARK)

	## Break Artist: letters splitting apart as the rack scatters.
	func _r_breakup() -> void:
		var c := Vector2(cx, cy)
		for d: Vector2 in [Vector2(-1, -0.8), Vector2(1, -0.9), Vector2(-1.25, 0.5), Vector2(1.3, 0.35), Vector2(0.1, -1.25)]:
			var p := c + Vector2(d.x * ((x1 - x0) * 0.5 + 9 * u), d.y * (cap * 0.5 + 2 * u))
			var dir := (p - c).normalized()
			draw_line(p - dir * 10 * u, p - dir * 4 * u, Color(tint, 0.45), 1.3 * u, true)
			draw_circle(p, 2.8 * u, Color(tint, 0.9), true, -1.0, true)
		var gl := _layout(5 * u)
		_put(gl[0], _ink(), Vector2(-2 * u, 0), deg_to_rad(-9))
		_put(gl[1], _ink(), Vector2(2 * u, 0), deg_to_rad(10))

	## Massé Master: letters riding the curve of a swerving cue ball.
	func _r_swerve() -> void:
		var gl := _layout(3 * u)
		var a := x0 - 8 * u
		var b := x1 + 12 * u
		var lift := func(x: float) -> float: return sin((x - a) / (b - a) * PI * 1.3 - 0.2) * 3.5 * u
		var pts := PackedVector2Array()
		for i in 25:
			var x := lerpf(a, b, i / 24.0)
			pts.append(Vector2(x, baseline + 3 * u - lift.call(x)))
		_dashes(pts, Color(tint, 0.7), 1.5 * u, 4 * u, 2.5 * u)
		draw_circle(pts[pts.size() - 1] + Vector2(3 * u, -1 * u), 3 * u, colour, true, -1.0, true)
		for g: Dictionary in gl:
			var x: float = g.x + g.w * 0.5
			var slope: float = (lift.call(x + 1.0) - lift.call(x - 1.0)) * 0.5
			_put(g, _ink(), Vector2(0, -lift.call(x)), -atan(slope))

	## Follow Through: carries on past the letters, dotted ahead.
	func _r_follow() -> void:
		var y := baseline - cap * 0.4
		var b := Vector2(x1 + 26 * u, y)
		_dashes(PackedVector2Array([Vector2(x1 + 4 * u, y), b]), Color(tint, 0.8), 1.8 * u, 2.5 * u, 2.5 * u)
		_head(b + Vector2(3 * u, 0), Vector2.RIGHT, 6 * u, Color(tint, 0.95))
		_text_at(_ink())

	## Draw Artist: pencil work, hatched and gone over twice in outline.
	func _r_sketch() -> void:
		_text_at(_ink())
		_edge(Color(colour, 0.85), 1.5 * u, Vector2(0.7, -0.5) * u)
		_edge(Color(colour, 0.45), 1.2 * u, Vector2(-0.8, 0.7) * u)
		var pts := PackedVector2Array()
		for i in 11:
			pts.append(Vector2(lerpf(x0 - 2 * u, x1 + 2 * u, i / 10.0), baseline + 5 * u + (1.3 * u if i % 2 else -1.3 * u)))
		draw_polyline(pts, Color(tint, 0.6), 1.3 * u, true)

	# --- Perks: Combos & clusters ---------------------------------------------------

	## Loud Table: sound waves rolling off the letters.
	func _r_loud() -> void:
		var c := Vector2(x1 + 1 * u, cy)
		for k in 3:
			draw_arc(c, (7 + 6 * k) * u, -0.95, 0.95, 16, Color(tint, 0.85 - 0.25 * k), 2 * u, true)
		_text_at(_ink())

	## Daisy Chain: hung on a chain with a daisy at its end.
	func _r_links() -> void:
		var y := baseline + 5 * u
		var x := x0 - 1 * u
		var i := 0
		while x < x1 + 4 * u:
			if i % 2 == 0:
				_oval_line(Vector2(x, y), 4.2 * u, 2.3 * u, Color(tint, 0.8), 1.3 * u)
			else:
				draw_line(Vector2(x - 3 * u, y), Vector2(x + 3 * u, y), Color(tint, 0.8), 1.6 * u, true)
			x += 6 * u
			i += 1
		var c := Vector2(x0 - 9 * u, y - 1 * u)
		for k in 6:
			var a := TAU * k / 6.0
			draw_circle(c + Vector2(cos(a), sin(a)) * 2.2 * u, 1.5 * u, Color(0.98, 0.96, 0.92), true, -1.0, true)
		draw_circle(c, 1.3 * u, Color(1, 0.8, 0.2), true, -1.0, true)
		_text_at(_ink())

	## Cluster: letters huddled with a little rack of balls.
	func _r_cluster() -> void:
		var c := Vector2(x1 + 1 * u, baseline - 4 * u)
		for p: Vector2 in [Vector2(0, 0), Vector2(7, 0), Vector2(3.5, -6)]:
			draw_circle(c + p * u, 3.4 * u, Color(tint, 0.6), true, -1.0, true)
		var gl := _layout(-3 * u)
		_put(gl[0], _ink(), Vector2(1 * u, 0), deg_to_rad(-6))
		_put(gl[1], _ink(), Vector2(-1 * u, -2 * u), deg_to_rad(8))

	## Clean Sweep: a broad sweep under letters leaning into it.
	func _r_sweep() -> void:
		var p0 := Vector2(x0 - 12 * u, baseline - 5 * u)
		var p1 := Vector2(cx - 6 * u, baseline + 13 * u)
		var p2 := Vector2(x1 + 15 * u, baseline - 16 * u)
		var upper := PackedVector2Array()
		var lower := PackedVector2Array()
		for i in 21:
			var t := i / 20.0
			var p := p0.lerp(p1, t).lerp(p1.lerp(p2, t), t)
			var th := pow(sin(t * PI), 0.8) * 2.2 * u
			upper.append(p - Vector2(0, th))
			lower.append(p + Vector2(0, th))
		lower.reverse()
		upper.append_array(lower)
		_poly(upper, Color(tint, 0.6))
		for g: Dictionary in _layout(1 * u):
			_put(g, _ink(), Vector2.ZERO, 0.0, Vector2.ONE, -0.12)

	## Same Pocket: two letters dropping into the one pocket.
	func _r_merge() -> void:
		var c := Vector2(cx, baseline + 3 * u)
		_poly(_oval(c, (x1 - x0) * 0.36, 4 * u), Color(0, 0, 0, 0.6))
		_oval_line(c, (x1 - x0) * 0.36, 4 * u, Color(tint, 0.55), 1.2 * u)
		var gl := _layout(-7 * u)
		_put(gl[0], _ink())
		_put(gl[1], tint.lerp(colour, 0.35))

	## Domino: toppling one after the other.
	func _r_topple() -> void:
		var gl := _layout(1 * u)
		_put(gl[0], _ink(), Vector2.ZERO, deg_to_rad(-3), Vector2.ONE, 0.0, 0.0, 0.0)
		_put(gl[1], _ink(), Vector2(-3 * u, 0), deg_to_rad(18), Vector2.ONE, 0.0, 0.0, 0.0)
		var foot := Vector2(gl[1].x + gl[1].w * 0.5, baseline)
		draw_arc(foot, xh + 5 * u, -PI * 0.5 + 0.1, -PI * 0.5 + 0.75, 10, Color(tint, 0.55), 1.4 * u, true)
		var r := Rect2(x1 + 7 * u, baseline - 5 * u, 15 * u, 5 * u)
		_rr(r, 1.2 * u, Color(tint, 0.85))
		draw_line(r.position + Vector2(r.size.x * 0.5, 1 * u), r.position + Vector2(r.size.x * 0.5, r.size.y - 1 * u), bg, 1 * u)
		for p: float in [0.25, 0.75]:
			draw_circle(r.position + Vector2(r.size.x * p, r.size.y * 0.5), 0.9 * u, bg, true, -1.0, true)

	# --- Perks: Streaks ---------------------------------------------------------------

	## Stoker: stoked to a glow, embers rising.
	func _r_stoke() -> void:
		_edge(Color(1, 0.45, 0.1, 0.2), 7 * u)
		_text_at(_ink())
		for e in [[0.08, 3, 1.6], [0.3, 7, 1.2], [0.52, 2, 1.8], [0.72, 6, 1.1], [0.92, 3, 1.4], [0.42, 9, 0.9]]:
			var x := lerpf(x0, x1, e[0])
			draw_circle(Vector2(x, _top_at(x) - e[1] * u), e[2] * u, Color(1, 0.62 + e[2] * 0.1, 0.2, 0.9), true, -1.0, true)

	## Rhythm: letters bobbing to a beat counted in threes.
	func _r_beat() -> void:
		var gl := _layout(1 * u)
		_put(gl[0], _ink(), Vector2(0, -3 * u))
		_put(gl[1], _ink())
		var bx := x1 + 6 * u
		for k in 3:
			var h := (16.0 if k == 2 else 7.0) * u
			_rr(Rect2(bx + k * 6 * u, baseline - h, 3.6 * u, h), 1.2 * u, Color(tint, 0.95 if k == 2 else 0.4))

	## Last Chalk: worn down to the stub, beside the last cube of chalk.
	func _r_stub() -> void:
		_text_at(_ink())
		var c := Vector2(x1 + 11 * u, baseline - 5 * u)
		var h := 5 * u
		_rr(Rect2(c - Vector2(h, h), Vector2(h, h) * 2), 1.2 * u, Color(0.42, 0.66, 0.98))
		_poly(_oval(c - Vector2(0, h - 1.6 * u), h * 0.6, 1.3 * u), Color(0.72, 0.86, 1.0))

	# --- Perks: Heat ------------------------------------------------------------------

	## Simmer: warming from below, bubbles rising.
	func _r_simmer() -> void:
		_text_at(_ink())
		for b in [[0.12, 3, 2.2], [0.32, 8, 1.4], [0.58, 4, 2.8], [0.8, 9, 1.6], [0.95, 3, 1.2]]:
			var x := lerpf(x0, x1, b[0])
			draw_arc(Vector2(x, _top_at(x) - b[1] * u), b[2] * u, 0, TAU, 16, Color(tint, 0.8), 1.1 * u, true)

	## Hot Hand: letters wavering in the heat haze.
	func _r_shimmer() -> void:
		var hot := Color(1, 0.55, 0.2)
		for side in [-1.0, 1.0]:
			for k in 2:
				var x := (x0 - (6 + 6 * k) * u) if side < 0 else (x1 + (6 + 6 * k) * u)
				var pts := PackedVector2Array()
				var cols := PackedColorArray()
				for i in 11:
					var t := i / 10.0
					pts.append(Vector2(x + sin(t * TAU * 1.3 + k * 1.7) * 1.8 * u, lerpf(baseline - 2 * u, top - 1 * u, t)))
					cols.append(Color(hot, 0.7 * (1.0 - t) * (1.0 - 0.35 * k)))
				draw_polyline_colors(pts, cols, 1.5 * u, true)
		var gl := _layout(1 * u)
		for i in gl.size():
			_put(gl[i], _ink(), Vector2(0, sin(i * 2.1) * 2 * u), 0.0, Vector2.ONE, 0.1 if i % 2 else -0.1)

	## Stay Hot: a steady glow that does not fade.
	func _r_glow() -> void:
		var hot := Color(1, 0.5, 0.15)
		_edge(Color(hot, 0.07), 16 * u)
		_edge(Color(hot, 0.12), 10 * u)
		_edge(Color(hot, 0.28), 5 * u)
		_text_at(_ink())

	## Cold Start: frosted letters with icicles hanging off.
	func _r_frost() -> void:
		_text_at(_ink())
		var ice := Color(0.75, 0.9, 1.0, 0.9)
		var i := 0
		for g: Dictionary in _layout():
			for f: float in [0.3, 0.72]:
				var x: float = g.x + g.w * f
				var l := (4.0 + 3.0 * (i % 2)) * u
				_poly(PackedVector2Array([Vector2(x - 1.5 * u, baseline - 1.5 * u), Vector2(x + 1.5 * u, baseline - 1.5 * u), Vector2(x, baseline + l)]), ice)
				i += 1
		var c := Vector2(x1 + 8 * u, top + 4 * u)
		for k in 3:
			var d := Vector2.from_angle(PI * k / 3.0) * 4.5 * u
			draw_line(c - d, c + d, ice, 1.2 * u, true)

	## Inferno: letters made of flame, tongues licking up behind.
	func _r_inferno() -> void:
		for g: Dictionary in _layout():
			for f: float in [0.28, 0.72]:
				var x: float = g.x + g.w * f
				_flame(Vector2(x, _top_at(x) + 7 * u), 3.8 * u, (12 + 5 * f) * u, Color(1, 0.42, 0.12, 0.6))
		_text_at(_ink())

	# --- Perks: Pockets ---------------------------------------------------------------

	## Corner Man: boxed into two corners, a pocket in one.
	func _r_corner() -> void:
		var col := Color(tint, 0.85)
		var a := Vector2(x0 - 8 * u, top - 5 * u)
		var b := Vector2(x1 + 8 * u, baseline + 5 * u)
		var arm := 12 * u
		draw_polyline(PackedVector2Array([a + Vector2(0, arm), a, a + Vector2(arm, 0)]), col, 2.2 * u, true)
		draw_polyline(PackedVector2Array([b - Vector2(0, arm), b, b - Vector2(arm, 0)]), col, 2.2 * u, true)
		draw_circle(a + Vector2(4, 4) * u, 3.2 * u, Color(0, 0, 0, 0.8), true, -1.0, true)
		_text_at(_ink())

	## Wide Jaws: stretched wide between open jaws.
	func _r_jaws() -> void:
		var gl := _layout(0.0, 1.3)
		var a: float = gl[0].x - 7 * u
		var b: float = gl[-1].x + gl[-1].w + 7 * u
		var n := 7
		var col := Color(tint, 0.85)
		for row in [[top - 4 * u, 1.0], [baseline + 4 * u, -1.0]]:
			var y: float = row[0]
			draw_line(Vector2(a, y), Vector2(b, y), col, 1.6 * u, true)
			for i in n:
				var xa := lerpf(a, b, float(i) / n)
				var xb := lerpf(a, b, float(i + 1) / n)
				_poly(PackedVector2Array([Vector2(xa, y), Vector2(xb, y), Vector2((xa + xb) * 0.5, y + row[1] * 4 * u)]), col)
		for g: Dictionary in gl:
			_put(g, _ink(), Vector2.ZERO, 0.0, Vector2(1.3, 1.0))

	## Scorcher: charred from below, smoke curling up.
	func _r_scorch() -> void:
		_poly(_oval(Vector2(cx, baseline + 1 * u), (x1 - x0) * 0.6, 4 * u), Color(0, 0, 0, 0.35))
		_text_at(_ink())
		for k in 2:
			var x := lerpf(x0, x1, 0.3 + 0.45 * k)
			var pts := PackedVector2Array()
			var cols := PackedColorArray()
			for i in 10:
				var t := i / 9.0
				pts.append(Vector2(x + sin(t * TAU * 0.9 + k * 2.0) * 2.5 * u + t * 4 * u, _top_at(x) - 1 * u - t * 7 * u))
				cols.append(Color(0.78, 0.75, 0.72, 0.65 * (1.0 - t)))
			draw_polyline_colors(pts, cols, 1.6 * u, true)

	## Magnetic Pockets: field lines pulling the letters toward a pocket.
	func _r_magnet() -> void:
		var p := Vector2(cx, baseline + 4 * u)
		for k in 3:
			draw_arc(p, (12 + 8 * k) * u, PI * 1.08, PI * 1.92, 24, Color(tint, 0.65 - 0.15 * k), 1.4 * u, true)
		draw_circle(p, 3.6 * u, Color(0, 0, 0, 0.85), true, -1.0, true)
		draw_arc(p, 3.6 * u, 0, TAU, 16, Color(tint, 0.85), 1.2 * u, true)
		var gl := _layout(3 * u)
		_put(gl[0], _ink(), Vector2(1.5 * u, 0), deg_to_rad(6), Vector2.ONE, 0.0, 0.0, 0.0)
		_put(gl[1], _ink(), Vector2(-1.5 * u, 0), deg_to_rad(-6), Vector2.ONE, 0.0, 0.0, 0.0)

	## Grand Tour: a dotted route past all six pockets.
	func _r_tour() -> void:
		var r := Rect2(x0 - 14 * u, top - 5 * u, x1 - x0 + 28 * u, cap + 10 * u)
		var loop := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position])
		_dashes(loop, Color(tint, 0.55), 1.2 * u, 3 * u, 2.5 * u)
		var mid := r.get_center().x
		for p: Vector2 in [r.position, Vector2(mid, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), Vector2(mid, r.end.y), r.end]:
			draw_circle(p, 3 * u, Color(0, 0, 0, 0.85), true, -1.0, true)
			draw_arc(p, 3 * u, 0, TAU, 14, Color(tint, 0.85), 1.1 * u, true)
		_text_at(_ink())

	# --- Perks: Ball numbers -----------------------------------------------------------

	## Odd Balls: one letter out of step with the other.
	func _r_odd() -> void:
		var gl := _layout(2 * u)
		_put(gl[0], _ink(), Vector2.ZERO, deg_to_rad(-9), Vector2(1.06, 1.06))
		_put(gl[1], tint.lerp(colour, 0.35), Vector2(1 * u, -6 * u), deg_to_rad(14))

	## Even Money: perfectly level on a balance.
	func _r_even() -> void:
		var y := baseline + 2.5 * u
		draw_line(Vector2(x0 - 8 * u, y), Vector2(x1 + 8 * u, y), Color(tint, 0.9), 2 * u, true)
		_poly(PackedVector2Array([Vector2(cx, y), Vector2(cx - 4.5 * u, y + 5 * u), Vector2(cx + 4.5 * u, y + 5 * u)]), Color(tint, 0.9))
		for x: float in [x0 - 8 * u, x1 + 8 * u]:
			draw_line(Vector2(x, y), Vector2(x, y - 4 * u), Color(tint, 0.9), 1.6 * u, true)
		_text_at(_ink())

	## Prime Cut: sliced clean through, the blade showing either side.
	func _r_cut() -> void:
		_text_at(_ink())
		var a := Vector2(x1 + 4 * u, top - 3 * u)
		var b := Vector2(x0 - 4 * u, baseline + 3 * u)
		draw_line(a, b, bg, 3.4 * u, true)
		draw_line(a, b, Color(tint, 0.9), 0.9 * u, true)
		var d := (a - b).normalized()
		draw_line(a, a + d * 7 * u, Color(tint, 0.9), 1.6 * u, true)
		draw_line(b, b - d * 7 * u, Color(tint, 0.9), 1.6 * u, true)

	## Lucky Numbers: on the golden spiral the Fibonacci numbers draw.
	func _r_spiral() -> void:
		var c := Vector2(cx + 3 * u, cy + 2 * u)
		var pts := PackedVector2Array()
		for i in 120:
			var th := i * 3.0 * PI / 119.0
			pts.append(c + Vector2.from_angle(-th) * 1.2 * u * exp(0.3063 * th))
		draw_polyline(pts, Color(tint, 0.75), 1.7 * u, true)
		_text_at(_ink())

	## Rotation: letters turning, arrows chasing round them.
	func _r_rotate() -> void:
		for k in 2:
			var a0 := PI * (0.1 + k)
			var pts := _oval_arc(Vector2(cx, cy), (x1 - x0) * 0.5 + 10 * u, cap * 0.5 + 6 * u, a0, a0 + PI * 0.7)
			draw_polyline(pts, Color(tint, 0.7), 1.8 * u, true)
			_head(pts[pts.size() - 1], pts[pts.size() - 1] - pts[pts.size() - 2], 5.5 * u, Color(tint, 0.95))
		var gl := _layout(1 * u)
		_put(gl[0], _ink(), Vector2.ZERO, deg_to_rad(-8))
		_put(gl[1], _ink(), Vector2.ZERO, deg_to_rad(8))

	## Big Numbers: drawn tall against a ruler.
	func _r_tall() -> void:
		var gl := _layout(1 * u, 0.95)
		for g: Dictionary in gl:
			_put(g, _ink(), Vector2.ZERO, 0.0, Vector2(0.95, 1.24), 0.0, 0.0, 0.0)
		var x: float = gl[-1].x + gl[-1].w + 7 * u
		var h := cap * 1.24
		draw_line(Vector2(x, baseline), Vector2(x, baseline - h), Color(tint, 0.75), 1.4 * u, true)
		for i in 9:
			var y := baseline - h * i / 8.0
			draw_line(Vector2(x, y), Vector2(x - (4.5 if i % 4 == 0 else 2.4) * u, y), Color(tint, 0.75), 1.2 * u, true)

	# --- Perks: Solids --------------------------------------------------------------

	## Solids: cut out of a solid plate.
	func _r_plate() -> void:
		_rr(Rect2(x0 - 9 * u, top - 5 * u, x1 - x0 + 18 * u, cap + 10 * u), 6 * u, Color(tint, 0.92))
		_text_at(bg.darkened(0.3))

	## Solid Gold: stamped into a gold ingot.
	func _r_ingot() -> void:
		var tl := Vector2(x0 - 4 * u, top - 4 * u)
		var tr := Vector2(x1 + 4 * u, top - 4 * u)
		var br := Vector2(x1 + 12 * u, baseline + 5 * u)
		var bl := Vector2(x0 - 12 * u, baseline + 5 * u)
		var hi := Color(1, 0.9, 0.52)
		var lo := Color(0.78, 0.52, 0.12)
		draw_polygon(PackedVector2Array([tl, tr, br, bl]), PackedColorArray([hi, hi, lo, lo]))
		draw_polyline(PackedVector2Array([tl, tr, br, bl, tl]), Color(0.5, 0.32, 0.05), 1.2 * u, true)
		draw_line(tl + Vector2(2, 2.5) * u, tr + Vector2(-2, 2.5) * u, Color(1, 1, 0.88, 0.7), 1.2 * u, true)
		_text_at(Color(0.32, 0.19, 0.04))

	## Bedrock: letters cut from layers of rock, on solid ground.
	func _r_strata() -> void:
		draw_line(Vector2(x0 - 10 * u, baseline + 3 * u), Vector2(x1 + 10 * u, baseline + 3 * u), Color(tint, 0.65), 1.6 * u, true)
		for p in [[0.0, 1.8], [0.3, 1.2], [0.62, 1.5], [0.95, 1.3]]:
			var x := lerpf(x0 - 8 * u, x1 + 8 * u, p[0])
			_poly(_oval(Vector2(x, baseline + 5.5 * u), p[1] * 1.4 * u, p[1] * u, 10), Color(tint, 0.5))
		_text_at(_ink())

	## Steady Run: climbing a step at a time.
	func _r_steps() -> void:
		var gl := _layout(3 * u)
		var rise := 7 * u
		var y := baseline + 3 * u
		var pts := PackedVector2Array([Vector2(gl[0].x - 6 * u, y)])
		for i in gl.size():
			var end_x: float = gl[i].x + gl[i].w + (1.5 * u if i < gl.size() - 1 else 6 * u)
			pts.append(Vector2(end_x, y - rise * i))
			if i < gl.size() - 1:
				pts.append(Vector2(end_x, y - rise * (i + 1)))
		draw_polyline(pts, Color(tint, 0.75), 1.6 * u, true)
		for i in gl.size():
			_put(gl[i], _ink(), Vector2(0, -rise * i))

	## Solids Only: one letter solid, the other only an outline.
	func _r_only() -> void:
		var gl := _layout(3 * u)
		_put(gl[0], _ink())
		var g: Dictionary = gl[1]
		var w0: float = g.w0
		draw_set_transform(Vector2(g.x + (g.w - w0) * 0.5, baseline))
		draw_char_outline(font, Vector2.ZERO, g.ch, fs, maxi(1, roundi(2.5 * u)), Color(colour, 0.55))
		draw_char(font, Vector2.ZERO, g.ch, fs, bg)
		draw_set_transform(Vector2.ZERO)

	## Last Solid: alone in a spotlight.
	func _r_spotlight() -> void:
		var w := x1 - x0
		var pts := PackedVector2Array([Vector2(cx - 5 * u, top - 8 * u), Vector2(cx + 5 * u, top - 8 * u), Vector2(cx + w * 0.5 + 14 * u, baseline + 4 * u), Vector2(cx - w * 0.5 - 14 * u, baseline + 4 * u)])
		var light := Color(1, 0.96, 0.82)
		draw_polygon(pts, PackedColorArray([Color(light, 0.3), Color(light, 0.3), Color(light, 0.03), Color(light, 0.03)]))
		_poly(_oval(Vector2(cx, baseline + 3 * u), w * 0.5 + 10 * u, 3.5 * u), Color(light, 0.2))
		_rr(Rect2(cx - 7 * u, top - 11 * u, 14 * u, 3.5 * u), 1.5 * u, Color(tint, 0.9))
		_text_at(_ink())

	## Low Ball: ducking low under a limbo bar.
	func _r_limbo() -> void:
		var gl := _layout(1 * u, 1.1)
		for g: Dictionary in gl:
			_put(g, _ink(), Vector2.ZERO, 0.0, Vector2(1.1, 0.72), 0.0, 0.0, 0.0)
		var y := baseline - cap * 0.72 - 5 * u
		var a: float = gl[0].x - 9 * u
		var b: float = gl[-1].x + gl[-1].w + 9 * u
		for x: float in [a, b]:
			draw_line(Vector2(x, y - 2 * u), Vector2(x, baseline + 3 * u), Color(tint, 0.75), 1.6 * u, true)
		draw_line(Vector2(a - 2 * u, y), Vector2(b + 2 * u, y), Color(colour, 0.85), 2 * u, true)

	# --- Perks: Stripes ------------------------------------------------------------

	## Stripes: a coloured band right across, like a striped ball.
	func _r_band() -> void:
		_text_at(_ink())

	## Racing Stripe: twin racing stripes and a chequered flag.
	func _r_racing() -> void:
		_text_at(_ink())
		var o := Vector2(x1 + 6 * u, top + 2 * u)
		var sq := 2.6 * u
		draw_line(o, o + Vector2(0, 16 * u), Color(colour, 0.7), 1.2 * u, true)
		for i in 4:
			for j in 3:
				draw_rect(Rect2(o + Vector2(i * sq + 0.6 * u, j * sq), Vector2(sq, sq)), colour if (i + j) % 2 == 0 else Color(0.08, 0.08, 0.1))

	## Lucky Stripe: a sash of stripes and a four-leaf clover.
	func _r_clover() -> void:
		_text_at(_ink())
		var c := Vector2(x1 + 9 * u, top + 6 * u)
		var green := Color(0.42, 0.88, 0.5)
		draw_line(c, c + Vector2(2, 7) * u, green, 1.3 * u, true)
		for k in 4:
			var a := PI * 0.25 + PI * 0.5 * k
			draw_circle(c + Vector2.from_angle(a) * 2.6 * u, 2.4 * u, green, true, -1.0, true)

	## Tiger Stripes: striped like a tiger.
	func _r_tiger() -> void:
		_text_at(Color(0, 0, 0, 0.5), Vector2(1.5, 1.5) * u)
		_text_at(_ink())

	## Stripes Only: pinstriped all through.
	func _r_pinstripe() -> void:
		_edge(Color(tint, 0.35), 2 * u)
		_text_at(_ink())

	## Last Stripe: one stripe left lit among faded ones.
	func _r_laststripe() -> void:
		for k in 5:
			var y := lerpf(top + 2 * u, baseline - 2 * u, k / 4.0)
			var last := k == 3
			draw_line(Vector2(x0 - 16 * u, y), Vector2(x1 + 16 * u, y), Color(tint, 0.9 if last else 0.13), (3.0 if last else 1.2) * u, true)
		_text_at(_ink())

	## High Roller: each letter on a thrown die.
	func _r_dice() -> void:
		var gl := _layout(7 * u)
		for i in gl.size():
			var g: Dictionary = gl[i]
			var rot := deg_to_rad(-9.0 if i == 0 else 8.0)
			var h := _gh(g.ch)
			var half := h * 0.5 + 5 * u
			var c := Vector2(g.x + g.w * 0.5, baseline - h * 0.5 - 2 * u)
			draw_set_transform(c, rot)
			var r := Rect2(-half, -half, half * 2, half * 2)
			_rr(r, 4 * u, Color(tint, 0.14))
			_rr(r, 4 * u, Color(tint, 0.8), 1.5 * u)
			for p: Vector2 in [Vector2(-1, -1), Vector2(1, 1)]:
				draw_circle(p * (half - 3.6 * u), 1.4 * u, Color(tint, 0.95), true, -1.0, true)
			draw_set_transform(Vector2.ZERO)
			_put(g, _ink(), Vector2(0, -2 * u), rot * 0.6)

	# --- Perks: The 8-ball -----------------------------------------------------------

	## Behind the 8: standing in front of the 8-ball.
	func _r_behind() -> void:
		var c := Vector2(x1 - 3 * u, cy - 2 * u)
		draw_circle(c, 16 * u, EIGHT_BLACK, true, -1.0, true)
		draw_arc(c, 16 * u, 0, TAU, 40, Color(tint, 0.5), 1 * u, true)
		var spot := c + Vector2(5, -6) * u
		draw_circle(spot, 6.5 * u, Color(0.96, 0.95, 0.9), true, -1.0, true)
		var f8 := roundi(10 * u)
		var w8 := font.get_string_size("8", HORIZONTAL_ALIGNMENT_LEFT, -1, f8).x
		draw_string(font, spot + Vector2(-w8 * 0.5, 3.6 * u), "8", HORIZONTAL_ALIGNMENT_LEFT, -1, f8, EIGHT_BLACK)
		_edge(Color(bg.darkened(0.5), 0.9), 6 * u)
		_text_at(_ink())

	## Dark Horse: a black silhouette, rimmed in light.
	func _r_dark() -> void:
		_edge(tint.lerp(colour, 0.4), 3.5 * u)
		_text_at(Color(0.06, 0.06, 0.08))
		_star(Vector2(x1 + 2 * u, top + 2 * u), 4.5 * u, SPARK)

	## Hush Money: a censor bar across the middle.
	func _r_hush() -> void:
		_text_at(_ink())
		draw_set_transform(Vector2(cx, baseline - cap * 0.46), -0.04)
		_rr(Rect2(-(x1 - x0) * 0.5 - 6 * u, -3 * u, x1 - x0 + 12 * u, 6 * u), 1.5 * u, Color(0.02, 0.02, 0.03, 0.95))
		draw_set_transform(Vector2.ZERO)

	## Kiss the Black: leaning in to touch, beside the black ball.
	func _r_kiss() -> void:
		var gl := _layout(-1 * u)
		_put(gl[0], _ink(), Vector2(1 * u, 0), deg_to_rad(7), Vector2.ONE, 0.0, 0.0, 0.0)
		_put(gl[1], _ink(), Vector2(-1 * u, 0), deg_to_rad(-7), Vector2.ONE, 0.0, 0.0, 0.0)
		_star(Vector2(gl[1].x + 1 * u, top + 1 * u), 4.6 * u, SPARK)
		var b := Vector2(x1 + 8 * u, baseline - 5 * u)
		draw_circle(b, 5 * u, EIGHT_BLACK, true, -1.0, true)
		draw_arc(b, 5 * u, 0, TAU, 20, Color(tint, 0.5), 0.8 * u, true)
		draw_circle(b + Vector2(-1.4, -1.4) * u, 1.8 * u, Color(0.96, 0.95, 0.9), true, -1.0, true)

	## Steer Clear: leaning away from the 8 between them.
	func _r_steer() -> void:
		var gl := _layout(14 * u)
		var c := Vector2((gl[0].x + gl[0].w + gl[1].x) * 0.5, baseline - 6 * u)
		for side in [-1.0, 1.0]:
			var a: float = -PI * 0.5 + side * 0.85
			draw_arc(c, 10 * u, a - 0.45, a + 0.45, 10, Color(tint, 0.6), 1.3 * u, true)
		draw_circle(c, 5.5 * u, EIGHT_BLACK, true, -1.0, true)
		draw_arc(c, 5.5 * u, 0, TAU, 20, Color(tint, 0.5), 0.8 * u, true)
		draw_circle(c + Vector2(-1.5, -1.5) * u, 2 * u, Color(0.96, 0.95, 0.9), true, -1.0, true)
		_put(gl[0], _ink(), Vector2(-1 * u, 0), deg_to_rad(-9), Vector2.ONE, 0.0, 0.0, 0.0)
		_put(gl[1], _ink(), Vector2(1 * u, 0), deg_to_rad(9), Vector2.ONE, 0.0, 0.0, 0.0)

	## Last Call: a neon bar sign.
	func _r_neon() -> void:
		var tube := tint.lerp(Color(1, 0.42, 0.82), 0.55)
		_edge(Color(tube, 0.08), 15 * u)
		_edge(Color(tube, 0.18), 9 * u)
		_edge(tube, 5 * u)
		_text_at(bg)
		_edge(Color(1, 0.9, 0.97, 0.9), 1 * u)
		_text_at(bg)

	## Eight Count: eight tally marks.
	func _r_tally() -> void:
		_text_at(_ink())
		var col := Color(tint, 0.9)
		var y0 := baseline - 10 * u
		var y1 := baseline - 1 * u
		var x := x1 + 6 * u
		for i in 4:
			draw_line(Vector2(x + i * 3.2 * u, y0), Vector2(x + i * 3.2 * u, y1), col, 1.4 * u, true)
		draw_line(Vector2(x - 1.5 * u, y1 - 0.5 * u), Vector2(x + 11 * u, y0 + 0.5 * u), col, 1.4 * u, true)
		for i in 3:
			draw_line(Vector2(x + (17 + i * 3.2) * u, y0), Vector2(x + (17 + i * 3.2) * u, y1), col, 1.4 * u, true)

	## Trouble Maker: letters jostling over a hazard stripe.
	func _r_hazard() -> void:
		var r := Rect2(x0 - 6 * u, baseline + 3 * u, x1 - x0 + 12 * u, 5 * u)
		draw_rect(r, Color(1, 0.8, 0.15, 0.95))
		var x := r.position.x - r.size.y
		while x < r.end.x:
			var pts := PackedVector2Array()
			for p: Vector2 in [Vector2(x + r.size.y, r.position.y), Vector2(x + r.size.y + 2.5 * u, r.position.y), Vector2(x + 2.5 * u, r.end.y), Vector2(x, r.end.y)]:
				pts.append(Vector2(clampf(p.x, r.position.x, r.end.x), p.y))
			draw_colored_polygon(pts, Color(0.08, 0.08, 0.08, 0.95))
			x += 5 * u
		var gl := _layout(2 * u)
		_put(gl[0], _ink(), Vector2(0, -1 * u), deg_to_rad(-8))
		_put(gl[1], _ink(), Vector2(0, 1 * u), deg_to_rad(10))

	# --- Perks: Banks & cushions -------------------------------------------------------

	## Bank Manager: engraved like a banknote, in a double frame.
	func _r_banknote() -> void:
		var r := Rect2(x0 - 11 * u, top - 6 * u, x1 - x0 + 22 * u, cap + 12 * u)
		_rr(r, 3 * u, Color(tint, 0.08))
		_rr(r, 3 * u, Color(tint, 0.65), 1 * u)
		var inner := r.grow(-2.5 * u)
		_rr(inner, 2 * u, Color(tint, 0.4), 1 * u)
		for p: Vector2 in [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]:
			draw_circle(p, 1.6 * u, Color(tint, 0.7), true, -1.0, true)
		_text_at(_ink())

	## Ricochet: a path zigzagging between two rails.
	func _r_ricochet() -> void:
		var ya := top - 4 * u
		var yb := baseline + 4 * u
		var a := x0 - 14 * u
		var b := x1 + 14 * u
		for y: float in [ya, yb]:
			draw_line(Vector2(a, y), Vector2(b, y), Color(tint, 0.45), 1.6 * u, true)
		var w := b - a
		var pts := PackedVector2Array([Vector2(a + 2 * u, cy), Vector2(a + w * 0.22, yb), Vector2(a + w * 0.48, ya), Vector2(a + w * 0.74, yb), Vector2(b - 3 * u, ya + 9 * u)])
		draw_polyline(pts, Color(tint, 0.75), 1.5 * u, true)
		draw_circle(pts[pts.size() - 1], 2.6 * u, colour, true, -1.0, true)
		_text_at(_ink())

	## Soft Rails: plump, cushioned letters on a padded rail.
	func _r_pillow() -> void:
		_rr(Rect2(x0 - 8 * u, baseline + 3 * u, x1 - x0 + 16 * u, 4.5 * u), 2.2 * u, Color(tint, 0.6))
		_edge(Color(tint, 0.25), 10 * u)
		_edge(tint.lerp(colour, 0.6), 4 * u)
		_text_at(_ink())

	## Geometry: the angle in equals the angle out.
	func _r_angles() -> void:
		var y := baseline + 5 * u
		var p := Vector2(cx, y)
		draw_line(Vector2(x0 - 16 * u, y), Vector2(x1 + 16 * u, y), Color(tint, 0.75), 1.6 * u, true)
		var a := Vector2(x0 - 12 * u, top - 4 * u)
		var b := Vector2(x1 + 12 * u, top - 4 * u)
		draw_line(a, p, Color(tint, 0.45), 1.2 * u, true)
		draw_line(p, b, Color(tint, 0.45), 1.2 * u, true)
		draw_arc(p, 8 * u, -PI, (a - p).angle(), 12, Color(tint, 0.9), 1.3 * u, true)
		draw_arc(p, 8 * u, (b - p).angle(), 0.0, 12, Color(tint, 0.9), 1.3 * u, true)
		_text_at(_ink())

	## Tracer: a dashed outline traced by a glowing round.
	func _r_trace() -> void:
		_edge(_ink(), 3 * u)
		_text_at(bg)
		var head := Vector2(x1 + 11 * u, cy - 5 * u)
		draw_polyline_colors(PackedVector2Array([Vector2(x1 + 1 * u, cy + 3 * u), head]), PackedColorArray([Color(tint, 0), Color(tint, 0.85)]), 1.6 * u, true)
		draw_circle(head, 4 * u, Color(tint, 0.3), true, -1.0, true)
		draw_circle(head, 2.2 * u, SPARK, true, -1.0, true)

	# --- Perks: Utility -----------------------------------------------------------------

	## Long Game: spaced out over a measured length.
	func _r_long() -> void:
		var gl := _layout(12 * u)
		for g: Dictionary in gl:
			_put(g, _ink())
		var a: float = gl[0].x
		var b: float = gl[-1].x + gl[-1].w
		var y := baseline + 5 * u
		var col := Color(tint, 0.8)
		draw_line(Vector2(a, y), Vector2(b, y), col, 1.4 * u, true)
		for i in 7:
			var x := lerpf(a, b, i / 6.0)
			var t := 3.0 if i == 0 or i == 6 else 1.4
			draw_line(Vector2(x, y - t * u), Vector2(x, y + t * u), col, 1.3 * u, true)

	## Spare Chalk: blue and chalky, with a little dust.
	func _r_chalky() -> void:
		_text_at(_ink())
		for d in [[0.1, 3.0, 1.0], [0.35, 4.5, 0.7], [0.62, 3.5, 1.1], [0.86, 5.0, 0.8], [0.5, 6.5, 0.6]]:
			draw_circle(Vector2(lerpf(x0, x1, d[0]), baseline + d[1] * u), d[2] * u, Color(0.62, 0.8, 1.0, 0.55), true, -1.0, true)

	## Long Lens: one letter enlarged under a magnifying glass.
	func _r_lens() -> void:
		var gl := _layout(3 * u)
		_put(gl[0], _ink())
		var g: Dictionary = gl[1]
		var c := Vector2(g.x + g.w * 0.5, baseline - xh * 0.5)
		var r := xh * 0.5 + 5 * u
		var rim := tint.lerp(colour, 0.4)
		draw_circle(c, r, Color(tint, 0.14), true, -1.0, true)
		_put(g, _ink(), Vector2.ZERO, 0.0, Vector2(1.15, 1.15))
		draw_arc(c, r, 0, TAU, 40, rim, 2 * u, true)
		var d := Vector2(0.7, 0.7)
		draw_line(c + d * r, c + d * (r + 6 * u), rim, 3.2 * u, true)

	## Insurance: safe behind a shield.
	func _r_shield() -> void:
		var hw := (x1 - x0) * 0.5 + 9 * u
		var t := top - 5 * u
		var mid := t + (cap + 5 * u) * 0.45
		var bot := baseline + 7 * u
		var right := PackedVector2Array()
		for i in 9:
			var a := PI * 0.5 * i / 8.0
			right.append(Vector2(cx + hw * cos(a), mid + (bot - mid) * sin(a)))
		var pts := PackedVector2Array([Vector2(cx - hw, t), Vector2(cx + hw, t)])
		pts.append_array(right)
		for i in range(7, -1, -1):
			pts.append(Vector2(2 * cx - right[i].x, right[i].y))
		_poly(pts, Color(tint, 0.12))
		pts.append(pts[0])
		draw_polyline(pts, Color(tint, 0.65), 1.6 * u, true)
		_text_at(_ink())

	## Second Sight: inside an all-seeing eye.
	func _r_eye() -> void:
		var a := Vector2(x0 - 15 * u, cy)
		var b := Vector2(x1 + 15 * u, cy)
		var bulge := cap * 0.5 + 6 * u
		draw_circle(Vector2(cx, cy), cap * 0.5 + 4 * u, Color(tint, 0.14), true, -1.0, true)
		for side in [-1.0, 1.0]:
			var ctl := Vector2(cx, cy + side * bulge * 2.0)
			var pts := PackedVector2Array()
			for i in 21:
				var t := i / 20.0
				pts.append(a.lerp(ctl, t).lerp(ctl.lerp(b, t), t))
			draw_polyline(pts, Color(tint, 0.65), 1.6 * u, true)
		_text_at(_ink())

	# --- Perks: Economy --------------------------------------------------------------

	## Gold Rail: on a gold rail with its diamond sights.
	func _r_rail() -> void:
		var r := Rect2(x0 - 14 * u, baseline + 2.5 * u, x1 - x0 + 28 * u, 5 * u)
		var hi := Color(1, 0.9, 0.5)
		var lo := Color(0.75, 0.5, 0.12)
		draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), PackedColorArray([hi, hi, lo, lo]))
		for k in 3:
			var c := Vector2(lerpf(r.position.x, r.end.x, (k + 1) / 4.0), r.get_center().y)
			_poly(PackedVector2Array([c + Vector2(0, -1.6) * u, c + Vector2(2.2, 0) * u, c + Vector2(0, 1.6) * u, c + Vector2(-2.2, 0) * u]), Color(1, 1, 0.92))
		_text_at(_ink())

	## Thrift: small letters on a price tag.
	func _r_tag() -> void:
		var gl := _layout(0.0, 0.84)
		var a: float = gl[0].x
		var b: float = gl[-1].x + gl[-1].w
		var t := baseline - cap * 0.84 - 5 * u
		var btm := baseline + 5 * u
		var mid := (t + btm) * 0.5
		var pts := PackedVector2Array([Vector2(a - 14 * u, mid), Vector2(a - 6 * u, t), Vector2(b + 6 * u, t), Vector2(b + 6 * u, btm), Vector2(a - 6 * u, btm)])
		_poly(pts, Color(tint, 0.12))
		pts.append(pts[0])
		draw_polyline(pts, Color(tint, 0.75), 1.5 * u, true)
		var hole := Vector2(a - 8 * u, mid)
		draw_arc(hole, 2 * u, 0, TAU, 12, Color(tint, 0.85), 1.2 * u, true)
		draw_polyline(_oval_arc(hole + Vector2(-5, -2) * u, 5 * u, 6 * u, PI * 0.1, -PI * 0.9, 12), Color(colour, 0.5), 1 * u, true)
		for g: Dictionary in gl:
			_put(g, _ink(), Vector2.ZERO, 0.0, Vector2(0.84, 0.84), 0.0, 0.0, 0.0)

	## Deep Pockets: sinking into a pocket.
	func _r_deep() -> void:
		var c := Vector2(cx, baseline + 1 * u)
		_poly(_oval(c, (x1 - x0) * 0.5 + 7 * u, 5 * u), Color(0, 0, 0, 0.7))
		_oval_line(c, (x1 - x0) * 0.5 + 7 * u, 5 * u, Color(tint, 0.6), 1.4 * u)
		_text_at(_ink(), Vector2(0, 3 * u))

	## Side Hustle: letters shuffling side to side.
	func _r_hustle() -> void:
		for g: Dictionary in _layout(2 * u):
			_put(g, _ink(), Vector2.ZERO, 0.0, Vector2.ONE, 0.2)
		var y := baseline + 5.5 * u
		var col := Color(tint, 0.85)
		draw_line(Vector2(x0 - 2 * u, y), Vector2(x1 + 2 * u, y), col, 1.5 * u, true)
		_head(Vector2(x1 + 5 * u, y), Vector2.RIGHT, 5 * u, col)
		_head(Vector2(x0 - 5 * u, y), Vector2.LEFT, 5 * u, col)

	## Overflow: too big for its beaker, spilling over.
	func _r_beaker() -> void:
		var hw := (x1 - x0) * 0.5 - 2 * u
		var rim := top + 9 * u
		var btm := baseline + 5 * u
		var glass := Color(tint, 0.8)
		_rr(Rect2(cx - hw + 1.5 * u, cy + 3 * u, hw * 2 - 3 * u, btm - cy - 4.5 * u), 2 * u, Color(tint, 0.3))
		var pts := PackedVector2Array([Vector2(cx - hw - 3.5 * u, rim - 2 * u), Vector2(cx - hw, rim)])
		pts.append_array(_oval_arc(Vector2(cx - hw + 3 * u, btm - 3 * u), 3 * u, 3 * u, PI, PI * 0.5, 6))
		pts.append_array(_oval_arc(Vector2(cx + hw - 3 * u, btm - 3 * u), 3 * u, 3 * u, PI * 0.5, 0.0, 6))
		pts.append(Vector2(cx + hw, rim))
		draw_polyline(pts, glass, 1.6 * u, true)
		_text_at(_ink())
		for d in [[cx + hw + 2.5 * u, rim + 5 * u, 1.6], [cx - hw - 2.5 * u, rim + 12 * u, 1.3]]:
			var p := Vector2(d[0], d[1])
			_poly(PackedVector2Array([p + Vector2(0, -3.2) * u * d[2], p + Vector2(0.9, 0) * u * d[2], p + Vector2(-0.9, 0) * u * d[2]]), Color(tint, 0.85))
			draw_circle(p, d[2] * u, Color(tint, 0.85), true, -1.0, true)

	# --- Perks: Risk & scaling ---------------------------------------------------------

	## Snowball: a snowball rolling along, bigger with every turn, snow flying.
	func _r_snowball() -> void:
		var snow := Color(0.97, 0.98, 1.0)
		var x := x1 + 4 * u
		for k in 4:
			var r := (1.2 + 1.3 * k) * u
			x += r + 1.2 * u
			draw_circle(Vector2(x, baseline - r), r, Color(snow, 0.45 + 0.18 * k), true, -1.0, true)
			x += r
		_text_at(_ink())
		for f in [[-0.12, 0.2, 1.2], [0.3, -0.12, 1.0], [0.85, -0.08, 1.1], [0.55, -0.2, 0.8], [-0.05, 0.75, 0.8]]:
			draw_circle(Vector2(lerpf(x0, x1, f[0]), lerpf(top, baseline, f[1])), f[2] * u, Color(0.97, 0.98, 1.0, 0.75), true, -1.0, true)

	## First Blood: the first letter drips.
	func _r_drip() -> void:
		_text_at(_ink())
		var g: Dictionary = _layout()[0]
		var red := Color(0.86, 0.12, 0.18)
		for d in [[0.14, 7.0], [0.3, 4.0]]:
			var x: float = g.x + g.w * d[0]
			var l: float = d[1] * u
			draw_line(Vector2(x, baseline - 2 * u), Vector2(x, baseline + l), red, 2.2 * u, true)
			draw_circle(Vector2(x, baseline + l), 1.9 * u, red, true, -1.0, true)

	## All In: between two stacks of chips, pushed to the middle.
	func _r_chips() -> void:
		for side in [-1.0, 1.0]:
			var x := (x0 - 12 * u) if side < 0 else (x1 + 12 * u)
			for k in 3:
				var c := Vector2(x, baseline - 2 * u - k * 4 * u)
				var face := tint if k % 2 == 0 else colour
				_poly(_oval(c + Vector2(0, 1.4 * u), 7 * u, 2.6 * u, 20), face.darkened(0.45))
				_poly(_oval(c, 7 * u, 2.6 * u, 20), face)
				_oval_line(c, 4.2 * u, 1.5 * u, Color(face.darkened(0.35), 0.8), 0.8 * u)
		for g: Dictionary in _layout(-1 * u):
			_put(g, _ink())

	## Double Take: seen twice.
	func _r_double() -> void:
		_text_at(Color(tint, 0.6), Vector2(3, -3) * u)
		_text_at(_ink())

	# --- Perks: Clearing your set --------------------------------------------------------

	## Thin Rack: drawn thin inside a narrow rack.
	func _r_thin() -> void:
		var gl := _layout(3 * u, 0.62)
		var a: float = gl[0].x
		var b: float = gl[-1].x + gl[-1].w
		var pts := PackedVector2Array([Vector2(cx, top - 6 * u), Vector2(b + 6 * u, baseline + 4 * u), Vector2(a - 6 * u, baseline + 4 * u), Vector2(cx, top - 6 * u)])
		draw_polyline(pts, Color(tint, 0.55), 1.3 * u, true)
		for g: Dictionary in gl:
			_put(g, _ink(), Vector2.ZERO, 0.0, Vector2(0.62, 1.04), 0.0, 0.0, 0.0)

	## Missing Piece: a piece knocked out, floating free.
	func _r_missing() -> void:
		_text_at(_ink())
		var g: Dictionary = _layout()[0]
		var sz := 8 * u
		_piece(Vector2(g.x + g.w - sz * 1.15, top - 1 * u), sz, bg)
		draw_set_transform(Vector2(x1 + 8 * u, top + 2 * u), 0.35)
		_piece(Vector2.ZERO, sz, Color(tint, 0.9))
		draw_set_transform(Vector2.ZERO)

	func _piece(at: Vector2, sz: float, col: Color) -> void:
		draw_rect(Rect2(at, Vector2(sz, sz)), col)
		draw_circle(at + Vector2(sz, sz * 0.5), sz * 0.3, col, true, -1.0, true)
		draw_circle(at + Vector2(sz * 0.5, sz), sz * 0.3, col, true, -1.0, true)

	## Clean House: polished to a shine, sparkling.
	func _r_clean() -> void:
		draw_polyline(_oval_arc(Vector2(cx, baseline - 4 * u), (x1 - x0) * 0.5 + 10 * u, 9 * u, PI * 0.12, PI * 0.88, 20), Color(tint, 0.45), 1.6 * u, true)
		_text_at(_ink())
		_star(Vector2(x0 - 4 * u, top + 2 * u), 5 * u, SPARK)
		_star(Vector2(x1 + 5 * u, top + 9 * u), 3.4 * u, SPARK)
		_star(Vector2(x1 + 1 * u, baseline - 1 * u), 2.4 * u, SPARK)

	# --- Perks: Gear, Imbues, Special balls ----------------------------------------------

	## Pack Rat: a slot for every letter and a spare one.
	func _r_slots() -> void:
		var gl := _layout(9 * u)
		for g: Dictionary in gl:
			var r := Rect2(g.x - 3.5 * u, top - 4 * u, g.w + 7 * u, cap + 8 * u)
			_rr(r, 3 * u, Color(tint, 0.12))
			_rr(r, 3 * u, Color(tint, 0.65), 1.3 * u)
			_put(g, _ink())
		var x: float = gl[-1].x + gl[-1].w + 8 * u
		var sq := Rect2(x, cy - 6 * u, 12 * u, 12 * u)
		var col := Color(tint, 0.6)
		_dashes(PackedVector2Array([sq.position, Vector2(sq.end.x, sq.position.y), sq.end, Vector2(sq.position.x, sq.end.y), sq.position]), col, 1.2 * u, 2.5 * u, 2 * u)
		var c := sq.get_center()
		draw_line(c - Vector2(3, 0) * u, c + Vector2(3, 0) * u, col, 1.4 * u, true)
		draw_line(c - Vector2(0, 3) * u, c + Vector2(0, 3) * u, col, 1.4 * u, true)

	## Quartermaster: stencilled like army stores.
	func _r_stencil() -> void:
		_text_at(_ink())
		for g: Dictionary in _layout():
			var cuts: Array = [0.3, 0.72] if g.ch == "m" else [0.5]
			for f: float in cuts:
				var x: float = g.x + g.w * f
				draw_line(Vector2(x, top - 2 * u), Vector2(x, baseline + 2 * u), bg, 2.2 * u)

	## Tinkerer: in front of a cog.
	func _r_cog() -> void:
		var c := Vector2(cx, cy)
		var ro := cap * 0.5 + 8 * u
		var ri := ro - 4 * u
		var pts := PackedVector2Array()
		for i in 40:
			var a := TAU * (i + 0.5) / 40.0
			pts.append(c + Vector2.from_angle(a) * (ro if i % 4 == 1 or i % 4 == 2 else ri))
		_poly(pts, Color(tint, 0.1))
		pts.append(pts[0])
		draw_polyline(pts, Color(tint, 0.55), 1.4 * u, true)
		draw_arc(c, ri - 6 * u, 0, TAU, 40, Color(tint, 0.3), 1 * u, true)
		_text_at(_ink())

	## Enchanter: a magic ring orbiting through the letters.
	func _r_enchant() -> void:
		var c := Vector2(cx, cy + 2 * u)
		var rx := (x1 - x0) * 0.5 + 13 * u
		var ry := 7 * u
		var back := _turned(_oval_arc(c, rx, ry, PI, TAU, 24), c, -0.22)
		var front := _turned(_oval_arc(c, rx, ry, 0.0, PI, 24), c, -0.22)
		draw_polyline(back, Color(tint, 0.45), 1.2 * u, true)
		_star(back[17], 2.6 * u, Color(SPARK, 0.7))
		_text_at(_ink())
		draw_polyline(front, Color(tint, 0.85), 1.4 * u, true)
		_star(front[6], 3.6 * u, SPARK)
		_star(front[19], 2.8 * u, SPARK)

	## Second Coat: over a fresh brush stroke of paint.
	func _r_coat() -> void:
		var a := x0 - 10 * u
		var b := x1 + 12 * u
		var y := baseline - cap * 0.5
		var pts := PackedVector2Array([Vector2(a + 3 * u, y), Vector2(b, y - 2 * u), Vector2(b - 2 * u, y + 3 * u), Vector2(b + 1 * u, y + 6 * u), Vector2(b - 3 * u, y + 12 * u), Vector2(a, y + 13 * u), Vector2(a + 2 * u, y + 8 * u), Vector2(a - 1 * u, y + 4 * u)])
		_poly(pts, Color(tint, 0.42))
		for k in 3:
			var yy := y + (2.5 + 4 * k) * u
			draw_line(Vector2(a + (4 + 3 * k) * u, yy), Vector2(b - (3 + 2 * k) * u, yy - 1.5 * u), Color(tint, 0.3), 1 * u, true)
		_text_at(_ink())

	## Gold Rush: struck gold, with nuggets.
	func _r_nuggets() -> void:
		_text_at(_ink())
		for n in [[x0 - 9 * u, baseline - 2 * u, 4.0, 0.2], [x1 + 8 * u, baseline - 1 * u, 3.2, 1.1], [x1 + 14 * u, baseline - 7 * u, 2.4, 2.0]]:
			var c := Vector2(n[0], n[1])
			var pts := PackedVector2Array()
			var k := 0
			for f: float in [1.0, 0.75, 0.95, 0.7, 1.0, 0.8]:
				pts.append(c + Vector2.from_angle(n[3] + TAU * k / 6.0) * n[2] * u * f)
				k += 1
			_poly(pts, Color(0.95, 0.74, 0.24))
			draw_circle(c + Vector2(-0.8, -0.8) * u, n[2] * 0.3 * u, Color(1, 0.95, 0.7), true, -1.0, true)

	## Menagerie: each letter a different colour, a row of balls below.
	func _r_menagerie() -> void:
		var gl := _layout(2 * u)
		_put(gl[0], Catalog.BALL_COLORS[1].lerp(colour, 0.2))
		_put(gl[1], Catalog.BALL_COLORS[2].lerp(colour, 0.5))
		for k in 5:
			draw_circle(Vector2(cx + (k - 2) * 6.5 * u, baseline + 5.5 * u), 2.4 * u, Catalog.BALL_COLORS[k + 3].lerp(colour, 0.15), true, -1.0, true)

	## Alchemy: lead turning to gold, beside the alchemists' sign.
	func _r_transmute() -> void:
		var c := Vector2(x0 - 13 * u, cy)
		var col := Color(tint, 0.65)
		draw_arc(c, 7 * u, 0, TAU, 28, col, 1.3 * u, true)
		var tri := PackedVector2Array()
		for k in 4:
			tri.append(c + Vector2.from_angle(-PI * 0.5 + TAU * k / 3.0) * 7 * u)
		draw_polyline(tri, col, 1.3 * u, true)
		_text_at(_ink())
		_star(Vector2(x1 + 4 * u, top + 3 * u), 4 * u, Color(1, 0.88, 0.45))

	# --- Perks: Pausing --------------------------------------------------------------

	## Stillness: paused, on water without a ripple.
	func _r_still() -> void:
		var x := x0 - 15 * u
		for k in 2:
			_rr(Rect2(x + k * 5.5 * u, cy - 8 * u, 3.4 * u, 16 * u), 1.4 * u, Color(tint, 0.9))
		_oval_line(Vector2(cx, baseline + 4 * u), (x1 - x0) * 0.5 + 4 * u, 1.8 * u, Color(tint, 0.45), 1 * u)
		_oval_line(Vector2(cx, baseline + 4 * u), (x1 - x0) * 0.5 + 12 * u, 3 * u, Color(tint, 0.2), 1 * u)
		_text_at(_ink())

	## Quick Hands: a blur of movement up and away.
	func _r_blur() -> void:
		for k in range(7, 0, -1):
			_text_at(Color(tint, 0.05 + 0.025 * (7 - k)), Vector2(-1.9, -0.9) * k * u)
		_text_at(_ink())

	## Afterimage: the colours split apart, as a fast image leaves.
	func _r_chroma() -> void:
		_text_at(Color(1, 0.3, 0.42, 0.75), Vector2(-2.6 * u, 0))
		_text_at(Color(0.3, 0.86, 1, 0.75), Vector2(2.6 * u, 0))
		_text_at(_ink())

	## Overclock: on a microchip, its screen lines glowing.
	func _r_chip() -> void:
		var r := Rect2(x0 - 8 * u, top - 5 * u, x1 - x0 + 16 * u, cap + 10 * u)
		_rr(r, 3 * u, Color(tint, 0.1))
		_rr(r, 3 * u, Color(tint, 0.7), 1.4 * u)
		for i in 4:
			var y := lerpf(r.position.y + 6 * u, r.end.y - 6 * u, i / 3.0)
			draw_line(Vector2(r.position.x - 4 * u, y), Vector2(r.position.x, y), Color(tint, 0.7), 1.6 * u, true)
			draw_line(Vector2(r.end.x, y), Vector2(r.end.x + 4 * u, y), Color(tint, 0.7), 1.6 * u, true)
		draw_circle(r.position + Vector2(4, 4) * u, 1.3 * u, Color(tint, 0.8), true, -1.0, true)
		_edge(Color(tint, 0.2), 6 * u)
		_text_at(_ink())

	# --- Gold ------------------------------------------------------------------------

	func _gold_material() -> ShaderMaterial:
		if _gold_shader == null:
			_gold_shader = Shader.new()
			_gold_shader.code = """
shader_type canvas_item;
uniform float top;
uniform float bottom;
uniform float phase = 0.0;
uniform float glint_w = 5.0;
uniform vec3 hi : source_color = vec3(1.0, 0.96, 0.7);
uniform vec3 mid : source_color = vec3(0.95, 0.72, 0.2);
uniform vec3 lo : source_color = vec3(0.55, 0.34, 0.04);
uniform vec3 edge : source_color = vec3(0.22, 0.13, 0.02);
varying vec2 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	if (COLOR.r < 0.02) {
		COLOR = vec4(edge, COLOR.a);
	} else {
		float t = clamp((lp.y - top) / (bottom - top), 0.0, 1.0);
		vec3 g = t < 0.5 ? mix(hi, mid, t * 2.0) : mix(mid, lo, (t - 0.5) * 2.0);
		// A glint crosses during the first third of every 4-second cycle.
		float sweep = fract(TIME * 0.25 + phase) / 0.33;
		float x = lp.x + (lp.y - top) * 0.6;
		float pos = 20.0 + sweep * 140.0;
		float band = sweep <= 1.0 ? smoothstep(glint_w, 0.0, abs(x - pos)) : 0.0;
		COLOR = vec4(mix(g, vec3(1.0), band * 0.9), COLOR.a);
	}
}
"""
		var m := ShaderMaterial.new()
		m.shader = _gold_shader
		m.set_shader_parameter("top", baseline - TileArt.F_SEMI.get_ascent(fs) * 0.8)
		m.set_shader_parameter("glint_w", 5.0 * s)
		m.set_shader_parameter("bottom", baseline)
		m.set_shader_parameter("phase", 0.15)
		return m
