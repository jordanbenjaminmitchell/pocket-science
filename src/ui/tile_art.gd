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
## Perks show their family instead of "on". Symbols follow the rules in
## docs/card-art/NEEDED.md: a real element only where it genuinely fits (Au, Fe,
## Pb), otherwise initials (FT for Follow Through), or a one-word name's first
## letter, then its first two. Side bets show a picture instead of letters.
const TILES := {
	# Physics
	"perk:velvet": {"sym": "V", "stat": "Balls roll 30% further", "letter": "velvet"},
	"perk:featherweight": {"sym": "H", "stat": "Object balls 30% lighter", "letter": "feather"},
	"perk:heavyhit": {"sym": "Os", "stat": "Cue ball 30% heavier", "letter": "heavy"},
	"perk:liverails": {"sym": "N", "stat": "Bouncier cushions", "letter": "spring"},
	"perk:slowcloth": {"sym": "Tl", "stat": "Balls stop 25% sooner", "letter": "brake"},
	"perk:backspin": {"sym": "Ba", "stat": "Spin 50% stronger", "letter": "spin"},
	"perk:bigbreak": {"sym": "Rn", "stat": "Breaks 25% harder", "letter": "shatter"},
	"perk:longarm": {"sym": "Mo", "stat": "Full power +15%", "letter": "reach"},
	# Cue control
	"perk:kick": {"sym": "K", "stat": "Kick shots ×2", "letter": "kick"},
	"perk:power": {"sym": "U", "stat": "Power hits fly 20% faster", "letter": "power"},
	"perk:finesse": {"sym": "In", "stat": "Soft shots ×2", "letter": "soft"},
	"perk:boomerang": {"sym": "Br", "stat": "Cue comes home: ×2", "letter": "boomerang"},
	"perk:precision": {"sym": "Cl", "stat": "Clean sinks +1 Chain", "letter": "crosshair"},
	"perk:stun": {"sym": "Th", "stat": "Cue stops on contact", "letter": "stun"},
	"perk:afterburner": {"sym": "Bk", "stat": "Break from anywhere", "letter": "breakup"},
	"perk:masse": {"sym": "Mn", "stat": "Double english swerve", "letter": "swerve"},
	"perk:followthru": {"sym": "Fr", "stat": "2+ sinks save a scratch", "letter": "follow"},
	"perk:drawartist": {"sym": "Yb", "stat": "Draw shots ×1.5", "letter": "sketch"},
	# Combos & clusters
	"perk:elastic": {"sym": "Nd", "stat": "Magnetic cue ball", "letter": "ndmagnet"},
	"perk:chain": {"sym": "S", "stat": "Combinations ×2", "letter": "links"},
	"perk:multi": {"sym": "B", "stat": "Extra sinks +1 Chain", "letter": "cluster"},
	"perk:supernova": {"sym": "Ni", "stat": "3+ sinks: all ×2", "letter": "sweep"},
	"perk:fusion": {"sym": "He", "stat": "Same pocket twice: ×3", "letter": "merge"},
	"perk:domino": {"sym": "Dy", "stat": "Hits keep their speed", "letter": "topple"},
	# Streaks
	"perk:streak": {"sym": "P", "stat": "2+ sinks: +1 Heat", "letter": "stoke"},
	"perk:rhythm": {"sym": "Rh", "stat": "Every 3rd shot ×2", "letter": "beat"},
	"perk:comeback": {"sym": "La", "stat": "Last Chalk: sinks ×2", "letter": "stub"},
	# Heat
	"perk:entropy": {"sym": "Sm", "stat": "Low Heat: +1 Chain", "letter": "simmer"},
	"perk:hothand": {"sym": "Ho", "stat": "Heat 3+: pockets pull", "letter": "pole"},
	"perk:migration": {"sym": "Hf", "stat": "On fire: misses cost 1", "letter": "glow"},
	"perk:coupon": {"sym": "Cd", "stat": "Heat 0: sinks ×2", "letter": "frost"},
	"perk:minimalist": {"sym": "Ir", "stat": "On fire: sinks ×2", "letter": "inferno"},
	# Pockets
	"perk:corner": {"sym": "Cm", "stat": "Corners +0.5 Chain", "letter": "corner"},
	"perk:side": {"sym": "Sr", "stat": "Side pockets ×2", "letter": "door"},
	"perk:jaws": {"sym": "Ti", "stat": "Pockets 12% wider", "letter": "jaws"},
	"perk:heat": {"sym": "Mg", "stat": "Hot pocket ×3, +30", "letter": "scorch"},
	"perk:magnet": {"sym": "Gd", "stat": "Pockets pull balls in", "letter": "magnet"},
	"perk:collector": {"sym": "Ga", "stat": "Cue ball rolls further", "letter": "glide"},
	# Ball numbers
	"perk:odd": {"sym": "F", "stat": "Odd balls +20", "letter": "odd"},
	"perk:even": {"sym": "Er", "stat": "Even balls +0.75 Chain", "letter": "even"},
	"perk:prime": {"sym": "Pm", "stat": "Prime balls ×2", "letter": "cut"},
	"perk:fibonacci": {"sym": "Fm", "stat": "Fibonacci balls +35", "letter": "spiral"},
	"perk:rotation": {"sym": "Pr", "stat": "Lowest scores highest", "letter": "rotate"},
	"perk:moneyball": {"sym": "Cf", "stat": "Numbers count ×3", "letter": "tall"},
	# Solids
	"perk:solids": {"sym": "Si", "stat": "Solids +35", "letter": "plate"},
	"perk:solidgold": {"sym": "Au", "stat": "Solids pay $1", "letter": "ingot"},
	"perk:bedrock": {"sym": "Al", "stat": "All-solid shots: +Heat", "letter": "strata"},
	"perk:steadyrun": {"sym": "Y", "stat": "Solid streaks add value", "letter": "steps"},
	"perk:solidsonly": {"sym": "Ta", "stat": "Solids ×3, stripes ×0.5", "letter": "only"},
	"perk:lastsolid": {"sym": "Bi", "stat": "Last solid ×8", "letter": "spotlight"},
	"perk:lowball": {"sym": "Li", "stat": "Balls 1–3 keep speed", "letter": "limbo"},
	# Stripes
	"perk:stripes": {"sym": "Cr", "stat": "Stripes ×1.5", "letter": "band"},
	"perk:racing": {"sym": "Rb", "stat": "Light, fast stripes", "letter": "racing"},
	"perk:luckystripe": {"sym": "Lu", "stat": "Stripes: 1 in 3 ×3", "letter": "clover"},
	"perk:tiger": {"sym": "Tb", "stat": "Stripe streaks: +Chain", "letter": "tiger"},
	"perk:stripesonly": {"sym": "Zr", "stat": "Stripes ×2, solids ×0.5", "letter": "pinstripe"},
	"perk:laststripe": {"sym": "Pb", "stat": "8 weighs 300%, stays up", "letter": "anchor8"},
	"perk:highball": {"sym": "Ac", "stat": "Balls 13–15 ×2.5", "letter": "dice"},
	# The 8-ball
	"perk:eight": {"sym": "C", "stat": "The 8 is safe, $3", "letter": "behind"},
	"perk:darkhorse": {"sym": "O", "stat": "The 8 scores ×8", "letter": "dark"},
	"perk:hushmoney": {"sym": "Ag", "stat": "Early 8 costs $3", "letter": "hush"},
	"perk:kissblack": {"sym": "Sb", "stat": "Touch the 8: +Chain", "letter": "kiss"},
	"perk:steerclear": {"sym": "Ne", "stat": "Miss the 8: +Chain", "letter": "steer"},
	"perk:lastcall": {"sym": "Po", "stat": "Last 8 pulled in, ×5", "letter": "neon"},
	"perk:eightcount": {"sym": "Kr", "stat": "Every 8th sink ×3", "letter": "tally"},
	"perk:trouble": {"sym": "Pu", "stat": "Early 8: +3 Heat", "letter": "hazard"},
	# Banks & cushions
	"perk:bank": {"sym": "Pt", "stat": "Banks +1 Chain a rail", "letter": "banknote"},
	"perk:ricochet": {"sym": "Re", "stat": "Every rail +0.25 Chain", "letter": "ricochet"},
	"perk:cushion": {"sym": "Na", "stat": "Bank sinks +30", "letter": "pillow"},
	"perk:geometry": {"sym": "Ge", "stat": "Banks ×1.5 a rail", "letter": "angles"},
	"perk:tracer": {"sym": "Ra", "stat": "Cue rails +0.25 Chain", "letter": "trace"},
	# Utility
	"perk:lever": {"sym": "W", "stat": "Stripes 140%, keep speed", "letter": "core"},
	"perk:chalk": {"sym": "Ca", "stat": "+1 Chalk a clear", "letter": "chalky"},
	"perk:lens": {"sym": "Se", "stat": "Long sinks +1 Chain", "letter": "lens"},
	"perk:insurance": {"sym": "Ar", "stat": "2 free misses a table", "letter": "shield"},
	"perk:oracle": {"sym": "Te", "stat": "See a shot's score", "letter": "eye"},
	# Economy
	"perk:gold": {"sym": "Cu", "stat": "$1 a sink, max $3", "letter": "rail"},
	"perk:thrift": {"sym": "Ce", "stat": "Spare Chalk pays $5", "letter": "tag"},
	"perk:venture": {"sym": "Pd", "stat": "Cash builds Chain", "letter": "deep"},
	"perk:hunter": {"sym": "Sc", "stat": "Side bets pay double", "letter": "hustle"},
	"perk:overflow": {"sym": "Np", "stat": "Extra points carry over", "letter": "beaker"},
	# Risk & scaling
	"perk:catalyst": {"sym": "Be", "stat": "Every sink: all +0.75", "letter": "snowball"},
	"perk:golden": {"sym": "Fe", "stat": "First sink ×2", "letter": "drip"},
	"perk:glasscannon": {"sym": "At", "stat": "Sinks ×2, fouls cost +1", "letter": "chips"},
	"perk:echo": {"sym": "Eu", "stat": "First sink counts twice", "letter": "double"},
	# Clearing your set
	"perk:thinrack": {"sym": "Tm", "stat": "Removed balls: all +12", "letter": "thin"},
	"perk:missing": {"sym": "Tc", "stat": "Removed balls: +Chain", "letter": "missing"},
	"perk:cleanhouse": {"sym": "I", "stat": "Free ball removal", "letter": "clean"},
	# Gear, imbues, special balls
	"perk:packrat": {"sym": "Pa", "stat": "+1 Catalyst slot", "letter": "slots"},
	"perk:quartermaster": {"sym": "Zn", "stat": "Catalysts $1 cheaper", "letter": "stencil"},
	"perk:tinkerer": {"sym": "Sn", "stat": "+1 Catalyst use", "letter": "cog"},
	"perk:enchanter": {"sym": "Es", "stat": "Isotopes $2 cheaper", "letter": "enchant"},
	"perk:secondcoat": {"sym": "Co", "stat": "Isotope balls ×1.5", "letter": "coat"},
	"perk:goldrush": {"sym": "Ru", "stat": "Special balls ×2", "letter": "nuggets"},
	"perk:menagerie": {"sym": "Nb", "stat": "Specials owned: +Chain", "letter": "menagerie"},
	"perk:alchemy": {"sym": "As", "stat": "Plain balls mutate", "letter": "transmute"},
	# Pausing
	"perk:stillness": {"sym": "Xe", "stat": "First pause: balls +30%", "letter": "still"},
	"perk:quickhands": {"sym": "Hg", "stat": "First Catalyst free", "letter": "blur"},
	"perk:afterimage": {"sym": "Am", "stat": "Cue Catalysts +Chain", "letter": "chroma"},
	"perk:overclock": {"sym": "Cs", "stat": "Catalysts used twice", "letter": "chip"},
	# Imbues, special balls and items made with the first five samples
	"imbue:vein": {"sym": "Ve", "stat": "+20, spreads", "letter": "veins"},
	"ball:gold": {"sym": "", "stat": "45 pts", "on": "Cushions", "letter": "gold"},
	"item:secondstrike": {"sym": "Im", "stat": "Hit again", "on": "Cue ball", "letter": "echo"},
	"item:trapdoor": {"sym": "BH", "stat": "+1 pocket", "on": "Cushion", "letter": "blackhole"},
	# Imbues
	"imbue:spark": {"sym": "Sk", "stat": "+1 Chain a hit", "letter": "spark"},
	"imbue:gold": {"sym": "G", "stat": "$1, +$1 a table", "letter": "gilt"},
	"imbue:heavy": {"sym": "We", "stat": "Number ×3, ×4…", "letter": "weights"},
	"imbue:glass": {"sym": "Ha", "stat": "×3, may crack", "letter": "hairline"},
	"imbue:ember": {"sym": "Ki", "stat": "+2 Heat", "letter": "kindle"},
	"imbue:lucky": {"sym": "L", "stat": "1 in 2: ×2", "letter": "horseshoe"},
	"imbue:volatile": {"sym": "Vo", "stat": "Explodes on hit", "letter": "volatile"},
	"imbue:jinxed": {"sym": "J", "stat": "×4, halves Heat", "letter": "jinx"},
	"imbue:mirror": {"sym": "M", "stat": "Copies its hitter", "letter": "mirror"},
	"imbue:pawned": {"sym": "Pw", "stat": "$4, no points", "letter": "pawn"},
	"imbue:frosted": {"sym": "Ft", "stat": "Next miss safe", "letter": "frosted"},
	"imbue:magnetic": {"sym": "Ma", "stat": "Pockets pull it", "letter": "poles"},
	"imbue:charged": {"sym": "Ch", "stat": "+0.5 Chain a rail", "letter": "battery"},
	"imbue:prismatic": {"sym": "R", "stat": "+0.25 a touch", "letter": "resonance"},
	"imbue:hollow": {"sym": "Hl", "stat": "50% weight", "letter": "hollow"},
	"imbue:leaded": {"sym": "Le", "stat": "200% weight, +45", "letter": "lead"},
	"imbue:bounty": {"sym": "Bo", "stat": "$1 per Heat", "letter": "wanted"},
	"imbue:starry": {"sym": "Sy", "stat": "+0.5 to the rest", "letter": "starry"},
	"imbue:twin": {"sym": "Tw", "stat": "Counts twice", "letter": "twin"},
	# Special balls
	"ball:void": {"sym": "", "stat": "Others ×2", "on": "Same shot", "letter": "void"},
	"ball:glass": {"sym": "", "stat": "×3, shatters", "on": "Hard hits", "letter": "glass"},
	"ball:iron": {"sym": "", "stat": "Worth 70", "on": "200% weight", "letter": "iron"},
	"ball:feather": {"sym": "", "stat": "+0.5 Chain", "on": "25% weight", "letter": "plume"},
	"ball:ember": {"sym": "", "stat": "Hot pocket", "on": "Its pocket", "letter": "coal"},
	"ball:frost": {"sym": "", "stat": "Stops balls dead", "on": "Touch", "letter": "iceblock"},
	"ball:magnet": {"sym": "", "stat": "Pulls balls", "on": "Nearby balls", "letter": "pull"},
	"ball:prism": {"sym": "", "stat": "Solid + stripe", "on": "Both sets", "letter": "prism"},
	"ball:wild": {"sym": "", "stat": "Copies a number", "on": "Last sunk", "letter": "wild"},
	"ball:clock": {"sym": "", "stat": "15, +9 a shot", "on": "Shots taken", "letter": "clock"},
	"ball:coin": {"sym": "", "stat": "$1 a cue hit", "on": "Cue ball", "letter": "coin"},
	"ball:bomb": {"sym": "", "stat": "Takes one down", "on": "Nearest ball", "letter": "bomb"},
	"ball:seed": {"sym": "", "stat": "30, +15 a sink", "on": "Whole run", "letter": "sprout"},
	"ball:clover": {"sym": "", "stat": "No Chalk lost", "on": "Its shots", "letter": "bigclover"},
	"ball:star": {"sym": "", "stat": "+1 Chain", "on": "Cushions", "letter": "star"},
	"ball:heart": {"sym": "", "stat": "+1 Chalk", "on": "Last ball", "letter": "heart"},
	"ball:dice": {"sym": "", "stat": "1–15 each shot", "on": "Its number", "letter": "die"},
	"ball:moon": {"sym": "", "stat": "×2 in a side", "on": "Side pockets", "letter": "moon"},
	"ball:sun": {"sym": "", "stat": "×2 in a corner", "on": "Corners", "letter": "sun"},
	"ball:anchor": {"sym": "", "stat": "Worth 105", "on": "Cue ball only", "letter": "anchor"},
	"ball:eraser": {"sym": "", "stat": "$4, erases two", "on": "Last touched", "letter": "erase"},
	"ball:echo": {"sym": "", "stat": "Comes back once", "on": "Foot spot", "letter": "return"},
	"ball:comet": {"sym": "", "stat": "No friction", "on": "Till a cushion", "letter": "comet"},
	# The Hustler's Kit
	"item:centremass": {"sym": "CM", "stat": "Pull together", "on": "2 to 4 balls", "letter": "centre"},
	"item:ghostchalk": {"sym": "QT", "stat": "Pass through", "on": "One ball", "letter": "ghost"},
	"item:swap": {"sym": "En", "stat": "Swap two balls", "on": "Two balls", "letter": "swap"},
	"item:polish": {"sym": "ZF", "stat": "Glides free", "on": "One ball", "letter": "chrome"},
	"item:leadweight": {"sym": "MS", "stat": "400% weight", "on": "One ball", "letter": "kettle"},
	"item:spotter": {"sym": "Cn", "stat": "Respot a ball", "on": "Foot spot", "letter": "spot"},
	"item:pocketcover": {"sym": "EH", "stat": "×2 wide", "on": "One pocket", "letter": "horizon"},
	"item:wall": {"sym": "FF", "stat": "Raise a wall", "on": "This shot", "letter": "field"},
	"item:blink": {"sym": "Sp", "stat": "Move the cue", "on": "Cue ball", "letter": "blink"},
	"item:freezeframe": {"sym": "It", "stat": "Stop one dead", "on": "One ball", "letter": "film"},
	"item:nudge": {"sym": "Vc", "stat": "Push one ball", "on": "One ball", "letter": "nudge"},
	"item:englishdial": {"sym": "ST", "stat": "Add your spin", "on": "Cue ball", "letter": "dial"},
	"item:gravitypebble": {"sym": "GW", "stat": "Bends balls", "on": "This shot", "letter": "warp"},
	"item:rewind": {"sym": "TR", "stat": "Retake shot", "on": "This shot", "letter": "rewind"},
	"item:reflection": {"sym": "Rf", "stat": "Turn back", "on": "One ball", "letter": "reflect"},
	"item:pythagoras": {"sym": "PT", "stat": "Triangle walls", "on": "Three balls", "letter": "triple"},
	"item:newton": {"sym": "NC", "stat": "Take momentum", "on": "One ball", "letter": "cradle"},
	"item:post": {"sym": "FP", "stat": "Place a post", "on": "This table", "letter": "post"},
	"item:portal": {"sym": "Wh", "stat": "Linked portals", "on": "Rolling balls", "letter": "portal"},
	"item:goldenratio": {"sym": "GR", "stat": "Speed ×1.618", "on": "One ball", "letter": "phi"},
	"item:hookes": {"sym": "HL", "stat": "No speed lost", "on": "One cushion", "letter": "coil"},
	# Side bets: a picture of the bet instead of letters, and a shared card back
	"bet:solid": {"sym": "", "title": "Any solid", "stat": "Wins 1× stake", "on": "Balls", "letter": "b_solid"},
	"bet:stripe": {"sym": "", "title": "Any stripe", "stat": "Wins 1× stake", "on": "Balls", "letter": "b_stripe"},
	"bet:corner": {"sym": "", "title": "Corner pocket", "stat": "Wins 1× stake", "on": "Pockets", "letter": "b_corner"},
	"bet:side": {"sym": "", "title": "Side pocket", "stat": "Wins 1× stake", "on": "Pockets", "letter": "b_side"},
	"bet:hot": {"sym": "", "title": "Hot pocket", "stat": "Wins 1× stake", "on": "Pockets", "letter": "b_hot"},
	"bet:breakpot": {"sym": "", "title": "Sink on the break", "stat": "Wins 1× stake", "on": "The break", "letter": "b_breakpot"},
	"bet:hard": {"sym": "", "title": "Power sink, 85%+", "stat": "Wins 1× stake", "on": "Power", "letter": "b_hard"},
	"bet:soft": {"sym": "", "title": "Soft sink, 35% or less", "stat": "Wins 1× stake", "on": "Power", "letter": "b_soft"},
	"bet:heat3": {"sym": "", "title": "Reach Heat 3", "stat": "Wins 1× stake", "on": "Heat", "letter": "b_heat3"},
	"bet:double": {"sym": "", "title": "Two in one shot", "stat": "Wins 2× stake", "on": "One shot", "letter": "b_double"},
	"bet:bank": {"sym": "", "title": "Bank shot", "stat": "Wins 2× stake", "on": "Cushions", "letter": "b_bank"},
	"bet:combo": {"sym": "", "title": "Combination", "stat": "Wins 2× stake", "on": "One shot", "letter": "b_combo"},
	"bet:kick": {"sym": "", "title": "Kick shot", "stat": "Wins 2× stake", "on": "Cushions", "letter": "b_kick"},
	"bet:heat4": {"sym": "", "title": "Reach Heat 4", "stat": "Wins 2× stake", "on": "Heat", "letter": "b_heat4"},
	"bet:chain5": {"sym": "", "title": "Chain 5 in one shot", "stat": "Wins 2× stake", "on": "Chain", "letter": "b_chain5"},
	"bet:quarter": {"sym": "", "title": "Quarter of the target", "stat": "Wins 2× stake", "on": "One shot", "letter": "b_quarter"},
	"bet:triple": {"sym": "", "title": "Three in one shot", "stat": "Wins 3× stake", "on": "One shot", "letter": "b_triple"},
	"bet:bank2": {"sym": "", "title": "Two-cushion bank", "stat": "Wins 3× stake", "on": "Cushions", "letter": "b_bank2"},
	"bet:heat5": {"sym": "", "title": "Reach Heat 5", "stat": "Wins 3× stake", "on": "Heat", "letter": "b_heat5"},
	"bet:chain7": {"sym": "", "title": "Chain 7 in one shot", "stat": "Wins 3× stake", "on": "Chain", "letter": "b_chain7"},
	"bet:half": {"sym": "", "title": "Half the target", "stat": "Wins 3× stake", "on": "One shot", "letter": "b_half"},
	"bet:hot2": {"sym": "", "title": "Two in the hot pocket", "stat": "Wins 3× stake", "on": "One shot", "letter": "b_hot2"},
	"bet:eight": {"sym": "", "title": "Last-ball 8", "stat": "Wins 3× stake", "on": "The 8-ball", "letter": "b_eight"},
	# Starting cues: a picture of the cue; stat is what it starts with, "on" the starting money.
	"cue:maple": {"sym": "", "stat": "All-rounder", "on": "$6"},
	"cue:hotrod": {"sym": "", "stat": "Mg, −1 Chalk", "on": "$4"},
	"cue:gilded": {"sym": "", "stat": "Rich start + Pd", "on": "$12"},
	"cue:gearhead": {"sym": "", "stat": "Pa + 2 Catalysts", "on": "$2"},
	"cue:lean": {"sym": "", "stat": "Tm, 1 and 2 out", "on": "$3"},
	"cue:black": {"sym": "", "stat": "C: the 8 is safe", "on": "$3"},
	"cue:alchemist": {"sym": "", "stat": "Gold ball + Ru", "on": "$3"},
	"cue:glass": {"sym": "", "stat": "At, −1 Chalk", "on": "$4"},
	"cue:posts": {"sym": "", "stat": "Posts + K", "on": "$2"},
	"cue:portals": {"sym": "", "stat": "Wormholes + Br", "on": "$2"},
	"cue:walls": {"sym": "", "stat": "Force Fields + Pt", "on": "$2"},
	"cue:trapdoors": {"sym": "", "stat": "Black Holes + Na", "on": "$2"},
	"cue:gravity": {"sym": "", "stat": "Wells + Gd", "on": "$2"},
	"bet:back": {"sym": "", "title": "Side bet", "stat": "Bet, peek or pass", "on": "This table", "letter": "b_back"},
}
## Elements: each card's periodic-table group (shown as the colour of its
## atomic-number chip) and what the element looks like, which colours its
## lettering: [kind, light, dark]. Kinds: metal (polished, tinted to the real
## metal), gas (a glowing discharge tube), crystal (a sheen across), liquid
## (metal that drips), powder (chalky), radio (glows, and gives off particles),
## rainbow (bismuth's oxide film). Gold (79) keeps its gold ingot.
const GROUP_COLORS := {
	"alkali": Color(1.0, 0.47, 0.42), "alkaline": Color(1.0, 0.72, 0.38), "transition": Color(0.98, 0.62, 0.74),
	"post": Color(0.64, 0.77, 0.93), "metalloid": Color(0.42, 0.86, 0.76), "nonmetal": Color(0.58, 0.9, 0.46),
	"halogen": Color(1.0, 0.9, 0.42), "noble": Color(0.76, 0.64, 1.0), "lanthanide": Color(0.44, 0.83, 0.98),
	"actinide": Color(0.96, 0.52, 0.96),
}
const GROUP_NAMES := {
	"alkali": "Alkali metal", "alkaline": "Alkaline earth", "transition": "Transition metal", "post": "Post-transition metal",
	"metalloid": "Metalloid", "nonmetal": "Nonmetal", "halogen": "Halogen", "noble": "Noble gas",
	"lanthanide": "Lanthanide", "actinide": "Actinide",
}
const ELEMENT_LOOK := {
	1: ["gas", Color(1.0, 0.62, 0.88)],
	2: ["gas", Color(1.0, 0.78, 0.55)],
	3: ["metal", Color(0.92, 0.92, 0.88), Color(0.5, 0.5, 0.48)],
	4: ["metal", Color(0.82, 0.86, 0.9), Color(0.36, 0.4, 0.46)],
	5: ["metal", Color(0.66, 0.58, 0.52), Color(0.26, 0.22, 0.2)],
	6: ["metal", Color(0.74, 0.74, 0.78), Color(0.18, 0.18, 0.2)],
	7: ["gas", Color(0.76, 0.62, 1.0)],
	8: ["gas", Color(0.55, 0.8, 1.0)],
	9: ["gas", Color(1.0, 0.96, 0.55)],
	10: ["gas", Color(1.0, 0.42, 0.26)],
	11: ["metal", Color(0.95, 0.95, 0.9), Color(0.56, 0.56, 0.52)],
	12: ["metal", Color(1, 1, 1), Color(0.6, 0.62, 0.66)],
	13: ["metal", Color(0.9, 0.92, 0.95), Color(0.5, 0.53, 0.58)],
	14: ["crystal", Color(0.66, 0.72, 0.9), Color(0.3, 0.33, 0.45)],
	15: ["gas", Color(0.62, 1.0, 0.6)],
	16: ["crystal", Color(1.0, 0.9, 0.3), Color(0.85, 0.65, 0.1)],
	17: ["gas", Color(0.78, 0.95, 0.38)],
	18: ["gas", Color(0.78, 0.56, 1.0)],
	19: ["metal", Color(0.92, 0.92, 0.95), Color(0.5, 0.5, 0.56)],
	20: ["powder", Color(0.97, 0.96, 0.92), Color(0.7, 0.7, 0.66)],
	21: ["metal", Color(0.95, 0.92, 0.8), Color(0.5, 0.47, 0.38)],
	22: ["metal", Color(0.85, 0.86, 0.88), Color(0.38, 0.4, 0.42)],
	23: ["metal", Color(0.78, 0.82, 0.9), Color(0.34, 0.38, 0.46)],
	24: ["metal", Color(1, 1, 1), Color(0.3, 0.32, 0.38)],
	25: ["metal", Color(0.88, 0.86, 0.86), Color(0.45, 0.42, 0.42)],
	26: ["metal", Color(0.82, 0.8, 0.8), Color(0.35, 0.32, 0.32)],
	27: ["metal", Color(0.55, 0.66, 1.0), Color(0.16, 0.25, 0.62)],
	28: ["metal", Color(0.92, 0.9, 0.82), Color(0.48, 0.46, 0.4)],
	29: ["metal", Color(1.0, 0.66, 0.46), Color(0.6, 0.28, 0.16)],
	30: ["metal", Color(0.84, 0.9, 0.96), Color(0.42, 0.48, 0.56)],
	31: ["liquid", Color(0.9, 0.93, 0.98), Color(0.45, 0.5, 0.6)],
	32: ["crystal", Color(0.84, 0.86, 0.9), Color(0.4, 0.42, 0.46)],
	33: ["metal", Color(0.76, 0.78, 0.8), Color(0.3, 0.32, 0.34)],
	34: ["crystal", Color(1.0, 0.48, 0.44), Color(0.6, 0.15, 0.15)],
	35: ["liquid", Color(0.95, 0.45, 0.24), Color(0.5, 0.14, 0.06)],
	36: ["gas", Color(0.86, 0.92, 1.0)],
	37: ["metal", Color(0.94, 0.92, 0.9), Color(0.5, 0.48, 0.46)],
	38: ["metal", Color(0.98, 0.9, 0.84), Color(0.56, 0.42, 0.36)],
	39: ["metal", Color(0.92, 0.93, 0.95), Color(0.44, 0.47, 0.52)],
	40: ["metal", Color(0.88, 0.88, 0.86), Color(0.44, 0.44, 0.42)],
	41: ["metal", Color(0.74, 0.7, 1.0), Color(0.3, 0.28, 0.6)],
	42: ["metal", Color(0.86, 0.87, 0.9), Color(0.4, 0.42, 0.46)],
	43: ["radio", Color(0.55, 1.0, 0.6)],
	44: ["metal", Color(0.9, 0.9, 0.92), Color(0.44, 0.44, 0.48)],
	45: ["metal", Color(1, 1, 1), Color(0.55, 0.57, 0.62)],
	46: ["metal", Color(0.96, 0.95, 0.92), Color(0.5, 0.5, 0.48)],
	47: ["metal", Color(1, 1, 1), Color(0.6, 0.62, 0.66)],
	48: ["metal", Color(0.86, 0.9, 0.98), Color(0.44, 0.48, 0.6)],
	49: ["metal", Color(0.92, 0.92, 0.96), Color(0.5, 0.5, 0.58)],
	50: ["metal", Color(0.92, 0.92, 0.9), Color(0.5, 0.5, 0.48)],
	51: ["crystal", Color(0.86, 0.88, 0.92), Color(0.4, 0.42, 0.48)],
	52: ["crystal", Color(0.94, 0.94, 0.9), Color(0.46, 0.46, 0.44)],
	53: ["crystal", Color(0.8, 0.58, 1.0), Color(0.3, 0.15, 0.45)],
	54: ["gas", Color(0.5, 0.72, 1.0)],
	55: ["metal", Color(1.0, 0.9, 0.6), Color(0.62, 0.48, 0.22)],
	56: ["metal", Color(0.88, 0.96, 0.84), Color(0.42, 0.52, 0.38)],
	57: ["metal", Color(0.92, 0.93, 0.95), Color(0.44, 0.47, 0.52)],
	58: ["metal", Color(0.92, 0.9, 0.86), Color(0.48, 0.46, 0.42)],
	59: ["metal", Color(0.74, 0.96, 0.62), Color(0.3, 0.5, 0.25)],
	60: ["metal", Color(0.88, 0.72, 1.0), Color(0.42, 0.3, 0.6)],
	61: ["radio", Color(0.5, 1.0, 0.75)],
	62: ["metal", Color(0.98, 0.94, 0.75), Color(0.55, 0.5, 0.3)],
	63: ["metal", Color(1.0, 0.6, 0.58), Color(0.55, 0.2, 0.22)],
	64: ["metal", Color(0.92, 0.93, 0.95), Color(0.44, 0.47, 0.52)],
	65: ["crystal", Color(0.6, 1.0, 0.5), Color(0.2, 0.55, 0.18)],
	66: ["metal", Color(0.92, 0.92, 0.86), Color(0.46, 0.46, 0.4)],
	67: ["metal", Color(1.0, 0.92, 0.55), Color(0.58, 0.48, 0.2)],
	68: ["metal", Color(1.0, 0.7, 0.82), Color(0.58, 0.3, 0.42)],
	69: ["metal", Color(0.86, 0.95, 0.9), Color(0.4, 0.5, 0.46)],
	70: ["metal", Color(0.94, 0.94, 0.9), Color(0.48, 0.48, 0.44)],
	71: ["metal", Color(0.92, 0.93, 0.95), Color(0.44, 0.47, 0.52)],
	72: ["metal", Color(0.84, 0.86, 0.88), Color(0.4, 0.42, 0.44)],
	73: ["metal", Color(0.76, 0.8, 0.94), Color(0.32, 0.36, 0.48)],
	74: ["metal", Color(0.9, 0.9, 0.88), Color(0.42, 0.42, 0.4)],
	75: ["metal", Color(0.92, 0.93, 0.95), Color(0.44, 0.47, 0.52)],
	76: ["metal", Color(0.7, 0.78, 1.0), Color(0.28, 0.34, 0.52)],
	77: ["metal", Color(0.92, 0.93, 0.95), Color(0.44, 0.47, 0.52)],
	78: ["metal", Color(1, 1, 1), Color(0.58, 0.6, 0.64)],
	80: ["liquid", Color(1, 1, 1), Color(0.42, 0.45, 0.52)],
	81: ["metal", Color(0.82, 0.84, 0.86), Color(0.4, 0.42, 0.44)],
	82: ["metal", Color(0.7, 0.73, 0.82), Color(0.3, 0.32, 0.38)],
	83: ["rainbow", Color(1, 1, 1)],
	84: ["radio", Color(0.6, 0.8, 1.0)],
	85: ["radio", Color(0.62, 1.0, 0.6)],
	86: ["radio", Color(1.0, 0.62, 0.45)],
	87: ["radio", Color(1.0, 0.85, 0.45)],
	88: ["radio", Color(0.45, 1.0, 0.78)],
	89: ["radio", Color(0.52, 0.76, 1.0)],
	90: ["radio", Color(0.62, 1.0, 0.55)],
	91: ["radio", Color(0.74, 1.0, 0.6)],
	92: ["radio", Color(0.66, 1.0, 0.3)],
	93: ["radio", Color(0.55, 0.95, 0.62)],
	94: ["radio", Color(1.0, 0.58, 0.32)],
	95: ["radio", Color(0.5, 1.0, 0.68)],
	96: ["radio", Color(0.86, 0.6, 1.0)],
	97: ["radio", Color(0.56, 1.0, 0.6)],
	98: ["radio", Color(0.62, 1.0, 0.82)],
	99: ["radio", Color(0.56, 0.8, 1.0)],
	100: ["radio", Color(0.56, 1.0, 0.56)],
}


