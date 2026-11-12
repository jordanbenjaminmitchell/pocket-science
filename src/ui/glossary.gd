class_name Glossary
extends RefCounted
## One-sentence definitions for the game's terms, and the markup that makes those
## words tappable wherever they appear in Perk and table text.

const LINK_COLOR := "#8fd8ff"

const TERMS := {
	"sink": {"title": "Sink", "text": "To knock a numbered ball into a pocket."},
	"score": {"title": "Score", "text": "The points a ball earns as it sinks: value × Chain × Heat, times any other multipliers."},
	"pay": {"title": "Pay", "text": "Money you earn, always shown with a $ sign."},
	"value": {"title": "Value", "text": "What a ball is worth before multipliers: 10 plus twice its number."},
	"chain": {"title": "Chain", "text": "Multiplies balls within one shot: ×1 to start, and +0.5 for every ball sunk before it."},
	"heat": {"title": "Heat", "text": "Multiplies every ball sunk this table; each scoring shot adds 1 Heat (+0.5×) and a miss halves it."},
	"on_fire": {"title": "On fire", "text": "Heat 5 or more, after Warm (1-2) and In stroke (3-4), with Dead stroke at 7+."},
	"bank": {"title": "Bank", "text": "A sink where the ball touches a cushion before it sinks."},
	"cushion": {"title": "Cushion", "text": "The padded rail around the edge of the table."},
	"combination": {"title": "Combination", "text": "The cue ball hits one ball, and that ball knocks another one into a pocket."},
	"kick": {"title": "Kick shot", "text": "The cue ball hits a cushion before it touches any ball, often to get round a blocker."},
	"clean": {"title": "Clean sink", "text": "A sink straight from the cue ball, with no cushions or other balls involved."},
	"hot": {"title": "Hot pocket", "text": "The glowing pocket, which scores ×2 and moves after each shot."},
	"chalk": {"title": "Chalk", "text": "Your lives on a table: a miss or scratch costs one, and at zero the run ends."},
	"scratch": {"title": "Scratch", "text": "Knocking the cue ball into a pocket."},
	"miss": {"title": "Miss", "text": "A shot that sinks nothing."},
	"break": {"title": "Break", "text": "The first shot at a fresh rack."},
	"rack": {"title": "Rack", "text": "The full set of 15 balls at the start of a table."},
	"solid": {"title": "Solids", "text": "Balls 1 to 7, coloured all over."},
	"stripe": {"title": "Stripes", "text": "Balls 9 to 15, with a coloured band around the middle."},
	"eight": {"title": "The 8-ball", "text": "Avoid it: sinking the 8 while other balls remain costs 15% of the table's target."},
	"perk": {"title": "Element", "text": "A passive item that sits in one of your six slots."},
	"imbue": {"title": "Isotope", "text": "An upgrade that stays on one ball all run; each ball holds one, and a loose Isotope lets you pick which."},
	"side_bet": {"title": "Side bet", "text": "An optional goal on each table that pays extra money."},
	"english": {"title": "English", "text": "Spin from hitting the cue ball left or right of centre."},
	"target": {"title": "Target", "text": "The score you must reach to clear this table."},
}

## Words as they appear in text, mapped to the term they open.
const WORDS := {
	"sink": "sink", "sinks": "sink", "sunk": "sink", "sinking": "sink",
	"score": "score", "scores": "score", "pay": "pay", "pays": "pay", "worth": "value", "value": "value",
	"chain": "chain", "heat": "heat", "on fire": "on_fire",
	"bank": "bank", "banks": "bank", "cushion": "cushion", "cushions": "cushion",
	"combination": "combination", "combinations": "combination",
	"kick": "kick", "kick shots": "kick", "clean": "clean", "hot pocket": "hot",
	"chalk": "chalk", "scratch": "scratch", "scratches": "scratch", "miss": "miss", "misses": "miss",
	"break": "break", "rack": "rack",
	"solid": "solid", "solids": "solid", "stripe": "stripe", "stripes": "stripe", "striped": "stripe",
	"the 8": "eight", "8-ball": "eight",
	"perk": "perk", "perks": "perk", "element": "perk", "elements": "perk", "imbue": "imbue", "imbues": "imbue", "isotope": "imbue", "isotopes": "imbue",
	"side bet": "side_bet", "side bets": "side_bet", "english": "english", "target": "target",
}

static var _pattern: RegEx


static func title(term: String) -> String:
	return TERMS[term].title


static func sentence(term: String) -> String:
	return TERMS[term].text


## Returns BBCode with the first use of each known term made into a link.
static func link(plain: String) -> String:
	if _pattern == null:
		var words: Array = WORDS.keys()
		words.sort_custom(func(a, b): return a.length() > b.length())   # "kick shots" before "kick"
		_pattern = RegEx.create_from_string("(?i)\\b(" + "|".join(words) + ")\\b")
	var out := ""
	var at := 0
	var seen := {}
	for m in _pattern.search_all(plain):
		var term: String = WORDS[m.get_string(1).to_lower()]
		if seen.has(term):
			continue
		seen[term] = true
		out += plain.substr(at, m.get_start() - at)
		out += "[url=%s][color=%s]%s[/color][/url]" % [term, LINK_COLOR, m.get_string()]
		at = m.get_end()
	return out + plain.substr(at)
