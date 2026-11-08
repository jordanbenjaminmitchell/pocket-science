class_name ScreenFit
extends RefCounted
## Works out where the table and HUD go for a given window shape.
##
## Classic is the fixed 1600x900 frame, letterboxed by the engine. Wide uses the
## whole of a wider-than-16:9 screen: the table sits dead centre, the score panel
## on its left and the Perks in a column on its right. All values are in canvas
## units, where the height is always 900.

const FRAME := Vector2(1600, 900)
## The table including its wooden rails, as placed in the Classic frame.
const TABLE_BOX := Rect2(358, 12, 1227, 700)
const MIN_PANEL := 256.0
const MAX_PANEL := 330.0
const GAP := 8.0
const EDGE := 14.0
const PANEL_MARGIN := 24.0    # left + right padding inside a side panel
const WIDE_CARD_H := 124.0


static func classic() -> Dictionary:
	return {
		"wide": false,
		"view": FRAME,
		"frame_x": 0.0,
		"table_offset": Vector2.ZERO,
		"panel_pos": Vector2(14, 14),
		"panel_size": Vector2(330, 872),
		"perks_pos": Vector2(360, 712),
		"perks_size": Vector2(1226, 174),
		"perks_vertical": false,
		"card": Vector2(192, 132),
		"table_zone": Rect2(352, 0, 1248, 706),
	}


## `hole` is how far a camera cutout intrudes from a short screen edge. The phone
## can be turned either way up, so both sides leave room for it.
static func solve(window: Vector2, want_wide: bool, hole: float) -> Dictionary:
	if not want_wide or window.x <= 0.0 or window.y <= 0.0:
		return classic()
	var width := roundf(FRAME.y * window.x / window.y)
	if width <= FRAME.x:
		return classic()
	var view := Vector2(width, FRAME.y)
	var offset := (view * 0.5 - TABLE_BOX.get_center()).round()
	var table_left := TABLE_BOX.position.x + offset.x
	var right := TABLE_BOX.end.x + offset.x + GAP
	var margin := maxf(hole, EDGE)
	var room := minf(table_left - GAP - margin, width - right - margin)
	if room < MIN_PANEL:
		return classic()   # not enough screen either side to be worth it
	var w := minf(room, MAX_PANEL)
	var left := table_left - GAP - w
	return {
		"wide": true,
		"view": view,
		"frame_x": (width - FRAME.x) * 0.5,
		"table_offset": offset,
		"panel_pos": Vector2(left, 14),
		"panel_size": Vector2(w, 872),
		"perks_pos": Vector2(right, 14),
		"perks_size": Vector2(w, 872),
		"perks_vertical": true,
		"card": Vector2(w - PANEL_MARGIN, WIDE_CARD_H),
		"table_zone": Rect2(left + w, 0, right - left - w, FRAME.y),
	}