## The periodic-table group of element z.
static func element_group(z: int) -> String:
	if z in [3, 11, 19, 37, 55, 87]: return "alkali"
	if z in [4, 12, 20, 38, 56, 88]: return "alkaline"
	if z in [2, 10, 18, 36, 54, 86]: return "noble"
	if z in [9, 17, 35, 53, 85]: return "halogen"
	if z in [1, 6, 7, 8, 15, 16, 34]: return "nonmetal"
	if z in [5, 14, 32, 33, 51, 52]: return "metalloid"
	if z in [13, 31, 49, 50, 81, 82, 83, 84]: return "post"
	if z >= 57 and z <= 71: return "lanthanide"
	if z >= 89: return "actinide"
	return "transition"


## Element families, short enough to sit beside the rarity.
const FAMILY_SHORT := {
	"bank": "Banks", "cue": "Cue control", "combo": "Combos", "streak": "Streaks", "heat": "Heat", "pocket": "Pockets",
	"number": "Numbers", "solid": "Solids", "stripe": "Stripes", "eight": "The 8-ball", "clear": "Clearing", "gear": "Gear",
	"imbue": "Isotopes", "special": "Specials", "pause": "Pausing", "money": "Economy", "risk": "Risk", "physics": "Physics",
	"utility": "Utility",
}

## Side bet tiers: Easy, Medium, Hard. The face-down back has its own colour.
const BET_COLORS := [Color(0.45, 0.9, 0.5), Color(1.0, 0.72, 0.3), Color(1.0, 0.42, 0.4)]
const BET_BACK := Color(0.62, 0.66, 0.98)
const WHEN_SHORT := {"setup": "While aiming", "pause": "While paused", "after": "After a shot", "any": "Aim or pause"}
const PAPER := Color(0.97, 0.95, 0.9)

## Which text carries the lettering effect: "symbol" (chosen) or "name". The
## other is plain. "name" is kept for comparison in tools/tile_preview.gd.
static var effects_on := "symbol"

var kind := ""   # perk, imbue, ball, item, bet
var id := ""
var ball := 0    # imbues: which numbered ball (0 while you still choose)
var tint := Color.WHITE
var data := {}
var motif := ""


## The ball numbers a card singles out, straight from the game's rules; [] when
## it works on any ball. Used to glow those balls on the table, and (for cards
## that name numbers) to float them on the tile.
static func balls_for(k: String, i: String) -> Array:
	if k != "perk":
		return []
	match i:
		"odd": return [1, 3, 5, 7, 9, 11, 13, 15]
		"even": return [2, 4, 6, 8, 10, 12, 14]
		"prime": return Catalog.PRIMES.duplicate()
		"fibonacci": return [1, 2, 3, 5, 8, 13]
		"lowball": return [1, 2, 3]
		"highball": return [13, 14, 15]
		"eight", "darkhorse", "hushmoney", "kissblack", "steerclear", "lastcall", "trouble", "laststripe": return [8]
		"solids", "solidgold", "bedrock", "steadyrun", "solidsonly", "lastsolid": return [1, 2, 3, 4, 5, 6, 7]
		"stripes", "racing", "luckystripe", "tiger", "stripesonly", "lever": return [9, 10, 11, 12, 13, 14, 15]
	return []


