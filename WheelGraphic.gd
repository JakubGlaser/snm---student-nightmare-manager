extends Control
# Pure-drawing helper for the special ability wheel. SpecialWheel.gd owns the
# spin logic and just feeds us `rotation_angle` + the segment list, then calls
# queue_redraw(). We render the colored pie segments, the labels (rotated so they
# read along each slice) and a fixed pointer/needle at the top.

const RIM_COLOR := Color(0.15, 0.065, 0.015, 1.0)
const CREAM := Color(1.0, 0.94, 0.78, 1.0)
const TEXT_COLOR := Color(0.12, 0.06, 0.02, 1.0)
const NEEDLE_COLOR := Color(0.85, 0.12, 0.12, 1.0)

# Each entry: { "title": String, "color": Color }
var segments: Array = []
var rotation_angle: float = 0.0
var label_font: Font = null

func _draw() -> void:
	var n := segments.size()
	if n == 0:
		return

	var center := size * 0.5
	# Leave headroom for the needle that sticks out above the rim.
	var radius : float = min(size.x, size.y) * 0.5 - 30.0
	var seg := TAU / n

	# Filled slices.
	for i in range(n):
		var a0 := rotation_angle + i * seg
		var a1 := a0 + seg
		_draw_slice(center, radius, a0, a1, segments[i]["color"])

	# Slice dividers + outer rim.
	for i in range(n):
		var a := rotation_angle + i * seg
		draw_line(center, center + Vector2(cos(a), sin(a)) * radius, RIM_COLOR, 2.0, true)
	draw_arc(center, radius, 0.0, TAU, 96, RIM_COLOR, 6.0, true)

	# Labels.
	for i in range(n):
		var mid := rotation_angle + (i + 0.5) * seg
		_draw_label(center, radius, mid, str(segments[i]["title"]))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Hub.
	draw_circle(center, 20.0, RIM_COLOR)
	draw_circle(center, 13.0, CREAM)

	# Fixed pointer at the very top, pointing down into the wheel.
	_draw_needle(center, radius)

func _draw_slice(center: Vector2, radius: float, a0: float, a1: float, color: Color) -> void:
	var pts := PackedVector2Array()
	pts.append(center)
	var steps := 28
	for s in range(steps + 1):
		var t : float = a0 + (a1 - a0) * float(s) / float(steps)
		pts.append(center + Vector2(cos(t), sin(t)) * radius)
	draw_colored_polygon(pts, color)

func _draw_label(center: Vector2, radius: float, angle: float, text: String) -> void:
	if label_font == null:
		return
	var fs := 13
	var inner := radius * 0.18
	var outer := radius * 0.96
	var band := outer - inner
	# Flip labels on the left half so they never appear upside down.
	var flip := cos(angle) < 0.0
	var rot := angle + (PI if flip else 0.0)
	draw_set_transform(center, rot, Vector2.ONE)
	var x : float = -outer if flip else inner
	var lines := _wrap_label(text, band, fs)
	var line_h := label_font.get_height(fs) * 1.1
	var total_h := line_h * lines.size()
	var y := label_font.get_ascent(fs) - total_h * 0.5
	for line in lines:
		draw_string_outline(label_font, Vector2(x, y), line, HORIZONTAL_ALIGNMENT_CENTER, band, fs, 4, CREAM)
		draw_string(label_font, Vector2(x, y), line, HORIZONTAL_ALIGNMENT_CENTER, band, fs, TEXT_COLOR)
		y += line_h

func _wrap_label(text: String, max_width: float, fs: int) -> Array:
	var words := text.split(" ")
	var lines: Array = []
	var current := ""
	for word in words:
		var candidate := word if current.is_empty() else current + " " + word
		if label_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= max_width:
			current = candidate
		else:
			if not current.is_empty():
				lines.append(current)
			current = word
	if not current.is_empty():
		lines.append(current)
	return lines

func _draw_needle(center: Vector2, radius: float) -> void:
	var tip := Vector2(center.x, center.y - radius + 16.0)
	var base_y := center.y - radius - 22.0
	var half := 17.0
	var p1 := Vector2(center.x - half, base_y)
	var p2 := Vector2(center.x + half, base_y)
	draw_colored_polygon(PackedVector2Array([p1, p2, tip]), NEEDLE_COLOR)
	draw_polyline(PackedVector2Array([p1, p2, tip, p1]), RIM_COLOR, 3.0, true)
