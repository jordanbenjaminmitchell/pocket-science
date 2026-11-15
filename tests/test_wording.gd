extends SceneTree
## Consistency: player-facing text uses the game's own words, names never clash,
## and every Element is the real element its atomic number says.

var failures := 0
var KINDS := {"PERKS": Catalog.PERKS, "ITEMS": Catalog.ITEMS, "IMBUES": Catalog.IMBUES, "BALL_TYPES": Catalog.BALL_TYPES, "CUES": Catalog.CUES, "BOSSES": Catalog.BOSSES, "DISCOVERIES": Catalog.DISCOVERIES}

const SYMBOLS := "H He Li Be B C N O F Ne Na Mg Al Si P S Cl Ar K Ca Sc Ti V Cr Mn Fe Co Ni Cu Zn Ga Ge As Se Br Kr Rb Sr Y Zr Nb Mo Tc Ru Rh Pd Ag Cd In Sn Sb Te I Xe Cs Ba La Ce Pr Nd Pm Sm Eu Gd Tb Dy Ho Er Tm Yb Lu Hf Ta W Re Os Ir Pt Au Hg Tl Pb Bi Po At Rn Fr Ra Ac Th Pa U Np Pu Am Cm Bk Cf Es Fm"
const NAMES := "Hydrogen Helium Lithium Beryllium Boron Carbon Nitrogen Oxygen Fluorine Neon Sodium Magnesium Aluminium Silicon Phosphorus Sulfur Chlorine Argon Potassium Calcium Scandium Titanium Vanadium Chromium Manganese Iron Cobalt Nickel Copper Zinc Gallium Germanium Arsenic Selenium Bromine Krypton Rubidium Strontium Yttrium Zirconium Niobium Molybdenum Technetium Ruthenium Rhodium Palladium Silver Cadmium Indium Tin Antimony Tellurium Iodine Xenon Caesium Barium Lanthanum Cerium Praseodymium Neodymium Promethium Samarium Europium Gadolinium Terbium Dysprosium Holmium Erbium Thulium Ytterbium Lutetium Hafnium Tantalum Tungsten Rhenium Osmium Iridium Platinum Gold Mercury Thallium Lead Bismuth Polonium Astatine Radon Francium Radium Actinium Thorium Protactinium Uranium Neptunium Plutonium Americium Curium Berkelium Californium Einsteinium Fermium"

## Old or wrong words, and what the game says instead.
const BANNED := {
	"\\b[Pp]ot(s|ted|ting)?\\b": "say sink",
	"\\b[Dd]rop(s|ped|ping)?\\b": "say sink (or slow/reset)",
	"\\b[Pp]erks?\\b": "say Element",
	"\\b[Ii]mbue[ds]?\\b": "say Isotope",
	"\\b[Ii]tems?\\b": "say Catalyst",
	"\\b[Ss]pecial balls?\\b": "say Exotic ball",
	"\\b[Cc]onsumables?\\b": "every Catalyst recharges",
}


func check(c: bool, m: String) -> void:
	if not c:
		print("  FAIL ", m)
		failures += 1


func _initialize() -> void:
	var texts := {}
	for kind in ["PERKS", "ITEMS", "IMBUES", "BALL_TYPES", "CUES", "BOSSES", "DISCOVERIES"]:
		var data: Dictionary = KINDS[kind]
		for id in data:
			var e = data[id]
			if e is Dictionary:
				for f in ["name", "desc", "hint"]:
					if e.has(f):
						texts["%s.%s.%s" % [kind, id, f]] = String(e[f])
	for id in Catalog.BOUNTIES:
		texts["BOUNTIES.%s" % id] = String(Catalog.BOUNTIES[id].name)
	for id in Glossary.TERMS:
		texts["TERMS.%s" % id] = String(Glossary.TERMS[id].text)
	for id in TileArt.TILES:
		for f in ["stat", "on"]:
			if TileArt.TILES[id].has(f):
				texts["TILES.%s.%s" % [id, f]] = String(TileArt.TILES[id][f])
	print("the game's own words (%d texts)" % texts.size())
	var res := {}
	for rx in BANNED:
		res[rx] = RegEx.create_from_string(rx)
	for where in texts:
		for rx in BANNED:
			var m: RegExMatch = res[rx].search(texts[where])
			check(m == null, "%s says '%s' (%s): %s" % [where, m.get_string() if m else "", BANNED[rx], texts[where]])
		if where.ends_with(".desc"):
			check(not texts[where].contains("  "), "%s has a double space" % where)

	print("no two things share a name")
	var seen := {}
	for kind in ["PERKS", "ITEMS", "IMBUES", "BALL_TYPES", "CUES", "BOSSES"]:
		var data: Dictionary = KINDS[kind]
		for id in data:
			var n := String(data[id].name).to_lower()
			check(not seen.has(n), "'%s' is both %s and %s.%s" % [n, seen.get(n, ""), kind, id])
			seen[n] = "%s.%s" % [kind, id]

	print("every Element is its real element")
	var sym := SYMBOLS.split(" ")
	var names := NAMES.split(" ")
	var zs := {}
	for id in Catalog.PERKS:
		var p: Dictionary = Catalog.PERKS[id]
		var z := int(p.z)
		check(z >= 1 and z <= 100 and not zs.has(z), "%s has its own atomic number (%d)" % [id, z])
		zs[z] = true
		check(String(p.name).begins_with(names[z - 1]), "%s is named for element %d, %s: '%s'" % [id, z, names[z - 1], p.name])
		var t: Dictionary = TileArt.TILES.get("perk:" + id, {})
		check(t.get("sym", "") == sym[z - 1], "%s's card shows %s (shows '%s')" % [id, sym[z - 1], t.get("sym", "")])

	print("starting cues say what they carry")
	for id in Catalog.CUES:
		var c: Dictionary = Catalog.CUES[id]
		var desc := String(c.desc)
		check(desc.contains("$%d" % int(c.money)), "%s says its money ($%d): %s" % [id, int(c.money), desc])
		for tool in c.get("tools", []):
			check(desc.contains(String(Catalog.ITEMS[tool].name)), "%s names its Catalyst %s" % [id, Catalog.ITEMS[tool].name])
		for b in c.get("add", []):
			check(desc.contains(String(Catalog.BALL_TYPES[b].name)), "%s names its %s ball" % [id, Catalog.BALL_TYPES[b].name])
	print("wording tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