## Cards whose numbers are not obvious from the name show them on the tile.
const FLOAT_NUMBERS := ["odd", "even", "prime", "fibonacci", "lowball", "highball"]


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
		"bet":
			tint = BET_BACK if i == "back" else BET_COLORS[int(Catalog.BOUNTIES[i].tier)]
		"cue":
			tint = Catalog.CUES[i].accent
			if tint.get_luminance() > 0.85:
				tint = tint.darkened(0.25)
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var recipe: String = data.get("letter", "")
	if k == "perk" and i in FLOAT_NUMBERS:
		add_child(Floaters.new(balls_for(k, i), tint))
	if k == "cue":
		add_child(CuePic.new(i))
	elif effects_on == "symbol":
		var lt := Lettering.new("    " if k == "ball" else data.sym, recipe, tint, 46, 74.0, PAPER)
		if k == "perk":
			lt.set_look(ELEMENT_LOOK.get(int(Catalog.PERKS[i].get("z", 0)), []))
		add_child(lt)
		if k == "ball":
			add_child(BallPic.new(i))   # over its effect, so backdrops (a coin, a plate) sit behind it
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
	# Top left: card kind, then rarity / timing / duration. Elements lead
	# with their atomic number, on a chip in their periodic-table group's colour.
	var kx := 9.0
	if kind == "perk":
		var z := int(Catalog.PERKS[id].get("z", 0))
		var zs := str(z)
		var zw := F_SEMI.get_string_size(zs, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var gc: Color = GROUP_COLORS[element_group(z)]
		var chip := StyleBoxFlat.new()
		chip.bg_color = gc
		chip.set_corner_radius_all(3)
		draw_style_box(chip, Rect2(6, 5, zw + 9, 15))
		_text(F_SEMI, zs, Vector2(10.5, 17), 12, gc.darkened(0.78), -1)
		kx = 6 + zw + 9 + 5
	_text(F_SEMI, _kind_name().to_upper(), Vector2(kx, 16), 11, light, -1)
	var sub := _sub()
	_text(F_REG, sub[0], Vector2(9, 29), 10, sub[1], -1)
	# Top right: motif, or for imbues the ball it goes on.
	if kind == "imbue":
		_mini_ball(Vector2(w - 20, 19), 10.0)
	elif kind == "bet":
		_chip(Vector2(w - 20, 19), 10.0)
	elif motif != "":
		IconArt.paint(self, motif, Vector2(w - 20, 20), 0.27, tint, tint.darkened(0.82), F_SEMI, 1.7)
	# Symbol and name: whichever does not carry the effect is drawn plain here.
	if effects_on == "symbol":
		_text(F_SEMI, _name(), Vector2(w * 0.5, 93), 14, light)
	else:
		_text(F_SEMI, data.sym, Vector2(w * 0.5, 74), 46, PAPER)
	# Bottom row: effect left, what it acts on right.
	draw_line(Vector2(8, 101), Vector2(w - 8, 101), Color(tint, 0.25), 1.0)
	if kind == "perk":
		# Elements: a few words on what it does, across the whole row.
		_text(F_SEMI, data.stat, Vector2(w * 0.5, 113), stat_size(data.stat, -8.0), tint)
	else:
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
		"perk": return "Element"
		"imbue": return "Isotope"
		"ball": return "Special ball"
		"item": return "Catalyst"
		"bet": return "Side bet"
		"cue": return "Starting cue"
	return ""


## The second line, top left, and its colour.
func _sub() -> Array:
	var dim := Color(tint.lerp(Color.WHITE, 0.55), 0.75)
	match kind:
		"perk":
			var r: int = Catalog.PERKS[id].r
			return [Catalog.rarity_name(r) + " · " + FAMILY_SHORT.get(Catalog.PERKS[id].fam, ""), Catalog.rarity_color(r)]
		"imbue":
			return ["Whole run", dim]
		"cue":
			var kit: String = Catalog.CUES[id].get("kit", "")
			return ["Object cue · " + Catalog.ITEMS[kit].name if kit != "" else "Plain cue", dim]
		"ball":
			return ["Joins your set", dim]
		"item":
			var it: Dictionary = Catalog.ITEMS[id]
			var when: String = WHEN_SHORT[it.when]
			return [when + " · every table", dim]
		"bet":
			if id == "back":
				return ["Face down", dim]
			return [Catalog.BET_TIERS[int(Catalog.BOUNTIES[id].tier)], tint]
	return ["", dim]


func _acts_on() -> String:
	match kind:
		"perk": return Catalog.family_name(id)
		"imbue": return "%d-ball" % ball if ball > 0 else "Any ball"
	return data.get("on", "")


func _name() -> String:
	match kind:
		"perk": return Catalog.PERKS[id].name
		"imbue": return "%s %d-ball" % [Catalog.IMBUES[id].name, ball] if ball > 0 else "%s Isotope" % Catalog.IMBUES[id].name
		"ball": return Catalog.BALL_TYPES[id].name + " ball"
		"item": return Catalog.ITEMS[id].name
		"bet": return data.get("title", id)
		"cue": return Catalog.CUES[id].name
	return id


## The imbued ball, small, ringed in the imbue colour (a question mark until
## you choose it).
func _mini_ball(c: Vector2, r: float) -> void:
	draw_arc(c, r + 2.5, 0, TAU, 28, tint, 1.6, true)
	if ball <= 0:
		draw_arc(c, r, 0, TAU, 28, Color(tint, 0.6), 1.2, true)
		_text(F_SEMI, "?", c + Vector2(0, 4), 12, tint)
		return
	var col := Catalog.ball_color(ball)
	if Catalog.is_stripe(ball):
		draw_circle(c, r, Color(0.95, 0.93, 0.88))
		draw_rect(Rect2(c + Vector2(-r + 1, -r * 0.5), Vector2(r * 2 - 2, r)), col)
	else:
		draw_circle(c, r, col)
	draw_circle(c, r * 0.55, Color(0.97, 0.95, 0.9))
	_text(F_SEMI, str(ball), c + Vector2(0, 3.5), 9, Color(0.06, 0.06, 0.08))


## A betting chip, for side bets.
func _chip(c: Vector2, r: float) -> void:
	draw_circle(c, r, tint, true, -1.0, true)
	for i in 6:
		var a := TAU * i / 6.0
		draw_line(c + Vector2.from_angle(a) * (r - 3.5), c + Vector2.from_angle(a) * r, Color(1, 1, 1, 0.85), 2.0, true)
	draw_circle(c, r * 0.55, tint.darkened(0.25), true, -1.0, true)
	draw_arc(c, r * 0.55, 0, TAU, 20, Color(1, 1, 1, 0.6), 1.0, true)


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
	var look := []   # Elements: [kind, light, dark] (see TileArt.ELEMENT_LOOK)
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
		if has_method("_p_" + recipe):
			add_child(TileArt.Motes.new(self, "_p_" + recipe))
		elif not look.is_empty() and look[0] == "radio":
			add_child(TileArt.Motes.new(self, "_p_radio"))

	## Effects that move or reshape their letters: a glow drawn round the
	## letters in place would not line up with them.
	const MOVES_GLYPHS := ["merge", "spring", "odd", "steer", "missing", "chips", "dice", "slots", "power", "hazard", "breakup", "tall"]

	## Colours the letters like the element itself: its own gradient where the
	## effect had a plain one, or the effect's pattern in the element's colours.
	func set_look(l: Array) -> void:
		look = l
		if l.is_empty() or recipe == "ingot":
			return
		var light: Color = l[1]
		var dark: Color = l[2] if l.size() > 2 else light.darkened(0.45)
		var own := fill
		var mode := -1 if own.is_empty() else int(own[0])
		if mode < 0 or mode == 0 or mode == 1:
			match String(l[0]):
				"gas": fill = [0, light.lerp(Color.WHITE, 0.72), light]
				"radio": fill = [0, light.lerp(Color.WHITE, 0.55), light.lerp(Color.WHITE, 0.1)]
				"crystal": fill = [13, light, Color(1, 1, 1, 0.96), light, 0.0, 0.42]
				"powder": fill = [5, light, light, light, 2.0 * u, 0.28]
				"rainbow": fill = [16, Color.WHITE]
				_: fill = [19, light, dark]
		elif mode == 4:
			fill = own.duplicate()   # a stripe-ball band: the element's metal, the card's coloured band
			fill[1] = light
			fill[3] = light
		elif mode in [2, 3, 6, 10, 11, 15]:
			fill = own.duplicate()
			fill[1] = light
			fill[2] = dark
		elif mode in [5, 9, 12, 13]:
			fill = own.duplicate()
			fill[1] = light
			if mode == 9:
				fill[2] = light
				fill[3] = light
		else:
			return   # flame, strata, gold leaf, rainbow, starfield, chrome: the effect's own look stays
		material = _fill_material()

	## Elements that glow: a soft halo in the element's colour behind the letters.
	func _halo() -> void:
		if look.is_empty() or not (look[0] in ["gas", "radio"]) or recipe in MOVES_GLYPHS:
			return
		var g: Color = look[1]
		_edge(Color(g, 0.09), 13 * u)
		_edge(Color(g, 0.16), 8 * u)
		_edge(Color(g, 0.3), 4 * u)

	## Liquid elements: a drop gathering under the last letter.
	func _drop_below() -> void:
		if look.is_empty() or look[0] != "liquid":
			return
		var c := Vector2(x1 - 7 * u, baseline + 4.5 * u)
		var col: Color = look[1].lerp(look[2], 0.35)
		var pts := PackedVector2Array()
		for i in 21:
			var a := TAU * i / 20.0
			var r := 2.6 * u * (1.0 - 0.75 * maxf(0.0, -sin(a)) ** 3)
			pts.append(c + Vector2(cos(a) * r, sin(a) * r * 1.25 - (2.4 * u if sin(a) < 0 else 0.0) * absf(sin(a))))
		draw_line(Vector2(c.x, baseline - 0.5 * u), c - Vector2(0, 2 * u), col, 1.6 * u, true)
		draw_colored_polygon(pts, col)
		draw_circle(c + Vector2(-0.9, -0.4) * u, 0.8 * u, Color(1, 1, 1, 0.85), true, -1.0, true)

	## Radioactive elements: specks flying off the letters, fading as they go.
	func _p_radio(ci: CanvasItem, t: float) -> void:
		var g: Color = look[1]
		for i in 7:
			var life := fposmod(t * 0.42 + i / 7.0, 1.0)
			var start := Vector2(lerpf(x0 + 2 * u, x1 - 2 * u, _h(i, 31)), lerpf(top + 3 * u, baseline - 3 * u, _h(i, 32)))
			var p := start + Vector2.from_angle(TAU * _h(i, 33)) * (4 * u + life * 15 * u)
			ci.draw_circle(p, (1.5 - life) * u, Color(g, 0.95 * (1.0 - life)), true, -1.0, true)

	func _col() -> Color:
		return colour

	## The colour for the main letters: INK when a fill paints them.
	func _ink() -> Color:
		return INK if not fill.is_empty() else colour

	func _width(t: String) -> float:
		return font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x

	## Sets the text's box (x0, x1, top, cx, cy) for drawing.
	func _box() -> void:
		x0 = size.x * 0.5 - _width(text) * 0.5
		x1 = x0 + _width(text)
		top = baseline - cap
		cx = size.x * 0.5
		cy = baseline - cap * 0.5

	func _draw() -> void:
		var pos := Vector2(size.x * 0.5 - _width(text) * 0.5, baseline)
		_box()
		_halo()
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
		_drop_below()

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
			"stub": return [9, colour, colour, colour, 1.0, 0.2]
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
			# Imbues
			"spark": return [0, colour, Color(0.6, 1.0, 0.95)]
			"gilt": return [14, colour, Color(1, 0.82, 0.35), colour, 0.0, 0.62]
			"weights": return [0, colour, tint.lerp(colour, 0.4)]
			"hairline": return [13, colour, Color(1, 1, 1), colour, 0.0, 0.3]
			"kindle": return [0, colour, Color(1, 0.6, 0.25)]
			"veins": return [0, colour, tint.lerp(colour, 0.35)]
			"volatile": return [0, Color(1, 0.95, 0.7), Color(1, 0.55, 0.15)]
			"jinx": return [0, colour, Color(0.72, 0.55, 1.0)]
			"pawn": return [0, colour, Color(1, 0.85, 0.5)]
			"frosted": return [0, Color(0.82, 0.93, 1.0), Color(0.55, 0.75, 1.0)]
			"poles": return [15, Color(1, 0.45, 0.45), Color(0.5, 0.65, 1.0)]
			"battery": return [0, Color(1, 1, 0.78), Color(1, 0.85, 0.3)]
			"resonance": return [1, Color(1, 0.62, 0.95), Color(0.55, 0.9, 1.0)]
			"lead": return [0, Color(0.82, 0.84, 0.88), Color(0.5, 0.53, 0.6)]
			"starry": return [17, Color(0.16, 0.18, 0.42), Color(1, 0.95, 0.78)]
			"twin": return [15, colour, tint.lerp(colour, 0.2)]
			# Special balls
			"glass": return [13, Color(0.6, 0.82, 0.95, 0.45), Color(1, 1, 1, 0.95), colour, 0.0, 0.42]
			"iron": return [2, Color(0.88, 0.9, 0.93), Color(0.68, 0.7, 0.75), colour, 2.0 * u, 0.5]
			"coal": return [0, Color(0.42, 0.24, 0.16), Color(0.95, 0.38, 0.1)]
			"iceblock": return [0, Color(0.95, 0.99, 1), Color(0.6, 0.85, 1)]
			"prism": return [16, colour]
			"wild": return [3, Color(0.8, 0.52, 1.0), Color(1, 0.86, 0.32), colour, 7.0 * u, 0.5]
			"sprout": return [0, colour, Color(0.62, 0.95, 0.5)]
			"bigclover": return [0, colour, Color(0.68, 1.0, 0.68)]
			"star": return [0, Color(1, 1, 0.86), Color(1, 0.82, 0.3)]
			"heart": return [0, colour, Color(1, 0.62, 0.76)]
			"moon": return [0, Color(0.93, 0.94, 1.0), Color(0.66, 0.68, 0.8)]
			"sun": return [0, Color(1, 0.96, 0.62), Color(1, 0.6, 0.15)]
			"erase": return [9, colour, colour, colour, 2.0, 0.1]
			"comet": return [0, Color(1, 1, 1), Color(0.6, 0.8, 1.0)]
			# Items
			"ghost": return [9, Color(colour, 0.9), colour, colour, -1.0, 0.1]
			"chrome": return [18, colour]
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
		else if (mode == 9) {                                                     // worn away (p1 > 1.5: right, > 0: top, < 0: bottom)
			float t = p1 > 1.5 ? 1.0 - tx : (p1 > 0.0 ? ty : 1.0 - ty);
			col.a *= smoothstep(p2 - 0.2, p2 + 0.25, t);
		}
		else if (mode == 10) { col = mod(lp.y, p1) < p1 * p2 ? a : b; }           // screen lines
		else if (mode == 11) { col = (abs(tx - 0.4) < 0.055 || abs(tx - 0.6) < 0.055) ? b : a; } // racing stripes
		else if (mode == 12) { if (mod(lp.x + lp.y * 0.6, p1) < p1 * p2) { col.a = 0.0; } }      // dashes
		else if (mode == 13) {                                                    // a sheen across
			float d = tx - (1.0 - ty) * 0.35 - p2;
			col = mix(a, b, smoothstep(0.12, 0.0, abs(d)));
		}
		else if (mode == 14) {                                                    // gold leaf over part
			float e = tx * 0.75 + (1.0 - ty) * 0.45 + (hash(floor(lp / 2.5)) - 0.5) * 0.14;
			col = e > p2 ? b : a;
		}
		else if (mode == 15) { col = tx < 0.5 ? a : b; }                          // two halves
		else if (mode == 16) {                                                    // rainbow
			vec3 h = clamp(abs(mod(tx * 5.1 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
			col = vec4(mix(vec3(1.0), h, 0.55), a.a);
		}
		else if (mode == 17) {                                                    // starfield
			col = vec4(mix(a.rgb, a.rgb * 1.7, ty), a.a);
			if (hash(floor(lp / 2.0)) > 0.93) { col = b; }
		}
		else if (mode == 18) {                                                    // chrome
			col = ty < 0.48 ? mix(vec4(1.0), vec4(0.72, 0.75, 0.8, 1.0), ty / 0.48) : mix(vec4(0.3, 0.32, 0.38, 1.0), vec4(0.86, 0.88, 0.92, 1.0), (ty - 0.48) / 0.52);
		}
		else if (mode == 19) {                                                    // tinted metal: bright top, dark horizon
			col = ty < 0.46 ? mix(mix(a, vec4(1.0), 0.5), a, ty / 0.46) : mix(b, mix(a, b, 0.3), (ty - 0.46) / 0.54);
			col.a = a.a;
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
		# A length of velvet draped behind the letters: it hangs in soft folds
		# (lit ridges, deep shadowed valleys, a wavy lower edge) from a stitched
		# hem, with a paler swipe where the pile has been brushed the other way.
		var l := x0 - 22 * u
		var r := x1 + 22 * u
		var t := top - 6 * u
		var b := baseline + 2 * u
		var folds := 4.0
		var n := 64
		var deep := tint.darkened(0.72)
		var lit := tint.darkened(0.38)
		for i in n:
			var k0 := i / float(n)
			var k1 := (i + 1) / float(n)
			var s0 := 0.5 + 0.5 * cos(k0 * folds * TAU)
			var s1 := 0.5 + 0.5 * cos(k1 * folds * TAU)
			var xa := lerpf(l, r, k0)
			var xb := lerpf(l, r, k1) + 0.5
			var col := deep.lerp(lit, pow((s0 + s1) * 0.5, 1.6))
			draw_colored_polygon(PackedVector2Array([Vector2(xa, t), Vector2(xb, t), Vector2(xb, b + s1 * 5 * u), Vector2(xa, b + s0 * 5 * u)]), col)
		# The brushed swipe, and a sheen along each ridge.
		_poly(PackedVector2Array([Vector2(cx + 2 * u, t), Vector2(cx + 20 * u, t), Vector2(cx - 6 * u, b + 2 * u), Vector2(cx - 24 * u, b + 2 * u)]), Color(1, 1, 1, 0.09))
		for f in int(folds) + 1:
			var x := lerpf(l, r, f / folds)
			draw_line(Vector2(x, t + 5 * u), Vector2(x, b + 3 * u), Color(tint.lightened(0.4), 0.22), 1.0 * u, true)
		# The hem: a darker band with a row of stitches.
		draw_rect(Rect2(l, t, r - l, 4.5 * u), Color(0, 0, 0, 0.28))
		_dashes(PackedVector2Array([Vector2(l + 2 * u, t + 2.3 * u), Vector2(r - 2 * u, t + 2.3 * u)]), Color(colour, 0.75), 1.1 * u, 3 * u, 2.2 * u)
		_text_at(Color(0, 0, 0, 0.45), Vector2(1.5, 2.2) * u)
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

	## Slow Cloth: a deep, shaggy pile under tightly braked letters, and a ball
	## that has rolled a short way into it and stopped dead.
	func _r_brake() -> void:
		var l := x0 - 30 * u
		var r := x1 + 8 * u
		var y := baseline + 6 * u
		var x := l
		var i := 0
		while x < r:
			var hgt := (4.0 + 3.5 * _h(i, 3)) * u
			draw_line(Vector2(x, y), Vector2(x + (_h(i, 5) - 0.5) * 2 * u, y - hgt), Color(tint, 0.45 + 0.4 * _h(i, 7)), 1.3 * u, true)
			x += 2.1 * u
			i += 1
		var ball := Vector2(x0 - 9 * u, y - 7.5 * u)
		draw_polyline_colors(PackedVector2Array([ball - Vector2(19 * u, 0), ball - Vector2(5 * u, 0)]), PackedColorArray([Color(colour, 0), Color(colour, 0.7)]), 1.6 * u, true)
		draw_circle(ball, 4.6 * u, Color(0.96, 0.95, 0.9), true, -1.0, true)
		draw_line(ball + Vector2(7 * u, -5 * u), ball + Vector2(7 * u, 5 * u), Color(1, 0.45, 0.4, 0.95), 1.8 * u, true)
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

	## A power gauge under the letters: the stretch from `from` to `to` (0-1 of
	## full power) is lit, the rest is an empty track, with a tick at each end of it.
	func _gauge(from: float, to: float, col: Color) -> void:
		var l := x0 - 8 * u
		var w := x1 - x0 + 16 * u
		var y := baseline + 1.6 * u
		var h := 3.0 * u
		_rr(Rect2(l, y, w, h), h * 0.5, Color(colour, 0.2))
		_rr(Rect2(l + w * from, y, w * (to - from), h), h * 0.5, col)
		for f: float in [from, to]:
			if f > 0.02 and f < 0.98:
				draw_line(Vector2(l + w * f, y - 1.2 * u), Vector2(l + w * f, y + h + 1.2 * u), Color(colour, 0.95), 1.3 * u, true)

	## Power Stroke: bold, leaning hard into the shot, speed lines behind, and
	## the top 15% of the power gauge lit (85% power and up).
	func _r_power() -> void:
		_gauge(0.85, 1.0, Color(1.0, 0.42, 0.28))
		for k in 3:
			var y := top + (7 + 9 * k) * u
			var l := (16 + 8 * (1 - absi(k - 1))) * u
			draw_line(Vector2(x0 - 6 * u - l, y), Vector2(x0 - 6 * u, y), Color(tint, 0.7), 2 * u, true)
		for g: Dictionary in _layout():
			_put(g, _ink(), Vector2.ZERO, 0.0, Vector2.ONE, -0.24, 1.6 * u)

	## Soft Touch: hollow letters in a soft glow, the lightest touch.
	func _r_soft() -> void:
		_gauge(0.0, 0.35, Color(0.55, 0.82, 1.0))   # 35% power or less
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
		# A draw shot: the cue ball comes back the way it came.
		var y := baseline + 3.6 * u
		draw_circle(Vector2(x1 + 5 * u, y), 3.2 * u, Color(0.96, 0.95, 0.9), true, -1.0, true)
		_dashes(PackedVector2Array([Vector2(x1 - 1 * u, y), Vector2(x0 - 4 * u, y)]), Color(tint, 0.85), 1.6 * u, 2.5 * u, 2.5 * u)
		_head(Vector2(x0 - 8 * u, y), Vector2.LEFT, 6 * u, Color(tint, 0.95))

	# --- Perks: Combos & clusters ---------------------------------------------------

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
		for i in gl.size():
			_put(gl[i], _ink(), Vector2(1 * u, 0) if i % 2 == 0 else Vector2(-1 * u, -2 * u), deg_to_rad(-6 if i % 2 == 0 else 8))

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
		var last := gl.size() - 1
		for i in gl.size():
			if i < last:
				_put(gl[i], _ink(), Vector2.ZERO, deg_to_rad(-3), Vector2.ONE, 0.0, 0.0, 0.0)
			else:
				_put(gl[i], _ink(), Vector2(-3 * u if last > 0 else 0.0, 0), deg_to_rad(16), Vector2.ONE, 0.0, 0.0, 0.0)
		var foot := Vector2(gl[last].x + gl[last].w * 0.5, baseline)
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
	## Hooke's Law: a coiled spring beside the letters.
	func _r_coil() -> void:
		_text_at(_ink())
		var x := x1 + 6 * u
		var pts := PackedVector2Array()
		for i in 13:
			pts.append(Vector2(x + (i % 2) * 5 * u, baseline - i * 1.6 * u))
		draw_polyline(pts, Color(tint, 0.9), 1.2 * u, true)

	## Golden Ratio: a golden spiral beside the letters.
	func _r_phi() -> void:
		_text_at(_ink())
		var c := Vector2(x1 + 10 * u, baseline - 7 * u)
		var pts := PackedVector2Array()
		for i in 48:
			var t := i / 47.0 * 4.0 * PI
			pts.append(c + Vector2(cos(t), sin(t)) * 0.55 * u * exp(0.3 * t))
		draw_polyline(pts, Color(1.0, 0.8, 0.3, 0.95), 1.1 * u, true)

	func _r_simmer() -> void:
		_text_at(_ink())
		for b in [[0.12, 3, 2.2], [0.32, 8, 1.4], [0.58, 4, 2.8], [0.8, 9, 1.6], [0.95, 3, 1.2]]:
			var x := lerpf(x0, x1, b[0])
			draw_arc(Vector2(x, _top_at(x) - b[1] * u), b[2] * u, 0, TAU, 16, Color(tint, 0.8), 1.1 * u, true)

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

	# --- Perks: Ball numbers -----------------------------------------------------------

	## Odd Balls: one letter out of step with the other.
	func _r_odd() -> void:
		var gl := _layout(2 * u)
		if gl.size() == 1:
			# One letter: the odd one out, tipped over and shoved off its line.
			_put(gl[0], Color(tint, 0.25), Vector2(-3 * u, 2 * u))
			_put(gl[0], _ink(), Vector2(3 * u, -4 * u), deg_to_rad(13), Vector2(1.04, 1.04))
			return
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
		for i in gl.size():
			_put(gl[i], _ink(), Vector2.ZERO, deg_to_rad(-8 if i % 2 == 0 else 8))

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
		var rise := 5 * u
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
		for k in 3:
			var y := top + (6 + 9 * k) * u
			draw_line(Vector2(x0 - (10 + 6 * (1 - absi(k - 1))) * u - 12 * u, y), Vector2(x0 - 5 * u, y), Color(tint, 0.6), 1.6 * u, true)
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

	## Side Hustle: a side bet card on one side, its winnings doubled on the other.
	func _r_hustle() -> void:
		for g: Dictionary in _layout(2 * u):
			_put(g, _ink(), Vector2.ZERO, 0.0, Vector2.ONE, 0.2)
		var card := Rect2(x0 - 21 * u, cy - 10 * u, 13 * u, 19 * u)
		_rr(card, 2 * u, Color(0.97, 0.95, 0.9))
		_rr(Rect2(card.position + Vector2(2, 3) * u, Vector2(9, 7) * u), 1 * u, tint.darkened(0.6))
		for k in 2:
			draw_line(card.position + Vector2(2.5 * u, (13 + 2.6 * k) * u), card.position + Vector2(10.5 * u, (13 + 2.6 * k) * u), Color(0.2, 0.18, 0.15, 0.8), 1.0 * u, true)
		for k in 2:
			var c := Vector2(x1 + 12 * u, cy + (5 - 9 * k) * u)
			draw_circle(c + Vector2(0, 1.2 * u), 6 * u, Color(0, 0, 0, 0.35), true, -1.0, true)
			draw_circle(c, 6 * u, tint, true, -1.0, true)
			draw_arc(c, 3.6 * u, 0, TAU, 20, Color(1, 1, 1, 0.8), 1.0 * u, true)
			for q in 6:
				draw_line(c + Vector2.from_angle(TAU * q / 6.0) * 4.4 * u, c + Vector2.from_angle(TAU * q / 6.0) * 6 * u, Color(1, 1, 1, 0.9), 1.3 * u, true)

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

	# --- Shared pieces for imbues, balls, items and bets -----------------------------

	## A repeatable 0..1 noise for particle i, channel k.
	func _h(i: int, k := 0) -> float:
		return fposmod(sin(i * 12.9898 + k * 78.233) * 43758.5453, 1.0)

	## A jagged lightning bolt from a to b.
	func _bolt(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w: float, seed: int, n := 6) -> void:
		var pts := PackedVector2Array([a])
		var d := b - a
		var nrm := d.orthogonal().normalized()
		for i in range(1, n):
			pts.append(a + d * (float(i) / n) + nrm * (_h(seed, i) - 0.5) * d.length() * 0.35)
		pts.append(b)
		ci.draw_polyline(pts, col, w, true)

	## A pool ball: n's colour, solid or striped, with its number.
	func _ballpic(c: Vector2, r: float, n: int) -> void:
		var col: Color = Catalog.BALL_COLORS.get(n, Color(0.96, 0.95, 0.9))
		if n >= 9 and n <= 15:
			draw_circle(c, r, Color(0.96, 0.95, 0.9), true, -1.0, true)
			var band := PackedVector2Array()
			for i in 13:
				var a := lerpf(-0.75, 0.75, i / 12.0)
				band.append(c + Vector2(cos(PI + a), sin(PI + a) * 0.62) * r)
			for i in 13:
				var a := lerpf(-0.75, 0.75, i / 12.0)
				band.append(c + Vector2(cos(a), sin(a) * 0.62) * r)
			draw_colored_polygon(band, col)
		else:
			draw_circle(c, r, col, true, -1.0, true)
		if n > 0:
			draw_circle(c, r * 0.5, Color(0.97, 0.95, 0.9), true, -1.0, true)
			var f := maxi(6, roundi(r * 0.75))
			var tw := font.get_string_size(str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, f).x
			draw_string(font, c + Vector2(-tw * 0.5, f * 0.36), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, f, Color(0.06, 0.06, 0.08))
		draw_circle(c + Vector2(-0.35, -0.4) * r, r * 0.22, Color(1, 1, 1, 0.45), true, -1.0, true)

	## A pocket: a dark hole with a coloured lip.
	func _pocket(c: Vector2, r: float, lip := Color.TRANSPARENT) -> void:
		draw_circle(c, r, Color(0.02, 0.02, 0.03, 0.92), true, -1.0, true)
		draw_arc(c, r, 0, TAU, 24, lip if lip.a > 0 else Color(tint, 0.85), maxf(1.0, 1.4 * u), true)

	## A number in the symbol font, centred on c.
	func _num(txt: String, c: Vector2, size_px: float, col: Color) -> void:
		var f := roundi(size_px)
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, f).x
		draw_string(font, c + Vector2(-tw * 0.5, f * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, f, col)

	## A heart shape, w across, centred on c.
	func _heart_pts(c: Vector2, w: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 36:
			var t := TAU * i / 36.0
			pts.append(c + Vector2(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))) * w / 34.0)
		return pts

	## A five-pointed star.
	func _star5(c: Vector2, ro: float, ri: float, rot := 0.0) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 10:
			pts.append(c + Vector2.from_angle(-PI * 0.5 + rot + PI * i / 5.0) * (ro if i % 2 == 0 else ri))
		return pts

	# --- Imbues -----------------------------------------------------------------------

	## Spark: crackling with arcs of electricity.
	func _r_spark() -> void:
		var zap := Color(0.55, 1.0, 0.95)
		_edge(Color(zap, 0.16), 8 * u)
		_text_at(_ink())
		var gl := _layout()
		_bolt(self, Vector2(x0 - 14 * u, cy - 8 * u), Vector2(x0 + 1 * u, top + 9 * u), Color(zap, 0.9), 1.6 * u, 3)
		_bolt(self, Vector2(x1 - 1 * u, baseline - 7 * u), Vector2(x1 + 15 * u, cy + 1 * u), Color(zap, 0.9), 1.6 * u, 7)
		var a := Vector2(gl[0].x + gl[0].w * 0.5, top - 1 * u)
		var b := Vector2(gl[-1].x + gl[-1].w * 0.5, baseline - _gh(gl[-1].ch) - 1 * u)
		_bolt(self, a, b, Color(zap, 0.7), 1.2 * u, 11, 5)

	func _p_spark(ci: CanvasItem, t: float) -> void:
		for i in 5:
			var life := fposmod(t * 1.7 + _h(i), 1.0)
			if life > 0.35:
				continue
			var k := floori(t * 1.7 + _h(i)) * 7 + i
			var p := Vector2(lerpf(x0 - 8 * u, x1 + 8 * u, _h(k, 1)), lerpf(top - 2 * u, baseline + 2 * u, _h(k, 2)))
			var d := Vector2.from_angle(_h(k, 3) * TAU) * 5 * u
			_bolt(ci, p - d, p + d, Color(0.7, 1.0, 1.0, 1.0 - life / 0.35), 1.1 * u, k, 3)

	## Gilded: gold leaf laid over half the letters, flakes coming loose.
	func _r_gilt() -> void:
		_text_at(_ink())
		for f in [[0.82, -0.25, 0.4], [1.12, 0.15, -0.3], [1.0, 0.7, 0.9], [-0.1, 0.9, 0.2]]:
			var c := Vector2(lerpf(x0, x1, f[0]), lerpf(top, baseline, f[1]))
			draw_set_transform(c, f[2])
			_rr(Rect2(-2 * u, -1.5 * u, 4 * u, 3 * u), 0.5 * u, Color(1, 0.84, 0.38))
			draw_set_transform(Vector2.ZERO)

	func _p_gilt(ci: CanvasItem, t: float) -> void:
		for i in 4:
			var life := fposmod(t * 0.28 + i * 0.25, 1.0)
			var x := lerpf(x0, x1 + 6 * u, _h(i, 1)) + sin(life * TAU * 1.5 + i) * 4 * u
			var y := lerpf(top - 6 * u, baseline + 6 * u, life)
			ci.draw_set_transform(Vector2(x, y), life * TAU * 2.0 + i, Vector2(1.0, absf(cos(life * TAU * 2.0)) + 0.2))
			ci.draw_rect(Rect2(-1.6 * u, -1.2 * u, 3.2 * u, 2.4 * u), Color(1, 0.86, 0.4, sin(life * PI)))
		ci.draw_set_transform(Vector2.ZERO)

	## Weighted: pressed down by a weight that reads ×3, and climbing.
	func _r_weights() -> void:
		var gl := _layout()
		for g: Dictionary in gl:
			_put(g, _ink(), Vector2.ZERO, 0.0, Vector2(1.08, 0.86), 0.0, 0.0, 0.0)
		var y := baseline - cap * 0.86 - 1 * u
		var bw := 26 * u
		var bh := 10 * u
		var pts := PackedVector2Array([Vector2(cx - bw * 0.36, y - bh), Vector2(cx + bw * 0.36, y - bh), Vector2(cx + bw * 0.5, y), Vector2(cx - bw * 0.5, y)])
		_poly(pts, tint.darkened(0.35))
		draw_arc(Vector2(cx, y - bh), 4 * u, PI, TAU, 12, tint.darkened(0.35), 2 * u, true)
		_num("×3", Vector2(cx, y - bh * 0.5), 9 * u, Color(0.96, 0.95, 0.9))
		for k in 2:
			_num("×%d" % (4 + k), Vector2(x1 + (8 + 9 * k) * u, baseline - (6 + 7 * k) * u), (8 - k) * u, Color(tint, 0.55 - 0.2 * k))

	## Hairline: a glossy coat with a fine crack running through it.
	func _r_hairline() -> void:
		_text_at(_ink())
		var w := x1 - x0
		var crack := PackedVector2Array([Vector2(x0 + w * 0.05, top + cap * 0.18), Vector2(x0 + w * 0.3, top + cap * 0.36), Vector2(x0 + w * 0.42, top + cap * 0.3), Vector2(x0 + w * 0.62, top + cap * 0.58), Vector2(x0 + w * 0.95, top + cap * 0.66)])
		draw_polyline(crack, Color(bg, 0.9), 1.4 * u, true)
		draw_polyline(crack, Color(1, 1, 1, 0.95), 0.7 * u, true)
		draw_line(crack[3], crack[3] + Vector2(-3, 7) * u, Color(1, 1, 1, 0.8), 0.6 * u, true)
		draw_line(crack[1], crack[1] + Vector2(1, -6) * u, Color(1, 1, 1, 0.8), 0.6 * u, true)

	## Kindled: kindling crossed under the letter, catching light.
	func _r_kindle() -> void:
		var wood := Color(0.55, 0.32, 0.16)
		var b := baseline + 3 * u
		draw_line(Vector2(cx - 15 * u, b + 3 * u), Vector2(cx + 13 * u, b - 3 * u), wood, 3 * u, true)
		draw_line(Vector2(cx - 13 * u, b - 3 * u), Vector2(cx + 15 * u, b + 3 * u), wood.darkened(0.2), 3 * u, true)
		_flame(Vector2(cx, baseline + 1 * u), 6 * u, 14 * u, Color(1, 0.5, 0.12, 0.85))
		_flame(Vector2(cx + 1 * u, baseline + 1 * u), 3 * u, 8 * u, Color(1, 0.86, 0.4, 0.95))
		_text_at(_ink())

	func _p_kindle(ci: CanvasItem, t: float) -> void:
		for i in 6:
			var life := fposmod(t * 0.7 + i / 6.0, 1.0)
			var p := Vector2(cx + (_h(i) - 0.5) * 18 * u + sin(life * 9.0 + i) * 2 * u, baseline - life * (cap + 8 * u))
			ci.draw_circle(p, (1.4 - life) * u, Color(1, 0.6 + 0.3 * _h(i, 2), 0.2, 1.0 - life), true, -1.0, true)

	## Vein: veins branching out of the letter, spreading.
	func _vein_paths() -> Array:
		var out := []
		for start in [[0.3, 0.62, 0.25], [0.12, 0.2, -0.3]]:
			for side in [-1.0, 1.0]:
				var p := Vector2(cx + side * (x1 - x0) * start[0], lerpf(top, baseline, start[1]))
				var pts := PackedVector2Array([p])
				var ang: float = (0.0 if side > 0 else PI) + side * start[2]
				for k in 6:
					ang += side * (0.22 + _h(k + int(side * 3) + int(start[1] * 10), 2) * 0.25) * (1.0 if k % 2 else -1.0)
					p += Vector2.from_angle(ang) * 5.5 * u
					p.y = clampf(p.y, top - 4 * u, baseline + 4 * u)
					pts.append(p)
				out.append(pts)
		return out

	func _r_veins() -> void:
		var vein := tint.lerp(Color(1, 0.3, 0.6), 0.3)
		for path: PackedVector2Array in _vein_paths():
			for i in path.size() - 1:
				var wv := lerpf(2.4, 0.8, float(i) / path.size()) * u
				draw_line(path[i], path[i + 1], Color(vein, 0.8), wv, true)
				if i % 2 == 1:
					var d := (path[i + 1] - path[i]).rotated(0.9 if i % 4 == 1 else -0.9) * 0.6
					draw_line(path[i], path[i] + d, Color(vein, 0.55), wv * 0.6, true)
		_text_at(_ink())

	func _p_veins(ci: CanvasItem, t: float) -> void:
		var paths := _vein_paths()
		for j in paths.size():
			var path: PackedVector2Array = paths[j]
			var f := fposmod(t * 0.6 + j * 0.27, 1.0) * (path.size() - 1)
			var i := mini(floori(f), path.size() - 2)
			var p := path[i].lerp(path[i + 1], f - i)
			ci.draw_circle(p, 2.2 * u, Color(1, 0.75, 0.95, 0.85), true, -1.0, true)

	## Lucky: hung inside a horseshoe, ends up so the luck stays in.
	func _r_horseshoe() -> void:
		var c := Vector2(cx, cy - 1 * u)
		var r := cap * 0.5 + 4 * u
		var steel := Color(0.8, 0.83, 0.9)
		draw_arc(c, r, -0.1 * PI, 1.1 * PI, 32, Color(steel, 0.85), 6 * u, true)
		draw_arc(c, r, -0.1 * PI, 1.1 * PI, 32, Color(bg, 0.6), 1 * u, true)
		for k in 6:
			var a := lerpf(0.0, PI, (k + 0.5) / 6.0)
			draw_circle(c + Vector2.from_angle(a) * r, 0.9 * u, Color(0.1, 0.1, 0.12), true, -1.0, true)
		_text_at(_ink())

	func _p_horseshoe(ci: CanvasItem, t: float) -> void:
		var c := Vector2(cx, cy - 1 * u)
		var r := cap * 0.5 + 4 * u
		for k in 2:
			var a := -0.1 * PI if k == 0 else 1.1 * PI
			var s := pow(maxf(0.0, sin(t * 2.2 + k * 2.4)), 6.0)
			_twinkle(ci, c + Vector2.from_angle(a) * r, 5 * u * s, Color(1, 1, 0.9, s))

	## A thin four-pointed twinkle for particles.
	func _twinkle(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
		if r < 0.3:
			return
		ci.draw_line(c - Vector2(r, 0), c + Vector2(r, 0), col, 1.0, true)
		ci.draw_line(c - Vector2(0, r), c + Vector2(0, r), col, 1.0, true)
		ci.draw_circle(c, r * 0.25, col, true, -1.0, true)

	## Volatile: shaking in front of a blast about to happen.
	func _r_volatile() -> void:
		var c := Vector2(cx, cy)
		var pts := PackedVector2Array()
		for i in 24:
			pts.append(c + Vector2.from_angle(TAU * i / 24.0) * (cap * 0.5 + (11 if i % 2 == 0 else 3) * u + _h(i) * 4 * u))
		_poly(pts, Color(1, 0.55, 0.1, 0.3))
		var inner := PackedVector2Array()
		for i in 24:
			inner.append(c + (pts[i] - c) * 0.72)
		_poly(inner, Color(1, 0.8, 0.25, 0.28))
		_text_at(Color(1, 0.3, 0.2, 0.7), Vector2(-1.5, 1) * u)
		_text_at(Color(1, 0.9, 0.3, 0.7), Vector2(1.5, -1) * u)
		_text_at(_ink())

	func _p_volatile(ci: CanvasItem, t: float) -> void:
		for i in 7:
			var life := fposmod(t * 2.3 + _h(i), 1.0)
			var a := _h(floori(t * 2.3 + _h(i)) * 11 + i) * TAU
			var p := Vector2(cx, cy) + Vector2.from_angle(a) * (cap * 0.5 + (6 + life * 10) * u)
			ci.draw_circle(p, (1.3 - life) * u, Color(1, 0.75, 0.25, 1.0 - life), true, -1.0, true)

	## Jinxed: under its own little rain cloud.
	func _r_jinx() -> void:
		var gl := _layout()
		for g: Dictionary in gl:
			_put(g, _ink(), Vector2(-3 * u, 1 * u), deg_to_rad(9))
		var c := Vector2(x1 + 5 * u, top + 1 * u)
		var cloud := Color(0.42, 0.36, 0.55)
		for b in [[-6, 1, 4.5], [0, -2, 5.5], [6, 0, 4.5], [1, 2.5, 4.5]]:
			draw_circle(c + Vector2(b[0], b[1]) * u, b[2] * u, cloud, true, -1.0, true)
		for k in 4:
			var x := c.x + (-6 + 4 * k) * u
			draw_line(Vector2(x, c.y + 7 * u), Vector2(x - 2.5 * u, c.y + 13 * u), Color(0.6, 0.55, 0.95, 0.7), 1.2 * u, true)

	func _p_jinx(ci: CanvasItem, t: float) -> void:
		var c := Vector2(x1 + 5 * u, top + 1 * u)
		for i in 5:
			var life := fposmod(t * 1.6 + i * 0.2, 1.0)
			var x := c.x + (-7 + 3.5 * i) * u - life * 5 * u
			var y := c.y + 7 * u + life * 24 * u
			ci.draw_line(Vector2(x, y), Vector2(x - 1.2 * u, y + 3.5 * u), Color(0.7, 0.65, 1.0, 0.8 * (1.0 - life)), 1.1 * u, true)

	## Pawned: hanging under the pawnbroker's three gold balls.
	func _r_pawn() -> void:
		_text_at(_ink())
		var gold := Color(1, 0.8, 0.3)
		var bar := Vector2(x1 + 3 * u, top + 2 * u)
		draw_line(bar, bar + Vector2(18 * u, 0), Color(colour, 0.7), 1.6 * u, true)
		for p: Vector2 in [Vector2(5, 7), Vector2(15, 7), Vector2(10, 15)]:
			var c := bar + p * u
			draw_line(Vector2(c.x, bar.y), c, Color(colour, 0.5), 0.8 * u, true)
			draw_circle(c, 3.6 * u, gold, true, -1.0, true)
			draw_circle(c + Vector2(-1.1, -1.1) * u, 1.1 * u, Color(1, 0.96, 0.75), true, -1.0, true)

	## Frosted: iced like a cake, with snow along the tops.
	func _r_frosted() -> void:
		_edge(Color(0.88, 0.96, 1.0, 0.95), 4 * u)
		_text_at(_ink())
		for g: Dictionary in _layout():
			var y := baseline - _gh(g.ch)
			for k in 3:
				var x: float = g.x + g.w * (0.2 + 0.3 * k)
				draw_circle(Vector2(x, y + 0.5 * u), (2.6 - 0.5 * (k % 2)) * u, Color(0.97, 0.99, 1.0), true, -1.0, true)

	func _p_frosted(ci: CanvasItem, t: float) -> void:
		for i in 6:
			var life := fposmod(t * 0.22 + i / 6.0, 1.0)
			var p := Vector2(lerpf(x0 - 10 * u, x1 + 10 * u, _h(i, 1)) + sin(life * 8.0 + i) * 3 * u, lerpf(top - 6 * u, baseline + 6 * u, life))
			var r := (1.2 + _h(i, 2)) * u
			for k in 3:
				var d := Vector2.from_angle(PI * k / 3.0 + life * 3.0) * r
				ci.draw_line(p - d, p + d, Color(0.9, 0.97, 1.0, sin(life * PI)), 0.8, true)

	## Magnetic: split into north and south, field lines looping round.
	func _r_poles() -> void:
		var c := Vector2(cx, cy)
		var rx := (x1 - x0) * 0.5 + 6 * u
		for k in 2:
			var ry := cap * 0.5 + (5 + 5 * k) * u
			_dashes(_oval_arc(c, rx + 4 * u * k, ry, PI * 1.05, PI * 1.95, 24), Color(tint, 0.5 - 0.15 * k), 1.2 * u, 3 * u, 2 * u)
			_dashes(_oval_arc(c, rx + 4 * u * k, ry, PI * 0.05, PI * 0.95, 24), Color(tint, 0.5 - 0.15 * k), 1.2 * u, 3 * u, 2 * u)
		_text_at(_ink())

	## Charged: inside a battery, bolt at the terminal.
	func _r_battery() -> void:
		var r := Rect2(x0 - 9 * u, top - 5 * u, x1 - x0 + 18 * u, cap + 10 * u)
		_rr(r, 4 * u, Color(tint, 0.1))
		_rr(r, 4 * u, Color(tint, 0.8), 1.6 * u)
		_rr(Rect2(r.end.x, cy - 5 * u, 3.5 * u, 10 * u), 1.2 * u, Color(tint, 0.8))
		for k in 3:
			_rr(Rect2(r.position.x + 3 * u, r.end.y - (6 + 6 * k) * u, 3 * u, 4.5 * u), 0.8 * u, Color(tint, 0.5))
		_text_at(_ink())
		var bolt := PackedVector2Array([Vector2(4, -11), Vector2(-3, 1), Vector2(1, 1), Vector2(-3, 11), Vector2(5, -2), Vector2(1, -2)])
		var o := Vector2(r.end.x + 10 * u, cy)
		var pts := PackedVector2Array()
		for p in bolt:
			pts.append(o + p * u * 0.9)
		_poly(pts, Color(1, 0.95, 0.4))

	func _p_battery(ci: CanvasItem, t: float) -> void:
		var o := Vector2(x1 + 9 * u + 3.5 * u + 10 * u, cy)
		var s := pow(maxf(0.0, sin(t * 5.0)), 4.0)
		for k in 3:
			var d := Vector2.from_angle(TAU * k / 3.0 + t) * 9 * u
			if s > 0.1:
				_bolt(ci, o, o + d, Color(1, 1, 0.6, s), 0.9 * u, floori(t * 5.0) * 3 + k, 3)

	## Resonant: ringing, its waves rippling out.
	func _r_resonance() -> void:
		var c := Vector2(cx, cy)
		for k in 3:
			_oval_line(c, (x1 - x0) * 0.5 + (6 + 6 * k) * u, cap * 0.5 + (2 + 3 * k) * u, Color(tint, 0.45 - 0.13 * k), 1.2 * u)
		_text_at(_ink())

	func _p_resonance(ci: CanvasItem, t: float) -> void:
		var c := Vector2(cx, cy)
		for k in 2:
			var life := fposmod(t * 0.45 + k * 0.5, 1.0)
			var pts := _oval(c, (x1 - x0) * 0.5 + (4 + 22 * life) * u, cap * 0.5 + (1 + 9 * life) * u)
			pts.append(pts[0])
			ci.draw_polyline(pts, Color(tint, 0.6 * (1.0 - life)), 1.2 * u, true)

	## Hollow: an empty shell, light enough to float.
	func _r_hollow() -> void:
		_poly(_oval(Vector2(cx, baseline + 5 * u), (x1 - x0) * 0.4, 1.8 * u), Color(0, 0, 0, 0.3))
		_edge(colour, 4 * u, Vector2(0, -3 * u))
		_text_at(Color(tint.darkened(0.6), 1.0), Vector2(0, -3 * u))
		_text_at(Color(tint, 0.18), Vector2(0, -3 * u))
		draw_line(Vector2(x0 + 4 * u, top), Vector2(x0 + 9 * u, top - 1 * u), Color(1, 1, 1, 0.6), 1 * u, true)

	## Leaded: cast in solid lead, deep and heavy.
	func _r_lead() -> void:
		for k in range(6, 0, -1):
			_text_at(Color(0.2, 0.22, 0.27).lerp(Color(0.12, 0.13, 0.16), k / 6.0), Vector2(k, k) * 0.6 * u)
		_text_at(_ink())

	## Bounty: on a wanted poster.
	func _r_wanted() -> void:
		var r := Rect2(x0 - 10 * u, top - 6 * u, x1 - x0 + 20 * u, cap + 12 * u)
		var paper := Color(0.88, 0.78, 0.56)
		var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y)])
		for i in 9:
			var t := i / 8.0
			pts.append(Vector2(lerpf(r.end.x, r.position.x, t), r.end.y - (1.5 * u if i % 2 else 0.0)))
		_poly(pts, paper)
		for p: Vector2 in [r.position + Vector2(3, 3) * u, Vector2(r.end.x - 3 * u, r.position.y + 3 * u)]:
			draw_circle(p, 1.2 * u, Color(0.35, 0.25, 0.15), true, -1.0, true)
		_text_at(Color(0.33, 0.2, 0.08))

	## Starry: a night sky, with stars trailing after it.
	func _r_starry() -> void:
		_edge(Color(colour, 0.95), 2.4 * u)
		_text_at(_ink())
		for k in 3:
			var p := Vector2(x1 + (6 + 8 * k) * u, cy + (2 - 4 * k) * u)
			_poly(_star5(p, (4.2 - k) * u, (1.8 - 0.4 * k) * u), Color(1, 0.9, 0.55, 0.95 - 0.25 * k))

	func _p_starry(ci: CanvasItem, t: float) -> void:
		for i in 5:
			var s := pow(maxf(0.0, sin(t * 1.8 + i * 1.7)), 4.0)
			var p := Vector2(lerpf(x0 - 10 * u, x1 + 4 * u, _h(i, 1)), lerpf(top - 5 * u, baseline + 5 * u, _h(i, 2)))
			_twinkle(ci, p, 3.5 * u * s, Color(1, 0.95, 0.75, s))

	## Twin: a solid and its striped twin, hopping over the letters.
	func _r_twin() -> void:
		var a := Vector2(x0 - 11 * u, baseline - 7 * u)
		var b := Vector2(x1 + 11 * u, baseline - 7 * u)
		var arc := PackedVector2Array()
		for i in 21:
			var t := i / 20.0
			arc.append(a.lerp(b, t) + Vector2(0, -sin(t * PI) * (cap + 8 * u)))
		_dashes(arc, Color(tint, 0.7), 1.3 * u, 3 * u, 2.5 * u)
		_head(arc[arc.size() - 1], arc[arc.size() - 1] - arc[arc.size() - 2], 5 * u, Color(tint, 0.9))
		_text_at(_ink())
		_ballpic(a, 6 * u, 3)
		_ballpic(b + Vector2(0, 2) * u, 6 * u, 11)

	# --- Special balls -----------------------------------------------------------------

	## Void: a black hole pulling everything round into it.
	func _r_void() -> void:
		var c := Vector2(cx, cy)
		for k in 3:
			var pts := PackedVector2Array()
			for i in 30:
				var th := i * 0.12
				pts.append(c + Vector2.from_angle(th + TAU * k / 3.0) * Vector2(1.5, 1.0) * (24 * u * exp(-0.12 * th)))
			draw_polyline(pts, Color(0.65, 0.35, 1.0, 0.5), 1.6 * u, true)
		draw_circle(c, 12 * u, Color(0, 0, 0, 0.85), true, -1.0, true)
		_edge(Color(0.85, 0.65, 1.0), 4 * u)
		_text_at(Color(0.1, 0.03, 0.18))

	func _p_void(ci: CanvasItem, t: float) -> void:
		var c := Vector2(cx, cy)
		for i in 6:
			var life := fposmod(t * 0.4 + i / 6.0, 1.0)
			var p := c + Vector2.from_angle(life * 5.0 + i * 1.3) * (30 * u * (1.0 - life))
			ci.draw_circle(p, 1.3 * u, Color(0.8, 0.6, 1.0, life), true, -1.0, true)

	## Glass: clear letters, a bright reflection across them.
	func _r_glass() -> void:
		_edge(Color(0.9, 0.97, 1.0), 3 * u)
		_text_at(bg)
		_text_at(_ink())

	func _p_glass(ci: CanvasItem, t: float) -> void:
		var s := pow(maxf(0.0, sin(t * 1.3)), 8.0)
		_twinkle(ci, Vector2(x1 - 3 * u, top + 3 * u), 6 * u * s, Color(1, 1, 1, s))

	## Iron: brushed steel on a riveted plate.
	func _r_iron() -> void:
		var r := Rect2(x0 - 9 * u, top - 5 * u, x1 - x0 + 18 * u, cap + 10 * u)
		_rr(r, 3 * u, Color(0.28, 0.3, 0.34))
		_rr(r, 3 * u, Color(0.55, 0.58, 0.63), 1 * u)
		for p: Vector2 in [r.position + Vector2(3.5, 3.5) * u, Vector2(r.end.x - 3.5 * u, r.position.y + 3.5 * u), r.end - Vector2(3.5, 3.5) * u, Vector2(r.position.x + 3.5 * u, r.end.y - 3.5 * u)]:
			draw_circle(p, 1.5 * u, Color(0.75, 0.77, 0.82), true, -1.0, true)
		_edge(Color(0.1, 0.11, 0.13), 2 * u)
		_text_at(_ink())

	## Feather: in front of a quill feather.
	func _r_plume() -> void:
		var a := Vector2(x0 - 12 * u, baseline + 5 * u)
		var b := Vector2(x1 + 14 * u, top - 5 * u)
		var d := (b - a).normalized()
		var n := d.orthogonal()
		var len := a.distance_to(b)
		var vane := PackedVector2Array()
		for i in 13:
			var t := lerpf(0.2, 1.0, i / 12.0)
			vane.append(a + d * len * t + n * sin((t - 0.2) / 0.8 * PI) * 8 * u)
		for i in range(12, -1, -1):
			var t := lerpf(0.2, 1.0, i / 12.0)
			vane.append(a + d * len * t - n * sin((t - 0.2) / 0.8 * PI) * 6 * u)
		_poly(vane, Color(tint.lerp(colour, 0.6), 0.22))
		for i in 9:
			var p := a + d * len * lerpf(0.3, 0.92, i / 8.0)
			draw_line(p, p + (n * 6 * u + d * 4 * u) * sin(lerpf(0.15, 0.95, i / 8.0) * PI), Color(tint, 0.35), 0.8 * u, true)
		draw_line(a, b, Color(colour, 0.6), 1.2 * u, true)
		_text_at(_ink())

	## Ember: a coal glowing through its cracks.
	func _r_coal() -> void:
		_edge(Color(1, 0.45, 0.1, 0.22), 9 * u)
		_edge(Color(1, 0.55, 0.15), 2.5 * u)
		_text_at(_ink())

	func _p_coal(ci: CanvasItem, t: float) -> void:
		_p_kindle(ci, t * 0.8)

	## Frost: frozen into a block of ice.
	func _r_iceblock() -> void:
		var r := Rect2(x0 - 9 * u, top - 6 * u, x1 - x0 + 18 * u, cap + 12 * u)
		_rr(r, 3 * u, Color(0.7, 0.9, 1.0, 0.16))
		_rr(r, 3 * u, Color(0.85, 0.96, 1.0, 0.75), 1.4 * u)
		draw_line(r.position + Vector2(3, 6) * u, r.position + Vector2(3, 14) * u, Color(1, 1, 1, 0.7), 1.2 * u, true)
		draw_line(r.position + Vector2(5, 3) * u, r.position + Vector2(13, 3) * u, Color(1, 1, 1, 0.7), 1.2 * u, true)
		_text_at(_ink())

	func _p_iceblock(ci: CanvasItem, t: float) -> void:
		for i in 3:
			var s := pow(maxf(0.0, sin(t * 1.5 + i * 2.1)), 6.0)
			var p := Vector2(lerpf(x0 - 6 * u, x1 + 6 * u, _h(i, 4)), lerpf(top - 3 * u, baseline + 3 * u, _h(i, 5)))
			_twinkle(ci, p, 4 * u * s, Color(1, 1, 1, s))

	## Magnet: a horseshoe magnet drawing balls in.
	func _r_pull() -> void:
		var c := Vector2(x0 - 13 * u, cy)
		var r := 7 * u
		draw_arc(c, r, PI * 0.5, PI * 1.5, 16, Color(0.9, 0.2, 0.2), 4 * u, true)
		draw_line(c + Vector2(0, -r), c + Vector2(6 * u, -r), Color(0.9, 0.2, 0.2), 4 * u, true)
		draw_line(c + Vector2(0, r), c + Vector2(6 * u, r), Color(0.9, 0.2, 0.2), 4 * u, true)
		for s in [-1.0, 1.0]:
			draw_line(c + Vector2(6 * u, s * r), c + Vector2(9 * u, s * r), Color(0.85, 0.87, 0.92), 4 * u, true)
		_text_at(_ink())
		for k in 2:
			var p := Vector2(x1 + (7 + 9 * k) * u, cy + (k * 6 - 3) * u)
			for m in 3:
				draw_line(p + Vector2((4 + m * 2) * u, (m - 1) * 1.6 * u), p + Vector2((7 + m * 3) * u, (m - 1) * 1.6 * u), Color(tint, 0.45), 1 * u, true)
			_ballpic(p, 3.4 * u, 0)

	## Prism: white light splitting into a rainbow.
	func _r_prism() -> void:
		var c := Vector2(x0 - 12 * u, cy)
		var tri := PackedVector2Array([c + Vector2(0, -9) * u, c + Vector2(8, 6) * u, c + Vector2(-8, 6) * u])
		draw_line(Vector2(c.x - 18 * u, cy + 4 * u), c + Vector2(-3, 1) * u, Color(1, 1, 1, 0.8), 1.4 * u, true)
		var hues := [0.0, 0.08, 0.16, 0.33, 0.55, 0.75]
		for k in hues.size():
			var col := Color.from_hsv(hues[k], 0.7, 1.0, 0.55)
			draw_line(c + Vector2(3, 0) * u, Vector2(x0 + 2 * u, cy - 9 * u + k * 3.6 * u), col, 1.4 * u, true)
		_poly(tri, Color(0.85, 0.95, 1.0, 0.3))
		tri.append(tri[0])
		draw_polyline(tri, Color(0.9, 0.97, 1.0, 0.9), 1.2 * u, true)
		_text_at(_ink())

	## Wild: any number at all behind it.
	func _r_wild() -> void:
		var spots := [[0.0, 0.2], [0.18, -0.15], [0.86, -0.12], [1.05, 0.35], [0.95, 0.95], [-0.08, 0.85], [0.45, 1.1], [0.62, -0.25]]
		for i in spots.size():
			var p := Vector2(lerpf(x0 - 10 * u, x1 + 10 * u, spots[i][0]), lerpf(top, baseline, spots[i][1]))
			_num(str([7, 13, 2, 11, 5, 14, 9, 3][i]), p, 10 * u, Color(tint.lerp(colour, 0.4), 0.3))
		_text_at(_ink())

	## Clock: on a clock face, the second hand sweeping round.
	func _r_clock() -> void:
		var c := Vector2(cx, cy)
		var r := cap * 0.5 + 9 * u
		draw_circle(c, r, Color(tint, 0.1), true, -1.0, true)
		draw_arc(c, r, 0, TAU, 48, Color(tint, 0.75), 1.6 * u, true)
		for i in 12:
			var d := Vector2.from_angle(TAU * i / 12.0)
			draw_line(c + d * (r - (3.5 if i % 3 == 0 else 2.0) * u), c + d * r, Color(tint, 0.8), 1.2 * u, true)
		draw_line(c, c + Vector2.from_angle(-PI * 0.5 - 1.05) * r * 0.55, Color(tint, 0.6), 2 * u, true)
		draw_line(c, c + Vector2.from_angle(-PI * 0.5 + 1.05) * r * 0.8, Color(tint, 0.6), 1.4 * u, true)
		_text_at(_ink())

	func _p_clock(ci: CanvasItem, t: float) -> void:
		var c := Vector2(cx, cy)
		var r := cap * 0.5 + 9 * u
		var a := -PI * 0.5 + TAU * floorf(t) / 60.0
		ci.draw_line(c, c + Vector2.from_angle(a) * (r - 1 * u), Color(1, 0.45, 0.4, 0.85), 0.8 * u, true)

	## Coin: struck on a coin with a milled edge.
	func _r_coin() -> void:
		var c := Vector2(cx, cy)
		var r := cap * 0.5 + 8 * u
		var face := Color(0.95, 0.75, 0.22)
		draw_circle(c, r, face, true, -1.0, true)
		for i in 48:
			var d := Vector2.from_angle(TAU * i / 48.0)
			draw_line(c + d * (r - 2 * u), c + d * r, face.darkened(0.3), 0.8 * u, true)
		draw_arc(c, r - 4 * u, 0, TAU, 48, face.darkened(0.25), 1 * u, true)
		for g: Dictionary in _layout(0.0, 0.8):
			_put(g, Color(1, 0.95, 0.72), Vector2(-0.8, -0.8) * u, 0.0, Vector2(0.8, 0.8))
			_put(g, Color(0.5, 0.33, 0.06), Vector2.ZERO, 0.0, Vector2(0.8, 0.8))

	func _p_coin(ci: CanvasItem, t: float) -> void:
		var r := cap * 0.5 + 8 * u
		var s := pow(maxf(0.0, sin(t * 1.4)), 6.0)
		_twinkle(ci, Vector2(cx, cy) + Vector2.from_angle(-2.3) * r, 6 * u * s, Color(1, 1, 0.85, s))

	## Bomb: in front of a bomb, its fuse lit.
	func _r_bomb() -> void:
		var c := Vector2(cx, cy + 1 * u)
		var r := cap * 0.5 + 7 * u
		draw_circle(c, r, Color(0.1, 0.1, 0.12), true, -1.0, true)
		draw_circle(c + Vector2(-0.4, -0.45) * r, r * 0.22, Color(1, 1, 1, 0.12), true, -1.0, true)
		var cap_at := c + Vector2.from_angle(-0.8) * r
		draw_set_transform(cap_at, 0.75)
		_rr(Rect2(-3.5 * u, -3 * u, 7 * u, 5 * u), 1 * u, Color(0.3, 0.3, 0.34))
		draw_set_transform(Vector2.ZERO)
		var fuse := PackedVector2Array()
		for i in 7:
			var t := i / 6.0
			fuse.append(cap_at + Vector2(t * 9 * u, -t * 7 * u - sin(t * PI) * 3 * u))
		draw_polyline(fuse, Color(0.75, 0.6, 0.4), 1.4 * u, true)
		_star(fuse[fuse.size() - 1], 3.5 * u, Color(1, 0.75, 0.25))
		_edge(Color(0.1, 0.1, 0.12), 3 * u)
		_text_at(_ink())

	func _p_bomb(ci: CanvasItem, t: float) -> void:
		var c := Vector2(cx, cy + 1 * u) + Vector2.from_angle(-0.8) * (cap * 0.5 + 7 * u) + Vector2(9, -7) * u
		for i in 5:
			var life := fposmod(t * 2.5 + i / 5.0, 1.0)
			var p := c + Vector2.from_angle(_h(floori(t * 2.5 + i / 5.0) * 5 + i) * TAU) * life * 7 * u
			ci.draw_circle(p, (1.1 - life) * u, Color(1, 0.8, 0.3, 1.0 - life), true, -1.0, true)

	## Seed: a sprout coming up beside it.
	func _r_sprout() -> void:
		var soil := Color(0.45, 0.3, 0.18)
		draw_line(Vector2(x0 - 8 * u, baseline + 3 * u), Vector2(x1 + 18 * u, baseline + 3 * u), soil, 2 * u, true)
		var s := Vector2(x1 + 10 * u, baseline + 2 * u)
		_poly(_oval(s + Vector2(0, 1) * u, 3 * u, 2 * u, 12), Color(0.75, 0.6, 0.35))
		var stem := PackedVector2Array()
		for i in 9:
			var t := i / 8.0
			stem.append(s + Vector2(sin(t * PI) * 2.5 * u, -t * 22 * u))
		var green := Color(0.45, 0.85, 0.35)
		draw_polyline(stem, green, 1.6 * u, true)
		var tip := stem[stem.size() - 1]
		for side in [-1.0, 1.0]:
			var leaf := PackedVector2Array()
			for i in 9:
				var t := i / 8.0
				leaf.append(tip + Vector2(side * t * 9 * u, -sin(t * PI) * 3.5 * u - t * 3 * u))
			for i in range(7, 0, -1):
				var t := i / 8.0
				leaf.append(tip + Vector2(side * t * 9 * u, sin(t * PI) * 1.5 * u - t * 3 * u))
			_poly(leaf, green)
		_text_at(_ink())

	## Clover: in front of a big four-leaf clover.
	func _r_bigclover() -> void:
		var c := Vector2(cx, cy)
		var green := Color(0.35, 0.8, 0.45, 0.38)
		for k in 4:
			var d := Vector2.from_angle(PI * 0.25 + PI * 0.5 * k)
			var leaf := _heart_pts(c + d * 11 * u, 22 * u)
			_poly(_turned(leaf, c + d * 11 * u, PI * 0.5 * k + PI * 0.75), green)
		draw_line(c + Vector2(0, 4 * u), c + Vector2(8, 24) * u, Color(0.35, 0.8, 0.45, 0.6), 2 * u, true)
		_text_at(_ink())

	## Star: in front of a star, bouncing off the rail at full speed.
	func _r_star() -> void:
		var c := Vector2(cx, cy)
		var pts := _star5(c, cap * 0.5 + 7 * u, 9 * u)
		_poly(pts, Color(1, 0.85, 0.3, 0.28))
		pts.append(pts[0])
		draw_polyline(pts, Color(1, 0.88, 0.4, 0.75), 1.3 * u, true)
		_text_at(_ink())

	func _p_star(ci: CanvasItem, t: float) -> void:
		var c := Vector2(cx, cy)
		for k in 5:
			var s := pow(maxf(0.0, sin(t * 2.0 + k * 1.3)), 6.0)
			_twinkle(ci, c + Vector2.from_angle(-PI * 0.5 + TAU * k / 5.0) * (cap * 0.5 + 7 * u), 4 * u * s, Color(1, 1, 0.85, s))

	## Heart: in front of a heart.
	func _r_heart() -> void:
		var c := Vector2(cx, cy + 1 * u)
		var pts := _heart_pts(c + Vector2(0, -5 * u), 50 * u)
		_poly(pts, Color(1, 0.4, 0.6, 0.3))
		pts.append(pts[0])
		draw_polyline(pts, Color(1, 0.55, 0.72, 0.8), 1.4 * u, true)
		_text_at(_ink())

	func _p_heart(ci: CanvasItem, t: float) -> void:
		for i in 3:
			var life := fposmod(t * 0.35 + i / 3.0, 1.0)
			var p := Vector2(lerpf(x0 - 8 * u, x1 + 8 * u, _h(i, 7)) + sin(life * 6.0 + i) * 3 * u, baseline - life * (cap + 10 * u))
			var pts := _heart_pts(p, 6 * u)
			ci.draw_colored_polygon(pts, Color(1, 0.55, 0.75, sin(life * PI) * 0.9))

	## Dice: beside a tumbling die.
	func _r_die() -> void:
		_text_at(_ink())
		var c := Vector2(x1 + 12 * u, cy + 2 * u)
		var s := 8 * u
		var top_f := PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, -s * 0.5), c, c + Vector2(-s, -s * 0.5)])
		var left_f := PackedVector2Array([c + Vector2(-s, -s * 0.5), c, c + Vector2(0, s), c + Vector2(-s, s * 0.5)])
		var right_f := PackedVector2Array([c, c + Vector2(s, -s * 0.5), c + Vector2(s, s * 0.5), c + Vector2(0, s)])
		draw_colored_polygon(top_f, Color(0.97, 0.96, 0.94))
		draw_colored_polygon(left_f, Color(0.82, 0.82, 0.86))
		draw_colored_polygon(right_f, Color(0.7, 0.7, 0.76))
		var pip := Color(0.12, 0.12, 0.16)
		draw_circle(c + Vector2(0, -s * 0.5), 1.1 * u, pip, true, -1.0, true)
		for p: Vector2 in [Vector2(-0.7, 0.05), Vector2(-0.3, 0.45)]:
			draw_circle(c + p * s, 1 * u, pip, true, -1.0, true)
		for p: Vector2 in [Vector2(0.3, -0.05), Vector2(0.5, 0.15), Vector2(0.7, 0.35)]:
			draw_circle(c + p * s, 0.9 * u, pip, true, -1.0, true)

	## Moon: cratered, under a crescent moon.
	func _r_moon() -> void:
		var c := Vector2(x0 - 10 * u, top + 4 * u)
		draw_circle(c, 8 * u, Color(0.92, 0.93, 1.0, 0.9), true, -1.0, true)
		draw_circle(c + Vector2(4, -2) * u, 7.5 * u, bg, true, -1.0, true)
		_text_at(_ink())
		for p in [[0.2, 0.3, 2.0], [0.55, 0.7, 1.6], [0.8, 0.35, 1.3], [0.35, 0.8, 1.2]]:
			var q := Vector2(lerpf(x0, x1, p[0]), lerpf(top, baseline, p[1]))
			draw_arc(q, p[2] * u, 0, TAU, 12, Color(0.55, 0.58, 0.7, 0.8), 0.8 * u, true)
		for s in [[1.08, 0.1], [1.15, 0.6]]:
			_star(Vector2(lerpf(x0, x1, s[0]), lerpf(top, baseline, s[1])), 2.4 * u, Color(1, 1, 0.9, 0.85))

	## Sun: rays blazing out from behind.
	func _r_sun() -> void:
		var c := Vector2(cx, cy)
		var r := cap * 0.5 + 1 * u
		draw_circle(c, r, Color(1, 0.75, 0.2, 0.35), true, -1.0, true)
		for i in 12:
			var a := TAU * i / 12.0
			var d := Vector2.from_angle(a)
			var n := d.orthogonal()
			_poly(PackedVector2Array([c + d * (r + 2 * u) + n * 2.6 * u, c + d * (r + (7 if i % 2 == 0 else 5) * u), c + d * (r + 2 * u) - n * 2.6 * u]), Color(1, 0.8, 0.25, 0.65))
		_text_at(_ink())

	## Anchor: in front of a ship's anchor.
	func _r_anchor() -> void:
		var c := Vector2(cx, cy)
		var col := Color(tint.lerp(colour, 0.4), 0.55)
		var h := cap * 0.5 + 6 * u
		draw_line(c + Vector2(0, -h + 4 * u), c + Vector2(0, h), col, 2.4 * u, true)
		draw_arc(c + Vector2(0, -h + 1.5 * u), 2.8 * u, 0, TAU, 14, col, 1.6 * u, true)
		draw_line(c + Vector2(-9 * u, -h + 8 * u), c + Vector2(9 * u, -h + 8 * u), col, 2.4 * u, true)
		draw_arc(c + Vector2(0, h - 13 * u), 13 * u, PI * 0.15, PI * 0.85, 20, col, 2.4 * u, true)
		for s in [-1.0, 1.0]:
			var tip := c + Vector2(0, h - 13 * u) + Vector2.from_angle(PI * 0.5 - s * PI * 0.35) * 13 * u
			_head(tip + Vector2(0, -2 * u), Vector2(s * 0.3, -1), 6 * u, col)
		_text_at(_ink())

	## Eraser: being rubbed out from the right.
	func _r_erase() -> void:
		_text_at(_ink())
		var c := Vector2(x1 + 4 * u, baseline - 4 * u)
		draw_set_transform(c, -0.45)
		_rr(Rect2(-5 * u, -6 * u, 18 * u, 10 * u), 2 * u, Color(1, 0.6, 0.68))
		_rr(Rect2(5 * u, -6 * u, 8 * u, 10 * u), 1 * u, Color(0.4, 0.5, 1.0))
		draw_set_transform(Vector2.ZERO)
		for d in [[2, 6, 1.0], [-4, 8, 0.8], [6, 9, 0.7]]:
			draw_circle(c + Vector2(d[0], d[1]) * u, d[2] * u, Color(1, 0.6, 0.68, 0.8), true, -1.0, true)

	func _p_erase(ci: CanvasItem, t: float) -> void:
		var c := Vector2(x1 + 4 * u, baseline - 4 * u)
		for i in 4:
			var life := fposmod(t * 0.9 + i * 0.25, 1.0)
			ci.draw_circle(c + Vector2((-6 + 4 * i) * u, (4 + life * 10) * u), 0.8 * u, Color(1, 0.6, 0.68, 1.0 - life), true, -1.0, true)

	## Echo: looping back round to the foot spot.
	func _r_return() -> void:
		var r := cap * 0.5 + 3 * u
		var c := Vector2(x1 + 3 * u, cy)
		var pts := _oval_arc(c, 12 * u, r, -PI * 0.5, PI * 0.5, 16)
		pts.append(Vector2(x0 - 4 * u, c.y + r))
		_dashes(pts, Color(tint, 0.75), 1.4 * u, 3 * u, 2.5 * u)
		var spot := Vector2(x0 - 9 * u, c.y + r)
		_head(spot + Vector2(1.5 * u, 0), Vector2.LEFT, 5 * u, Color(tint, 0.9))
		_poly(PackedVector2Array([spot + Vector2(-3, 0) * u, spot + Vector2(0, -2) * u, spot + Vector2(3, 0) * u, spot + Vector2(0, 2) * u]), colour)
		_text_at(_ink())

	## Comet: blazing across, its tail streaming behind.
	func _r_comet() -> void:
		var head := Vector2(x1 + 7 * u, top + 3 * u)
		var tail := Vector2(x0 - 22 * u, baseline + 4 * u)
		var d := (head - tail).normalized()
		var n := d.orthogonal()
		var pts := PackedVector2Array([tail, head + n * 6 * u, head - n * 6 * u])
		draw_polygon(pts, PackedColorArray([Color(0.6, 0.8, 1.0, 0.0), Color(0.75, 0.88, 1.0, 0.55), Color(0.75, 0.88, 1.0, 0.55)]))
		draw_circle(head, 6 * u, Color(0.8, 0.9, 1.0, 0.35), true, -1.0, true)
		draw_circle(head, 3.6 * u, Color(0.95, 0.98, 1.0), true, -1.0, true)
		_text_at(_ink())

	func _p_comet(ci: CanvasItem, t: float) -> void:
		var head := Vector2(x1 + 7 * u, top + 3 * u)
		var tail := Vector2(x0 - 22 * u, baseline + 4 * u)
		for i in 6:
			var life := fposmod(t * 0.8 + i / 6.0, 1.0)
			var p := head.lerp(tail, life) + (head - tail).orthogonal().normalized() * (_h(i) - 0.5) * 8 * u * life
			ci.draw_circle(p, (1.4 - life) * u, Color(0.9, 0.95, 1.0, 1.0 - life), true, -1.0, true)

	# --- Items ---------------------------------------------------------------------------

	## Ghost Chalk: a ghost the ball passes straight through.
	func _r_ghost() -> void:
		var y := cy + 1 * u
		draw_line(Vector2(x0 - 18 * u, y), Vector2(x1 + 8 * u, y), Color(tint, 0.3), 1 * u, true)
		_dashes(_oval(Vector2(x0 + (x1 - x0) * 0.55, y), 7 * u, 7 * u), Color(1, 1, 1, 0.7), 1.2 * u, 2 * u, 1.6 * u)
		_text_at(_ink())
		var pts := PackedVector2Array()
		for i in 17:
			var t := i / 16.0
			pts.append(Vector2(lerpf(x0, x1, t), baseline + 2 * u + sin(t * TAU * 2.0) * 1.6 * u))
		draw_polyline(pts, Color(colour, 0.5), 1.2 * u, true)
		_ballpic(Vector2(x1 + 12 * u, y), 4 * u, 0)

	func _p_ghost(ci: CanvasItem, t: float) -> void:
		for i in 3:
			var life := fposmod(t * 0.4 + i / 3.0, 1.0)
			var p := Vector2(lerpf(x0, x1, _h(i, 3)) + sin(life * 7.0 + i) * 3 * u, top - life * 8 * u + 4 * u)
			ci.draw_circle(p, (2.2 - life) * u, Color(1, 1, 1, 0.35 * (1.0 - life)), true, -1.0, true)

	## Swap: the two letters trading places.
	func _r_swap() -> void:
		var gl := _layout(6 * u)
		var a := Vector2(gl[0].x + gl[0].w * 0.5, top - 3 * u)
		var b := Vector2(gl[-1].x + gl[-1].w * 0.5, top - 3 * u)
		for s in [-1.0, 1.0]:
			var p0 := a if s < 0 else b + Vector2(0, cap + 5 * u)
			var p1 := b if s < 0 else a + Vector2(0, cap + 5 * u)
			var arc := PackedVector2Array()
			for i in 13:
				var t := i / 12.0
				arc.append(p0.lerp(p1, t) + Vector2(0, s * sin(t * PI) * (5 if s < 0 else 3) * u))
			draw_polyline(arc, Color(tint, 0.8), 1.5 * u, true)
			_head(arc[12], arc[12] - arc[10], 5 * u, Color(tint, 0.95))
		# Entangled: a wave runs between the pair.
		var wave := PackedVector2Array()
		var wa := Vector2(gl[0].x + gl[0].w * 0.5, cy)
		var wb := Vector2(gl[-1].x + gl[-1].w * 0.5, cy)
		for i in 25:
			var t := i / 24.0
			wave.append(wa.lerp(wb, t) + Vector2(0, sin(t * TAU * 2.0) * 3 * u))
		draw_polyline(wave, Color(tint.lightened(0.3), 0.55), 1.4 * u, true)
		for g: Dictionary in gl:
			_put(g, _ink())

	## Polish: buffed to a mirror shine.
	func _r_chrome() -> void:
		for k in 3:
			draw_arc(Vector2(x1 + 10 * u, baseline - 4 * u), (3 + 2.5 * k) * u, -PI * 0.9 + k, PI * 0.4 + k, 12, Color(tint, 0.5 - 0.12 * k), 1 * u, true)
		_edge(Color(0.25, 0.28, 0.32), 2 * u)
		_text_at(_ink())

	func _p_chrome(ci: CanvasItem, t: float) -> void:
		var life := fposmod(t * 0.35, 1.0)
		if life < 0.4:
			_twinkle(ci, Vector2(lerpf(x0, x1, life / 0.4), top + cap * 0.3), 5 * u * sin(life / 0.4 * PI), Color(1, 1, 1, sin(life / 0.4 * PI)))

	## Lead Weight: stamped on a lead weight.
	func _r_kettle() -> void:
		var bw := x1 - x0 + 20 * u
		var y0 := top - 3 * u
		var y1 := baseline + 6 * u
		var pts := PackedVector2Array([Vector2(cx - bw * 0.38, y0), Vector2(cx + bw * 0.38, y0), Vector2(cx + bw * 0.5, y1), Vector2(cx - bw * 0.5, y1)])
		draw_polygon(pts, PackedColorArray([Color(0.48, 0.5, 0.56), Color(0.48, 0.5, 0.56), Color(0.28, 0.3, 0.35), Color(0.28, 0.3, 0.35)]))
		draw_arc(Vector2(cx, y0), 6 * u, PI, TAU, 16, Color(0.48, 0.5, 0.56), 2.4 * u, true)
		_text_at(Color(0.85, 0.87, 0.92))

	## Spotter: a ball dropping back onto the foot spot.
	func _r_spot() -> void:
		var spot := Vector2(x1 + 12 * u, baseline + 2 * u)
		draw_line(spot - Vector2(6 * u, 0), spot + Vector2(6 * u, 0), Color(tint, 0.6), 1 * u, true)
		draw_line(spot - Vector2(0, 3 * u), spot + Vector2(0, 3 * u), Color(tint, 0.6), 1 * u, true)
		draw_circle(spot, 1.6 * u, colour, true, -1.0, true)
		_dashes(PackedVector2Array([spot + Vector2(0, -26) * u, spot + Vector2(0, -9) * u]), Color(tint, 0.7), 1.2 * u, 2.5 * u, 2 * u)
		_head(spot + Vector2(0, -6) * u, Vector2.DOWN, 5 * u, Color(tint, 0.9))
		_ballpic(spot + Vector2(0, -29) * u + Vector2(0, 2) * u, 4 * u, 5)
		_text_at(_ink())

	## Blink: vanishing from one spot and appearing at another.
	func _r_blink() -> void:
		var a := Vector2(x0 - 13 * u, baseline - 5 * u)
		var b := Vector2(x1 + 13 * u, top + 3 * u)
		_dashes(_oval(a, 4 * u, 4 * u, 16), Color(1, 1, 1, 0.55), 1 * u, 1.6 * u, 1.6 * u)
		var arc := PackedVector2Array()
		for i in 17:
			var t := i / 16.0
			arc.append(a.lerp(b, t) + Vector2(0, -sin(t * PI) * 10 * u))
		_dashes(arc, Color(tint, 0.5), 1 * u, 1.5 * u, 3 * u)
		_ballpic(b, 4 * u, 0)
		_text_at(_ink())

	func _p_blink(ci: CanvasItem, t: float) -> void:
		var a := Vector2(x0 - 13 * u, baseline - 5 * u)
		var b := Vector2(x1 + 13 * u, top + 3 * u)
		for i in 4:
			var s := pow(maxf(0.0, sin(t * 3.0 + i * 1.6)), 4.0)
			var at := a if i % 2 == 0 else b
			_twinkle(ci, at + Vector2.from_angle(i * 2.2) * 6 * u, 3 * u * s, Color(1, 1, 1, s))

	## Freeze Frame: caught on a strip of film.
	func _r_film() -> void:
		var r := Rect2(x0 - 14 * u, top - 7 * u, x1 - x0 + 28 * u, cap + 14 * u)
		for y: float in [r.position.y, r.end.y - 4 * u]:
			_rr(Rect2(r.position.x, y, r.size.x, 4 * u), 0.8 * u, Color(0.1, 0.1, 0.12, 0.9))
			var x := r.position.x + 2 * u
			while x < r.end.x - 3 * u:
				draw_rect(Rect2(x, y + 1.2 * u, 2.4 * u, 1.6 * u), Color(tint, 0.5))
				x += 5 * u
		draw_line(Vector2(r.position.x, r.position.y + 4 * u), Vector2(r.position.x, r.end.y - 4 * u), Color(tint, 0.4), 1 * u)
		draw_line(Vector2(r.end.x, r.position.y + 4 * u), Vector2(r.end.x, r.end.y - 4 * u), Color(tint, 0.4), 1 * u)
		_text_at(_ink())

	## Nudge: pushed a little way along.
	func _r_nudge() -> void:
		_text_at(Color(tint, 0.2), Vector2(-5 * u, 0))
		var y := cy
		draw_line(Vector2(x0 - 20 * u, y), Vector2(x0 - 4 * u, y), Color(tint, 0.85), 2 * u, true)
		_head(Vector2(x0 - 1 * u, y), Vector2.RIGHT, 6 * u, Color(tint, 0.95))
		for k in 3:
			var a := -0.6 + 0.6 * k
			draw_line(Vector2(x0 + 2 * u, y) + Vector2.from_angle(PI + a) * 2 * u, Vector2(x0 + 2 * u, y) + Vector2.from_angle(PI + a) * 1 * u, Color(colour, 0.5), 1 * u, true)
		_text_at(_ink(), Vector2(2 * u, 0))

	## English Dial: in front of a spin dial.
	func _r_dial() -> void:
		var c := Vector2(cx, cy)
		var r := cap * 0.5 + 9 * u
		draw_arc(c, r, -PI * 1.25, PI * 0.25, 40, Color(tint, 0.6), 1.6 * u, true)
		for i in 13:
			var a := lerpf(-PI * 1.25, PI * 0.25, i / 12.0)
			var d := Vector2.from_angle(a)
			draw_line(c + d * (r + 1 * u), c + d * (r + (4.0 if i % 3 == 0 else 2.2) * u), Color(tint, 0.7), 1.1 * u, true)
		var needle := Vector2.from_angle(-PI * 0.2)
		draw_line(c + needle * (r - 6 * u), c + needle * (r + 5 * u), Color(1, 0.5, 0.4), 1.8 * u, true)
		_text_at(_ink())

	## Gravity Pebble: the cloth bent into a well.
	func _warp(p: Vector2, c: Vector2) -> Vector2:
		var d := c - p
		var l := d.length()
		return p + d.normalized() * minf(l * 0.7, 140.0 * u * u / (l + 12 * u))

	func _r_warp() -> void:
		var c := Vector2(cx, baseline + 1 * u)
		var a := Vector2(x0 - 22 * u, top - 6 * u)
		var b := Vector2(x1 + 22 * u, baseline + 8 * u)
		for k in 6:
			var y := lerpf(a.y, b.y, k / 5.0)
			var pts := PackedVector2Array()
			for i in 21:
				pts.append(_warp(Vector2(lerpf(a.x, b.x, i / 20.0), y), c))
			draw_polyline(pts, Color(tint, 0.28), 1 * u, true)
		for k in 9:
			var x := lerpf(a.x, b.x, k / 8.0)
			var pts := PackedVector2Array()
			for i in 13:
				pts.append(_warp(Vector2(x, lerpf(a.y, b.y, i / 12.0)), c))
			draw_polyline(pts, Color(tint, 0.28), 1 * u, true)
		draw_circle(c, 2.6 * u, Color(0.6, 0.62, 0.7), true, -1.0, true)
		_text_at(_ink())

	func _p_warp(ci: CanvasItem, t: float) -> void:
		var c := Vector2(cx, baseline + 1 * u)
		var life := fposmod(t * 0.35, 1.0)
		var r := lerpf(26.0, 3.0, life) * u
		var p := c + Vector2(cos(t * 3.0) * r, sin(t * 3.0) * r * 0.45)
		ci.draw_circle(p, 2.2 * u, Color(0.96, 0.95, 0.9, sin(life * PI)), true, -1.0, true)

	## Rewind: running backwards.
	func _r_rewind() -> void:
		var o := Vector2(x0 - 7 * u, cy)
		for k in 2:
			var tip := o + Vector2(-k * 7 * u - 7 * u, 0)
			_poly(PackedVector2Array([tip, tip + Vector2(7, -6) * u, tip + Vector2(7, 6) * u]), Color(tint, 0.85))
		for k in 3:
			var y := top + (6 + 9 * k) * u
			draw_line(Vector2(x1 + 3 * u, y), Vector2(x1 + (16 - 4 * k) * u, y), Color(tint, 0.5), 1.6 * u, true)
		_text_at(_ink())

	## Post: a bumper post, a ball bouncing off it.
	func _r_post() -> void:
		var c := Vector2(x1 + 12 * u, cy + 2 * u)
		draw_circle(c, 7 * u, Color(tint, 0.85), true, -1.0, true)
		draw_circle(c, 4.5 * u, Color(0.85, 0.86, 0.9), true, -1.0, true)
		draw_circle(c, 2 * u, Color(0.55, 0.57, 0.62), true, -1.0, true)
		var hit := c + Vector2(-5, -6) * u
		draw_line(hit + Vector2(-10, -8) * u, hit, Color(tint, 0.55), 1.2 * u, true)
		draw_line(hit, hit + Vector2(-2, -12) * u, Color(tint, 0.55), 1.2 * u, true)
		for k in 3:
			var d := Vector2.from_angle(-PI * 0.75 + (k - 1) * 0.45)
			draw_line(c + d * 8.5 * u, c + d * 11 * u, Color(colour, 0.7), 1 * u, true)
		_text_at(_ink())

	## Portal Pair: in one portal and out of the other.
	func _r_portal() -> void:
		var a := Vector2(x0 - 12 * u, cy)
		var b := Vector2(x1 + 12 * u, cy)
		for p in [[a, Color(0.35, 0.65, 1.0)], [b, Color(1.0, 0.6, 0.2)]]:
			var c: Vector2 = p[0]
			var col: Color = p[1]
			_poly(_oval(c, 5 * u, 15 * u), Color(col, 0.18))
			_oval_line(c, 5 * u, 15 * u, Color(col, 0.95), 2 * u)
			_oval_line(c, 3 * u, 10 * u, Color(col, 0.5), 1 * u)
		_dashes(PackedVector2Array([a + Vector2(5, 0) * u, b - Vector2(5, 0) * u]), Color(colour, 0.25), 1 * u, 2 * u, 3 * u)
		_text_at(_ink())

	func _p_portal(ci: CanvasItem, t: float) -> void:
		var a := Vector2(x0 - 12 * u, cy)
		var b := Vector2(x1 + 12 * u, cy)
		for i in 6:
			var c := a if i < 3 else b
			var ang := t * (2.0 if i < 3 else -2.0) + i * TAU / 3.0
			ci.draw_circle(c + Vector2(cos(ang) * 4 * u, sin(ang) * 12 * u), 1 * u, Color(1, 1, 1, 0.7), true, -1.0, true)

	# --- Elements reworked into physics ---------------------------------------------

	## Lead Anchor: a heavy 8 sunk into the cloth; a ball glances off it.
	func _r_anchor8() -> void:
		var c := Vector2(x1 + 13 * u, baseline - 7 * u)
		draw_set_transform(c + Vector2(0, 7 * u), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, 10 * u, Color(0, 0, 0, 0.5), true, -1.0, true)
		draw_set_transform(Vector2.ZERO)
		var b := Vector2(c.x + 4 * u, top - 3 * u)
		_dashes(PackedVector2Array([b, c + Vector2(2, -8) * u]), Color(tint, 0.7), 1.2 * u, 2.5 * u, 2 * u)
		_dashes(PackedVector2Array([c + Vector2(2, -8) * u, c + Vector2(14, -10) * u]), Color(tint, 0.7), 1.2 * u, 2.5 * u, 2 * u)
		_head(c + Vector2(15, -10.2) * u, Vector2(1, -0.15), 4.5 * u, Color(tint, 0.9))
		_text_at(_ink())
		_ballpic(c, 7.5 * u, 8)
		_ballpic(b, 3.2 * u, 12)

	## Holmium Magnet: field lines bending rolling balls down into two pockets.
	func _r_pole() -> void:
		for side in [-1.0, 1.0]:
			var pk := Vector2((x0 - 14 * u) if side < 0 else (x1 + 14 * u), baseline + 1 * u)
			for k in 3:
				var pts := PackedVector2Array()
				var start := Vector2(cx + side * (6 + 7 * k) * u, top - 4 * u)
				for i in 13:
					var t := i / 12.0
					pts.append(start.lerp(pk, t) + Vector2(0, -sin(t * PI) * (3 + 2 * k) * u))
				_dashes(pts, Color(tint, 0.55 - 0.12 * k), 1.1 * u, 2.5 * u, 2 * u)
			_pocket(pk, 5 * u)
			draw_arc(pk, 8 * u, 0, TAU, 24, Color(1, 0.5, 0.25, 0.7), 1.2 * u, true)
		_text_at(_ink())

	## Tungsten Core: a heavy stripe ploughing through, knocking two balls aside.
	func _r_core() -> void:
		var c := Vector2(x1 + 14 * u, cy + 4 * u)
		for k in 3:
			draw_line(Vector2(x0 - (16 - 2 * k) * u, cy + (k - 1) * 6 * u), Vector2(x0 - 6 * u, cy + (k - 1) * 6 * u), Color(tint, 0.45), 2.2 * u, true)
		_edge(Color(0, 0, 0, 0.5), 4 * u, Vector2(1.5, 1.5) * u)
		_text_at(_ink())
		_ballpic(c, 7 * u, 12)
		for side in [-1.0, 1.0]:
			var b := c + Vector2(7 * u, side * 12 * u)
			_ballpic(b, 3 * u, 2 if side < 0 else 5)
			_head(b + Vector2(5 * u, side * 3 * u), Vector2(1, side * 0.6), 3.5 * u, Color(tint, 0.85))

	## Gallium Glide: letters starting to melt, a cue ball sliding far on a long trail.
	func _r_glide() -> void:
		var y := baseline + 4.5 * u
		draw_polyline_colors(PackedVector2Array([Vector2(x0 - 18 * u, y), Vector2(x1 + 10 * u, y)]), PackedColorArray([Color(tint, 0.0), Color(tint, 0.8)]), 2 * u, true)
		_text_at(_ink())
		for k in 3:
			var x := lerpf(x0 + 4 * u, x1 - 6 * u, k / 2.0)
			var h := (3 + 2 * k) * u
			draw_line(Vector2(x, baseline - 1 * u), Vector2(x, baseline + h * 0.4), Color(colour, 0.7), 2.2 * u, true)
			draw_circle(Vector2(x, baseline + h * 0.4 + 1 * u), 1.4 * u, Color(colour, 0.7), true, -1.0, true)
		draw_circle(Vector2(x1 + 14 * u, y - 0.5 * u), 4 * u, Color(0.97, 0.96, 0.92), true, -1.0, true)
		draw_circle(Vector2(x1 + 12.6 * u, y - 2 * u), 1.2 * u, Color(1, 1, 1), true, -1.0, true)

	## Neodymium Magnet: a rolling cue ball, field lines reaching out to a ball it tugs along.
	func _r_ndmagnet() -> void:
		var cue := Vector2(x1 + 12 * u, cy + 6 * u)
		var b := Vector2(x1 + 16 * u, top - 4 * u)
		for k in 3:
			var pts := PackedVector2Array()
			for i in 11:
				var t := i / 10.0
				pts.append(cue.lerp(b, t) + Vector2((k - 1) * 5 * u * sin(t * PI), 0))
			_dashes(pts, Color(tint, 0.65 - 0.15 * absi(k - 1)), 1.1 * u, 2 * u, 1.6 * u)
		draw_polyline_colors(PackedVector2Array([cue - Vector2(22 * u, 0), cue - Vector2(5 * u, 0)]), PackedColorArray([Color(colour, 0), Color(colour, 0.6)]), 1.6 * u, true)
		_head(b + Vector2(0, 7 * u), Vector2.DOWN, 4 * u, Color(tint, 0.9))
		_text_at(_ink())
		draw_circle(cue, 4.5 * u, Color(0.97, 0.96, 0.92), true, -1.0, true)
		draw_arc(cue, 7 * u, 0, TAU, 20, Color(1, 0.3, 0.3, 0.7), 1.2 * u, true)
		_ballpic(b, 3.6 * u, 6)

	# --- Catalysts drawn for the rework ----------------------------------------------

	## Black Hole: a hole torn in the cushion, with matter spiralling in.
	func _r_blackhole() -> void:
		var y := baseline + 4 * u
		var c := Vector2(x1 + 11 * u, y - 2 * u)
		var wood := Color(0.5, 0.3, 0.15)
		draw_line(Vector2(x0 - 12 * u, y), Vector2(c.x - 9 * u, y), wood, 3 * u, true)
		draw_line(Vector2(c.x + 9 * u, y), Vector2(c.x + 16 * u, y), wood, 3 * u, true)
		for k in 3:
			var pts := PackedVector2Array()
			for i in 25:
				var a := TAU * i / 24.0 * 1.4 + k * TAU / 3.0
				var r := (12.0 - i * 0.3) * u
				pts.append(c + Vector2(cos(a) * r, sin(a) * r * 0.5))
			draw_polyline(pts, Color(1, 0.62, 0.32, 0.5), 1.2 * u, true)
		draw_circle(c, 5.5 * u, Color(0, 0, 0), true, -1.0, true)
		draw_arc(c, 6.2 * u, 0, TAU, 24, Color(1, 0.78, 0.45, 0.85), 1 * u, true)
		_text_at(_ink())

	func _p_blackhole(ci: CanvasItem, t: float) -> void:
		var c := Vector2(x1 + 11 * u, baseline + 2 * u)
		for i in 5:
			var life := fposmod(t * 0.5 + i / 5.0, 1.0)
			var a := TAU * _h(i, 41) + life * 5.0
			var r := (14.0 * (1.0 - life) + 6.0) * u
			ci.draw_circle(c + Vector2(cos(a) * r, sin(a) * r * 0.5), 1.1 * u, Color(1, 0.85, 0.55, 1.0 - life), true, -1.0, true)

	## Event Horizon: a pocket under the letters, ringed by a dark halo twice its width.
	func _r_horizon() -> void:
		var c := Vector2(cx, cy + 2 * u)
		for k in 7:
			draw_circle(c, (24.0 - k * 2.4) * u, Color(0, 0, 0, 0.12), true, -1.0, true)
		_dashes(_oval(Vector2(c.x, c.y), 30 * u, 21 * u, 48), Color(tint, 0.75), 1.2 * u, 3 * u, 2.5 * u)
		draw_arc(c, 12 * u, 0, TAU, 40, Color(tint, 0.5), 1 * u, true)
		_text_at(_ink())

	## Force Field: a glowing barrier under the letters, honeycomb shimmering behind them.
	func _r_field() -> void:
		var glow := tint.lerp(Color(0.6, 1.0, 1.0), 0.5)
		var r := 3.2 * u
		var row := 0
		var y := top - 2 * u
		while y < baseline + 2 * u:
			var x := x0 - 8 * u + (r * 0.87 if row % 2 else 0.0)
			while x < x1 + 8 * u:
				var hexs := PackedVector2Array()
				for k in 7:
					hexs.append(Vector2(x, y) + Vector2.from_angle(PI / 6.0 + TAU * k / 6.0) * r)
				draw_polyline(hexs, Color(glow, 0.16), 0.8 * u, true)
				x += r * 1.74
			y += r * 1.5
			row += 1
		var by := baseline + 4.5 * u
		for k in 3:
			draw_line(Vector2(x0 - 10 * u, by), Vector2(x1 + 10 * u, by), Color(glow, 0.15 + 0.3 * k), (8.0 - 3.0 * k) * u, true)
		for x: float in [x0 - 11 * u, x1 + 11 * u]:
			draw_circle(Vector2(x, by), 2.6 * u, Color(0.85, 0.9, 0.95), true, -1.0, true)
		_text_at(_ink())

	func _p_field(ci: CanvasItem, t: float) -> void:
		var by := baseline + 4.5 * u
		for i in 3:
			var f := fposmod(t * 0.7 + i / 3.0, 1.0)
			var x := lerpf(x0 - 9 * u, x1 + 9 * u, f)
			ci.draw_circle(Vector2(x, by), 2.2 * u, Color(1, 1, 1, 0.8 * sin(f * PI)), true, -1.0, true)

	## Centre of Mass: three balls, each with an arrow to the point between them.
	func _r_centre() -> void:
		var c := Vector2(cx, baseline + 1 * u)
		var balls := [Vector2(x0 - 14 * u, top + 1 * u), Vector2(x1 + 14 * u, top + 1 * u), Vector2(x1 + 15 * u, baseline - 1 * u)]
		var nums := [3, 10, 6]
		for i in 3:
			var b: Vector2 = balls[i]
			var d := (c - b).normalized()
			_dashes(PackedVector2Array([b + d * 6 * u, c - d * 6 * u]), Color(tint, 0.75), 1.3 * u, 3 * u, 2.5 * u)
			_head(c - d * 4 * u, d, 4.5 * u, Color(tint, 0.95))
		_text_at(_ink())
		for i in 3:
			_ballpic(balls[i], 4.6 * u, nums[i])
		draw_circle(c, 2.6 * u, colour, true, -1.0, true)
		draw_arc(c, 4.4 * u, 0, TAU, 20, Color(colour, 0.8), 1 * u, true)

	## Reflection: a ball running at a mirror line and turning straight back.
	func _r_reflect() -> void:
		var mx := x1 + 17 * u
		draw_line(Vector2(mx, top - 4 * u), Vector2(mx, baseline + 4 * u), Color(0.8, 0.9, 1.0, 0.85), 2 * u, true)
		for k in 5:
			var yy := top - 2 * u + k * (cap + 6 * u) / 5.0
			draw_line(Vector2(mx, yy), Vector2(mx + 3 * u, yy + 3 * u), Color(0.8, 0.9, 1.0, 0.4), 1 * u, true)
		var turn := PackedVector2Array()
		for i in 17:
			var a := lerpf(-PI * 0.5, PI * 0.5, i / 16.0)
			turn.append(Vector2(mx - 4 * u, cy) + Vector2(cos(a) * 3 * u, sin(a) * 7 * u))
		_dashes(PackedVector2Array([Vector2(x1 + 2 * u, cy - 7 * u), turn[0]]), Color(tint, 0.8), 1.3 * u, 2.5 * u, 2 * u)
		draw_polyline(turn, Color(tint, 0.85), 1.4 * u, true)
		_dashes(PackedVector2Array([turn[16], Vector2(x1 + 4 * u, cy + 7 * u)]), Color(tint, 0.8), 1.3 * u, 2.5 * u, 2 * u)
		_head(Vector2(x1 + 2 * u, cy + 7 * u), Vector2.LEFT, 5 * u, Color(tint, 0.95))
		_text_at(_ink())
		_ballpic(Vector2(mx - 9 * u, cy - 7 * u), 3.6 * u, 11)

	## Pythagorean Triple: a 3-4-5 right triangle of glowing walls between three balls.
	func _r_triple() -> void:
		var a := Vector2(x0 - 9 * u, baseline + 5 * u)
		var b := Vector2(x1 + 9 * u, baseline + 5 * u)
		var c := Vector2(x0 - 9 * u, baseline + 5 * u - (b.x - a.x) * 0.75 * 0.55)
		var glow := tint.lerp(Color(0.6, 1.0, 1.0), 0.45)
		for seg in [[a, b], [a, c], [c, b]]:
			draw_line(seg[0], seg[1], Color(glow, 0.22), 5 * u, true)
			draw_line(seg[0], seg[1], Color(glow, 0.85), 1.4 * u, true)
		draw_polyline(PackedVector2Array([a + Vector2(5 * u, 0), a + Vector2(5 * u, -5 * u), a + Vector2(0, -5 * u)]), Color(glow, 0.9), 1 * u, true)
		_text_at(_ink())
		_ballpic(a, 4 * u, 3)
		_ballpic(b, 4 * u, 4)
		_ballpic(c, 4 * u, 5)

	## Newton's Cradle: a frame beside the letters; one ball has swung in and the
	## far one flies out with all its momentum.
	func _r_cradle() -> void:
		var bar_y := top - 5 * u
		var x := x1 + 5 * u
		var gap := 6.4 * u
		var frame := Color(0.75, 0.78, 0.82)
		draw_line(Vector2(x - 2 * u, bar_y), Vector2(x + gap * 3 + 4 * u, bar_y), frame, 1.6 * u, true)
		var hang := baseline - 2 * u - bar_y
		for i in 4:
			var pivot := Vector2(x + gap * i, bar_y)
			var ang := 0.55 if i == 3 else 0.0
			var bpos := pivot + Vector2(sin(ang), cos(ang)) * hang
			draw_line(pivot, bpos, Color(frame, 0.6), 0.8 * u, true)
			draw_circle(bpos, 3.1 * u, Color(0.86, 0.88, 0.92), true, -1.0, true)
			draw_circle(bpos + Vector2(-1, -1) * u, 1 * u, Color(1, 1, 1, 0.9), true, -1.0, true)
		draw_arc(Vector2(x + gap * 3, bar_y), hang + 2 * u, PI * 0.5 - 0.55, PI * 0.5 - 0.1, 10, Color(tint, 0.7), 1.2 * u, true)
		_text_at(_ink())

	# --- Side bets: a picture of what to do, instead of letters ---------------------------

	func _r_b_solid() -> void:
		_ballpic(Vector2(cx, cy), 15 * u, 3)

	func _r_b_stripe() -> void:
		_ballpic(Vector2(cx, cy), 15 * u, 11)

	func _rails(corner: Vector2, ax: Vector2, ay: Vector2, len: float) -> void:
		var felt := Color(0.1, 0.45, 0.3, 0.55)
		_poly(PackedVector2Array([corner, corner + ax * len, corner + ax * len + ay * len * 0.8, corner + ay * len * 0.8]), felt)
		draw_line(corner, corner + ax * len, Color(0.5, 0.3, 0.15), 3 * u, true)
		draw_line(corner, corner + ay * len * 0.8, Color(0.5, 0.3, 0.15), 3 * u, true)

	func _r_b_corner() -> void:
		var corner := Vector2(cx - 20 * u, top - 4 * u)
		_rails(corner, Vector2.RIGHT, Vector2.DOWN, 44 * u)
		_pocket(corner + Vector2(3, 3) * u, 6 * u)
		var b := corner + Vector2(26, 22) * u
		_dashes(PackedVector2Array([b, corner + Vector2(9, 8) * u]), Color(1, 1, 1, 0.6), 1.2 * u, 2.5 * u, 2 * u)
		_ballpic(b, 5 * u, 1)

	func _r_b_side() -> void:
		var y := top - 2 * u
		_poly(PackedVector2Array([Vector2(cx - 30 * u, y), Vector2(cx + 30 * u, y), Vector2(cx + 30 * u, baseline + 6 * u), Vector2(cx - 30 * u, baseline + 6 * u)]), Color(0.1, 0.45, 0.3, 0.55))
		draw_line(Vector2(cx - 30 * u, y), Vector2(cx + 30 * u, y), Color(0.5, 0.3, 0.15), 3 * u, true)
		_pocket(Vector2(cx, y + 2 * u), 6 * u)
		var b := Vector2(cx + 8 * u, baseline - 4 * u)
		_dashes(PackedVector2Array([b, Vector2(cx + 1 * u, y + 9 * u)]), Color(1, 1, 1, 0.6), 1.2 * u, 2.5 * u, 2 * u)
		_ballpic(b, 5 * u, 6)

	func _hotpocket(c: Vector2, r: float) -> void:
		for i in 8:
			var a := TAU * i / 8.0
			var base := c + Vector2.from_angle(a) * (r + 1 * u)
			var d := Vector2.from_angle(a)
			var n := d.orthogonal()
			_poly(PackedVector2Array([base + n * 3 * u, base + d * (6 + (i % 2) * 3) * u, base - n * 3 * u]), Color(1, 0.5 + (i % 2) * 0.25, 0.15, 0.85))
		_pocket(c, r, Color(1, 0.6, 0.2))

	func _r_b_hot() -> void:
		_hotpocket(Vector2(cx, cy), 11 * u)

	func _r_b_breakpot() -> void:
		var o := Vector2(cx + 6 * u, cy)
		var r := 4.6 * u
		var nums := [1, 9, 2, 10, 8, 3]
		var k := 0
		for row in 3:
			for j in row + 1:
				var p := o + Vector2(row * r * 1.75, (j - row * 0.5) * r * 2.05)
				_ballpic(p + Vector2.from_angle(TAU * k / 6.0) * 1.5 * u, r, nums[k])
				k += 1
		var cue := o + Vector2(-26, 0) * u
		draw_line(cue + Vector2(-16, 0) * u, cue + Vector2(-6, 0) * u, Color(0.85, 0.7, 0.45), 2.4 * u, true)
		_ballpic(cue, r, 0)
		for k2 in 3:
			var d := Vector2.from_angle(PI + (k2 - 1) * 0.5)
			draw_line(o + Vector2(-5 * u, 0) + d * 3 * u, o + Vector2(-5 * u, 0) + d * 7 * u, Color(1, 1, 0.8, 0.8), 1.2 * u, true)

	func _meter(fill: float, col: Color) -> void:
		var r := Rect2(cx - 28 * u, cy - 5 * u, 56 * u, 10 * u)
		_rr(r, 3 * u, Color(0, 0, 0, 0.45))
		_rr(Rect2(r.position, Vector2(r.size.x * fill, r.size.y)), 3 * u, col)
		_rr(r, 3 * u, Color(tint, 0.8), 1.2 * u)
		for f: float in [0.35, 0.85]:
			var x := r.position.x + r.size.x * f
			draw_line(Vector2(x, r.position.y - 3 * u), Vector2(x, r.end.y + 3 * u), Color(colour, 0.8), 1 * u, true)

	func _r_b_hard() -> void:
		_meter(0.95, Color(1, 0.4, 0.25))
		var o := Vector2(cx + 22 * u, cy - 15 * u)
		var bolt := PackedVector2Array([Vector2(4, -9), Vector2(-3, 1), Vector2(1, 1), Vector2(-3, 10), Vector2(5, -2), Vector2(1, -2)])
		var pts := PackedVector2Array()
		for p in bolt:
			pts.append(o + p * u * 0.8)
		_poly(pts, Color(1, 0.9, 0.35))

	func _r_b_soft() -> void:
		_meter(0.3, Color(0.5, 0.8, 1.0))
		var a := Vector2(cx - 26 * u, cy - 9 * u)
		var b := Vector2(cx - 8 * u, cy - 17 * u)
		var d := (b - a).normalized()
		var n := d.orthogonal()
		var vane := PackedVector2Array()
		for i in 9:
			var t := i / 8.0
			vane.append(a.lerp(b, t) + n * sin(t * PI) * 4 * u)
		for i in range(8, -1, -1):
			var t := i / 8.0
			vane.append(a.lerp(b, t) - n * sin(t * PI) * 3 * u)
		_poly(vane, Color(0.95, 0.95, 1.0, 0.75))

	func _flamebadge(n: int, scale_f: float) -> void:
		var base := Vector2(cx, baseline - 5 * u)
		_flame(base, 13 * u * scale_f, 34 * u * scale_f, Color(1, 0.45, 0.12, 0.85))
		_flame(base, 8 * u * scale_f, 19 * u * scale_f, Color(1, 0.8, 0.3, 0.9))
		_num(str(n), base - Vector2(0, 8 * u * scale_f), 20 * u * scale_f, Color(0.25, 0.08, 0.02))

	func _r_b_heat3() -> void:
		_flamebadge(3, 0.85)

	func _r_b_heat4() -> void:
		_flamebadge(4, 0.95)

	func _r_b_heat5() -> void:
		_flamebadge(5, 1.05)

	func _r_b_double() -> void:
		var pk := Vector2(cx, baseline - 2 * u)
		_pocket(pk, 8 * u)
		_ballpic(pk + Vector2(-9, -17) * u, 5.5 * u, 4)
		_ballpic(pk + Vector2(8, -21) * u, 5.5 * u, 12)
		for s in [-1.0, 1.0]:
			_head(pk + Vector2(s * 4, -9) * u, Vector2(-s * 0.3, 1), 4 * u, Color(colour, 0.7))

	func _bankpic(bounces: int) -> void:
		var top_y := top - 3 * u
		draw_line(Vector2(cx - 32 * u, top_y), Vector2(cx + 32 * u, top_y), Color(0.5, 0.3, 0.15), 3 * u, true)
		if bounces > 1:
			draw_line(Vector2(cx + 32 * u, top_y), Vector2(cx + 32 * u, baseline + 6 * u), Color(0.5, 0.3, 0.15), 3 * u, true)
		var b := Vector2(cx - 22 * u, baseline - 2 * u)
		var pk := Vector2(cx + 2 * u, baseline + 2 * u) if bounces == 1 else Vector2(cx - 6 * u, baseline + 3 * u)
		var pts := PackedVector2Array([b, Vector2(cx - 8 * u, top_y + 2 * u)])
		if bounces > 1:
			pts.append(Vector2(cx + 30 * u, cy - 2 * u))
		pts.append(pk)
		_dashes(pts, Color(1, 1, 1, 0.65), 1.3 * u, 3 * u, 2 * u)
		for k in range(1, pts.size() - 1):
			draw_circle(pts[k], 1.6 * u, Color(tint, 0.95), true, -1.0, true)
		_pocket(pk, 5 * u)
		_ballpic(b, 5 * u, 7)

	func _r_b_bank() -> void:
		_bankpic(1)

	func _r_b_bank2() -> void:
		_bankpic(2)

	func _r_b_combo() -> void:
		var y := cy + 2 * u
		var xs := [cx - 26 * u, cx - 10 * u, cx + 4 * u]
		draw_line(Vector2(xs[0], y), Vector2(cx + 20 * u, y), Color(1, 1, 1, 0.35), 1.2 * u, true)
		_ballpic(Vector2(xs[0], y), 5 * u, 0)
		_ballpic(Vector2(xs[1], y), 5 * u, 2)
		_ballpic(Vector2(xs[2], y), 5 * u, 5)
		_pocket(Vector2(cx + 22 * u, y), 6 * u)
		for x: float in [xs[0] + 6 * u, xs[1] + 6 * u]:
			draw_line(Vector2(x, y - 6 * u), Vector2(x + 2 * u, y - 8 * u), Color(1, 1, 0.8, 0.8), 1 * u, true)

	func _r_b_kick() -> void:
		var rail_y := top - 3 * u
		draw_line(Vector2(cx - 32 * u, rail_y), Vector2(cx + 32 * u, rail_y), Color(0.5, 0.3, 0.15), 3 * u, true)
		var cue := Vector2(cx - 24 * u, baseline - 2 * u)
		var hit := Vector2(cx - 6 * u, rail_y + 2 * u)
		var obj := Vector2(cx + 10 * u, cy + 4 * u)
		_dashes(PackedVector2Array([cue, hit, obj - Vector2(4, 4) * u]), Color(1, 1, 1, 0.65), 1.3 * u, 3 * u, 2 * u)
		draw_circle(hit, 1.8 * u, Color(tint, 0.95), true, -1.0, true)
		_ballpic(cue, 5 * u, 0)
		_ballpic(obj, 5 * u, 13)
		_pocket(Vector2(cx + 26 * u, baseline + 3 * u), 5 * u)

	func _chainbadge(n: int) -> void:
		for k in 4:
			var c := Vector2(cx - 24 * u + k * 13 * u, cy + 2 * u)
			if k % 2 == 0:
				_oval_line(c, 8 * u, 4.5 * u, Color(tint, 0.8), 2.2 * u)
			else:
				draw_line(c - Vector2(7 * u, 0), c + Vector2(7 * u, 0), Color(tint, 0.8), 2.6 * u, true)
		draw_circle(Vector2(cx, cy), 11 * u, Color(0.06, 0.06, 0.08, 0.95), true, -1.0, true)
		draw_arc(Vector2(cx, cy), 11 * u, 0, TAU, 32, Color(tint, 0.95), 1.6 * u, true)
		_num(str(n), Vector2(cx, cy), 18 * u, colour)

	func _r_b_chain5() -> void:
		_chainbadge(5)

	func _r_b_chain7() -> void:
		_chainbadge(7)

	func _pie(frac: float) -> void:
		var c := Vector2(cx, cy)
		var r := 15 * u
		draw_circle(c, r, Color(0, 0, 0, 0.4), true, -1.0, true)
		var pts := PackedVector2Array([c])
		for i in 25:
			pts.append(c + Vector2.from_angle(-PI * 0.5 + TAU * frac * i / 24.0) * r)
		_poly(pts, Color(tint, 0.9))
		draw_arc(c, r, 0, TAU, 40, Color(colour, 0.8), 1.4 * u, true)
		draw_arc(c, r + 4 * u, 0, TAU, 40, Color(colour, 0.4), 1 * u, true)

	func _r_b_quarter() -> void:
		_pie(0.25)

	func _r_b_half() -> void:
		_pie(0.5)

	func _r_b_triple() -> void:
		var pk := Vector2(cx, baseline - 1 * u)
		_pocket(pk, 8 * u)
		for p in [[-13, -16, 1], [0, -23, 11], [13, -16, 6]]:
			_ballpic(pk + Vector2(p[0], p[1]) * u, 5 * u, p[2])

	func _r_b_hot2() -> void:
		var pk := Vector2(cx, cy + 5 * u)
		_hotpocket(pk, 7 * u)
		_ballpic(pk + Vector2(-17, -10) * u, 5 * u, 2)
		_ballpic(pk + Vector2(17, -12) * u, 5 * u, 14)

	func _r_b_eight() -> void:
		var c := Vector2(cx, cy + 1 * u)
		var pts := PackedVector2Array([c + Vector2(-5, -24) * u, c + Vector2(5, -24) * u, c + Vector2(20, 16) * u, c + Vector2(-20, 16) * u])
		draw_polygon(pts, PackedColorArray([Color(1, 1, 0.9, 0.3), Color(1, 1, 0.9, 0.3), Color(1, 1, 0.9, 0.04), Color(1, 1, 0.9, 0.04)]))
		for p: Vector2 in [Vector2(-24, 8), Vector2(24, 4)]:
			_dashes(_oval(c + p * u, 4 * u, 4 * u, 14), Color(tint, 0.35), 1 * u, 1.5 * u, 1.5 * u)
		_ballpic(c + Vector2(0, 4) * u, 11 * u, 8)

	## The back of every face-down bet: a lattice of little atoms and a question mark.
	func _r_b_back() -> void:
		var r := Rect2(8, 36, TileArt.SIZE.x - 16, 44)
		var col := Color(tint, 0.22)
		var y := r.position.y + 4
		var row := 0
		while y < r.end.y:
			var x := r.position.x + 5 + (7.0 if row % 2 else 0.0)
			while x < r.end.x - 2:
				draw_arc(Vector2(x, y), 2.4, 0, TAU, 10, col, 0.8, true)
				x += 14
			y += 8
			row += 1
		var c := Vector2(cx, 58)
		draw_circle(c, 17, bg, true, -1.0, true)
		draw_arc(c, 17, 0, TAU, 40, Color(tint, 0.9), 1.6, true)
		for k in 3:
			var pts := _turned(_oval(c, 15, 5.5, 28), c, PI * k / 3.0)
			pts.append(pts[0])
			draw_polyline(pts, Color(tint, 0.35), 0.8, true)
		_num("?", c + Vector2(0, 1), 26, colour)

	# --- Particles for perks --------------------------------------------------------------

	func _p_stoke(ci: CanvasItem, t: float) -> void:
		for i in 6:
			var life := fposmod(t * 0.55 + i / 6.0, 1.0)
			var x := lerpf(x0, x1, _h(i, 1)) + sin(life * 6.0 + i) * 2 * u
			ci.draw_circle(Vector2(x, _top_at(x) - 1 * u - life * 9 * u), (1.5 - life) * u, Color(1, 0.6 + 0.3 * _h(i, 2), 0.2, 1.0 - life), true, -1.0, true)

	func _p_inferno(ci: CanvasItem, t: float) -> void:
		for i in 8:
			var life := fposmod(t * 0.9 + i / 8.0, 1.0)
			var x := lerpf(x0 - 2 * u, x1 + 2 * u, _h(i, 4)) + sin(life * 9.0 + i * 2.0) * 3 * u
			ci.draw_circle(Vector2(x, top + 4 * u - life * 14 * u), (1.3 - life) * u, Color(1, 0.75 + 0.2 * _h(i, 5), 0.3, 1.0 - life), true, -1.0, true)

	func _p_simmer(ci: CanvasItem, t: float) -> void:
		for i in 4:
			var life := fposmod(t * 0.4 + i / 4.0, 1.0)
			var x := lerpf(x0, x1, _h(i, 6)) + sin(life * 5.0 + i) * 1.5 * u
			ci.draw_arc(Vector2(x, _top_at(x) - life * 10 * u), (0.8 + life * 2.0) * u, 0, TAU, 12, Color(tint, 0.8 * (1.0 - life)), 1.0, true)

	func _p_frost(ci: CanvasItem, t: float) -> void:
		_p_frosted(ci, t)

	func _p_clean(ci: CanvasItem, t: float) -> void:
		for i in 3:
			var s := pow(maxf(0.0, sin(t * 1.6 + i * 2.1)), 6.0)
			var p := Vector2(lerpf(x0 - 4 * u, x1 + 6 * u, _h(i, 8)), lerpf(top - 2 * u, baseline, _h(i, 9)))
			_twinkle(ci, p, 4 * u * s, Color(1, 1, 1, s))

	func _p_nuggets(ci: CanvasItem, t: float) -> void:
		_p_clean(ci, t * 0.8 + 1.0)

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


## A special ball as it looks on the table: its colour, its band, the white
## disc with its emblem, a shine and a shadow on the cloth. It turns slowly,
## and holds still while Fx.minimal_particles is on.
class BallPic extends Control:
	var bt: Dictionary
	var t := 0.0
	const C := Vector2(86, 57)
	const RAD := 22.0

	func _init(id: String) -> void:
		bt = Catalog.BALL_TYPES[id]
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(delta: float) -> void:
		if not Fx.minimal_particles and is_visible_in_tree():
			t += delta
			queue_redraw()

	func _draw() -> void:
		var col: Color = bt.color
		var acc: Color = bt.accent
		# Shadow on the felt, then the ball.
		draw_set_transform(C + Vector2(3, RAD - 1), 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, RAD * 0.95, Color(0, 0, 0, 0.45), true, -1.0, true)
		draw_set_transform(Vector2.ZERO)
		draw_circle(C, RAD, col, true, -1.0, true)
		# The pattern band, rolling slowly round the ball.
		var roll := sin(t * 0.6) * 0.35
		var hw := RAD * 0.42
		if int(bt.get("pattern", 0)) % 2 == 1:
			draw_colored_polygon(_clip_band(hw, roll), Color(acc, 0.85))
		# The darker side away from the light.
		draw_arc(C, RAD - 3.0, PI * 0.15, PI * 1.05, 32, Color(0, 0, 0, 0.22), 6.0, true)
		# White disc and emblem.
		var dc := C + Vector2(sin(t * 0.6) * 2.0, -1.0)
		draw_circle(dc, RAD * 0.56, Color(0.97, 0.96, 0.9), true, -1.0, true)
		var ink: Color = col.darkened(0.2) if col.get_luminance() < 0.7 else acc.darkened(0.25)
		IconArt.paint(self, bt.motif, dc, RAD * 0.42 / 34.0, ink, Color(0.97, 0.96, 0.9), TileArt.F_SEMI, 1.6)
		# Shine.
		draw_circle(C + Vector2(-RAD * 0.42, -RAD * 0.45), RAD * 0.2, Color(1, 1, 1, 0.55), true, -1.0, true)
		draw_circle(C + Vector2(-RAD * 0.5, -RAD * 0.52), RAD * 0.09, Color(1, 1, 1, 0.9), true, -1.0, true)
		draw_arc(C, RAD, 0, TAU, 48, Color(0, 0, 0, 0.35), 1.0, true)

	## The band across the middle of the ball, as a polygon clipped to the ball.
	func _clip_band(hw: float, roll: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var off := roll * 4.0
		var top := clampf(-hw + off, -RAD + 1, RAD - 1)
		var bot := clampf(hw + off, -RAD + 1, RAD - 1)
		var a0 := asin(top / RAD)
		var a1 := asin(bot / RAD)
		for i in 13:
			var a := lerpf(a0, a1, i / 12.0)
			pts.append(C + Vector2(cos(a) * RAD, sin(a) * RAD))
		for i in 13:
			var a := lerpf(a1, a0, i / 12.0)
			pts.append(C + Vector2(-cos(a) * RAD, sin(a) * RAD))
		return pts


## A starting cue, lying across the tile: butt, wrap, shaft, ferrule and tip in
## the cue's own colours, with a cue ball waiting at the tip and, for object
## cues, the object it carries.
class CuePic extends Control:
	var cue: Dictionary

	func _init(id: String) -> void:
		cue = Catalog.CUES[id]
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		var a := Vector2(14, 76)
		var b := Vector2(132, 46)
		var d := (b - a).normalized()
		var n := d.orthogonal()
		var len := a.distance_to(b)
		var piece := func(f0: float, f1: float, w0: float, w1: float, col: Color) -> void:
			var p0 := a + d * len * f0
			var p1 := a + d * len * f1
			draw_colored_polygon(PackedVector2Array([p0 + n * w0, p1 + n * w1, p1 - n * w1, p0 - n * w0]), col)
		draw_colored_polygon(PackedVector2Array([a + n * 4.5 + Vector2(3, 5), b + n * 1.6 + Vector2(3, 5), b - n * 1.6 + Vector2(3, 5), a - n * 4.5 + Vector2(3, 5)]), Color(0, 0, 0, 0.35))
		piece.call(0.0, 0.42, 4.5, 3.6, cue.butt)
		piece.call(0.02, 0.06, 4.6, 4.5, Color(0.08, 0.08, 0.09))
		piece.call(0.16, 0.36, 4.0, 3.7, Color(cue.butt).darkened(0.35))
		for k in 6:
			var f := 0.17 + k * 0.032
			var p := a + d * len * f
			draw_line(p + n * 4.0, p - n * 4.0, Color(cue.accent, 0.7), 1.0, true)
		piece.call(0.42, 0.97, 3.6, 1.7, cue.shaft)
		piece.call(0.40, 0.44, 3.8, 3.7, cue.accent)
		piece.call(0.95, 0.985, 1.8, 1.7, Color(0.96, 0.95, 0.9))
		piece.call(0.985, 1.0, 1.7, 1.6, Color(0.3, 0.55, 0.95))
		draw_line(a + d * len * 0.43 + n * 1.4, b - d * 6 + n * 0.6, Color(1, 1, 1, 0.35), 1.0, true)
		var cb := b + d * 12
		draw_circle(cb + Vector2(2, 3), 6.5, Color(0, 0, 0, 0.35), true, -1.0, true)
		draw_circle(cb, 6.5, Color(0.97, 0.96, 0.92), true, -1.0, true)
		draw_circle(cb + Vector2(-2, -2), 1.8, Color(1, 1, 1), true, -1.0, true)
		var kit: String = cue.get("kit", "")
		if kit != "":
			var c := Vector2(150, 70)
			draw_circle(c, 13, Color(0, 0, 0, 0.3), true, -1.0, true)
			draw_arc(c, 13, 0, TAU, 32, Color(cue.accent, 0.8), 1.4, true)
			IconArt.paint(self, IconArt.motif_for(kit), c, 0.28, cue.accent, Color(0.1, 0.1, 0.12), TileArt.F_SEMI, 1.6)


## The real ball numbers a card works on, as little balls floating either side
## of the symbol. They bob gently, and hold still while Fx.minimal_particles is on.
class Floaters extends Control:
	var nums := []
	var tint := Color.WHITE
	var t := 0.0

	func _init(n: Array, c: Color) -> void:
		nums = n
		tint = c
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(delta: float) -> void:
		if not Fx.minimal_particles and is_visible_in_tree():
			t += delta
			queue_redraw()

	func _draw() -> void:
		var half := ceili(nums.size() / 2.0)
		for i in nums.size():
			var left := i < half
			var j := i if left else i - half
			var n_side := half if left else nums.size() - half
			var col := j % 2
			var row := j / 2
			var rows := ceili(n_side / 2.0)
			var x := (11.0 + col * 16.0) if left else (TileArt.SIZE.x - 27.0 + col * 16.0)
			if n_side == 1:
				x = 19.0 if left else TileArt.SIZE.x - 19.0
			var y := 58.0 + (row - (rows - 1) * 0.5) * 17.0 + (4.0 if col == 1 and n_side > 2 else 0.0) - (2.0 if n_side > 2 else 0.0)
			var c := Vector2(x, y + sin(t * 1.4 + i * 1.3) * 1.4)
			var n: int = nums[i]
			var bc := Catalog.ball_color(n)
			draw_circle(c, 8.2, Color(tint, 0.16), true, -1.0, true)
			if Catalog.is_stripe(n):
				draw_circle(c, 6.8, Color(0.95, 0.93, 0.88), true, -1.0, true)
				var band := PackedVector2Array()
				var half_a := asin(3.4 / 6.8)
				for q in 7:
					band.append(c + Vector2.from_angle(lerpf(-half_a, half_a, q / 6.0)) * 6.8)
				for q in 7:
					band.append(c + Vector2.from_angle(PI + lerpf(-half_a, half_a, q / 6.0)) * 6.8)
				draw_colored_polygon(band, bc)
			else:
				draw_circle(c, 6.8, bc, true, -1.0, true)
			draw_circle(c, 4.1, Color(0.97, 0.95, 0.9), true, -1.0, true)
			var txt := str(n)
			var fsz := 8 if n < 10 else 7
			var tw := TileArt.F_SEMI.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
			draw_string(TileArt.F_SEMI, c + Vector2(-tw * 0.5, fsz * 0.37), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(0.06, 0.06, 0.08))


## Small moving particles over a tile's lettering (embers, sparkles, snow...),
## drawn by the effect's _p_<name> method. Nothing is drawn while
## Fx.minimal_particles is on; the still lettering is complete without them.
class Motes extends Control:
	var host: Lettering
	var fn := ""
	var t := 1.7
	var shown := true

	func _init(h: Lettering, f: String) -> void:
		host = h
		fn = f
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(delta: float) -> void:
		var want := not Fx.minimal_particles
		if want != shown:
			shown = want
			queue_redraw()
		if want and is_visible_in_tree():
			t += delta
			queue_redraw()

	func _draw() -> void:
		if Fx.minimal_particles:
			return
		host._box()
		host.call(fn, self, t)
