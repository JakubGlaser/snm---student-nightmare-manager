@tool
extends Node2D

const PROJECT_FONT := preload("res://assets/fonts/Nunito-Regular.ttf")
const WASTED_STICKER := preload("res://sprites/Wasted.png")

const COLOR_CREAM := Color(1.0, 0.94, 0.78, 1.0)
const COLOR_DARK := Color(0.15, 0.065, 0.015, 1.0)
const COLOR_TRACK := Color(0.18, 0.13, 0.09, 0.94)

@export var bar_width: float = 50.0:
	set(value):
		bar_width = value
		_apply_child_layout()
		_update_wasted_sticker_transform()
		queue_redraw()

@export var bar_height: float = 220.0:
	set(value):
		bar_height = value
		_apply_child_layout()
		_update_wasted_sticker_transform()
		queue_redraw()

@export_range(0.0, 100.0, 1.0) var editor_preview_focus: float = 70.0:
	set(value):
		editor_preview_focus = value
		if Engine.is_editor_hint():
			focus = value
			queue_redraw()
			_update_label()

@export_group("Wasted Sticker")
# Offset from the centre of the bar (positive Y is down, positive X is right).
@export var wasted_sticker_offset: Vector2 = Vector2.ZERO:
	set(value):
		wasted_sticker_offset = value
		_update_wasted_sticker_transform()
# Direct scale multiplier applied to the sticker texture.
@export_range(0.05, 3.0, 0.01) var wasted_sticker_scale: float = 0.44:
	set(value):
		wasted_sticker_scale = value
		_update_wasted_sticker_transform()
# Random tilt range applied once when the sticker first appears (±degrees).
@export_range(0.0, 180.0, 1.0) var wasted_sticker_rotation_jitter_deg: float = 30.0
# Toggle to preview the sticker in the editor — does nothing at runtime.
@export var editor_preview_wasted: bool = false:
	set(value):
		editor_preview_wasted = value
		if Engine.is_editor_hint():
			if value:
				_show_wasted_sticker()
			else:
				_hide_wasted_sticker()

var focus: float = 0.0
var focus_decay_rate: float = 1.0

var is_active: bool = true
var bonus_focus: float = 0.0
var decay_paused: bool = false
# Extra decay (focus/sec) inflicted when a classmate in the same group (the same
# question zone) has lost focus. Set by MainScene; persists across levels (dead
# groupmates stay dead).
var row_decay_penalty: float = 0.0

signal student_died

var focus_label: Label
var wasted_sticker: Sprite2D = null
var _syncing_from_node: bool = false

func _ready() -> void:
	# Reconnect to a WastedSticker node that was previously saved as part of the scene.
	if wasted_sticker == null or not is_instance_valid(wasted_sticker):
		var existing: Node = find_child("WastedSticker", false, false)
		if existing is Sprite2D:
			wasted_sticker = existing as Sprite2D
			if not (Engine.is_editor_hint() and editor_preview_wasted):
				wasted_sticker.hide()

	focus_label = Label.new()
	focus_label.add_theme_font_override("font", PROJECT_FONT)
	focus_label.add_theme_font_size_override("font_size", 20)
	focus_label.add_theme_color_override("font_color", Color.WHITE)
	focus_label.add_theme_color_override("font_outline_color", COLOR_DARK)
	focus_label.add_theme_constant_override("outline_size", 5)
	focus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	focus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	focus_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(focus_label)
	_apply_child_layout()

	if Engine.is_editor_hint():
		focus = editor_preview_focus
	else:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		focus = rng.randf_range(50.0, 79.0)
	queue_redraw()
	_update_label()

func _apply_child_layout() -> void:
	if focus_label:
		focus_label.size = Vector2(bar_width + 24, 28)
		# Percentage label sits ABOVE the bar
		focus_label.position = Vector2(-12, -32)

func reset_for_new_level(new_decay_rate: float) -> void:
	if not is_active: return
	focus_decay_rate = new_decay_rate
	bonus_focus = 0.0
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	focus = rng.randf_range(50.0, 79.0)
	queue_redraw()
	_update_label()

func add_bonus_focus(amount: float) -> void:
	if not is_active: return
	bonus_focus += amount
	focus += amount
	if focus > 100.0:
		focus = 100.0
	queue_redraw()
	_update_label()

func set_decay_paused(paused: bool) -> void:
	decay_paused = paused

func set_row_decay_penalty(value: float) -> void:
	row_decay_penalty = value

func set_focus_override(value: float) -> void:
	if not is_active: return
	focus = value
	queue_redraw()
	_update_label()

func modify_focus(amount: float) -> void:
	if not is_active:
		return
	focus += amount
	if focus > 100.0:
		focus = 100.0
	elif focus <= 0.0:
		focus = 0.0
		is_active = false
		_show_wasted_sticker()
		student_died.emit()
	queue_redraw()
	_update_label()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		# Sync position/scale changes the user made by dragging back into export vars.
		if editor_preview_wasted and wasted_sticker != null and is_instance_valid(wasted_sticker):
			var center := Vector2(bar_width / 2.0, bar_height / 2.0)
			var node_offset := wasted_sticker.position - center
			var node_scale := wasted_sticker.scale.x
			if node_offset.distance_to(wasted_sticker_offset) > 0.5 or absf(node_scale - wasted_sticker_scale) > 0.001:
				_syncing_from_node = true
				wasted_sticker_offset = node_offset
				wasted_sticker_scale = node_scale
				_syncing_from_node = false
		return
	if not is_active or decay_paused:
		return
	var effective_decay_rate = focus_decay_rate + row_decay_penalty
	if bonus_focus > 0:
		var decay = effective_decay_rate * 2.0 * delta
		bonus_focus -= decay
		focus -= decay
		if bonus_focus < 0:
			bonus_focus = 0.0
	else:
		focus -= effective_decay_rate * delta

	if focus <= 0.0:
		focus = 0.0
		is_active = false
		_show_wasted_sticker()
		student_died.emit()

	queue_redraw()
	_update_label()

func _update_label() -> void:
	if focus_label == null:
		return
	focus_label.text = str(int(focus)) + "%"

func _show_wasted_sticker() -> void:
	if not is_inside_tree():
		return

	# Reuse an existing node (saved in scene or previously hidden by editor preview toggle).
	if wasted_sticker == null or not is_instance_valid(wasted_sticker):
		var existing: Node = find_child("WastedSticker", false, false)
		if existing is Sprite2D:
			wasted_sticker = existing as Sprite2D

	if wasted_sticker != null and is_instance_valid(wasted_sticker):
		if not Engine.is_editor_hint():
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			var jitter := deg_to_rad(wasted_sticker_rotation_jitter_deg)
			wasted_sticker.rotation = rng.randf_range(-jitter, jitter) if jitter > 0.0 else 0.0
		wasted_sticker.show()
		return

	# Create a new sticker node.
	wasted_sticker = Sprite2D.new()
	wasted_sticker.texture = WASTED_STICKER
	wasted_sticker.centered = true
	wasted_sticker.z_index = 10
	wasted_sticker.name = "WastedSticker"
	add_child(wasted_sticker)
	# Give it an owner so it appears in the Scene dock and is selectable in the 2D editor.
	if Engine.is_editor_hint():
		wasted_sticker.owner = get_tree().edited_scene_root
		wasted_sticker.rotation = 0.0
	else:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var jitter := deg_to_rad(wasted_sticker_rotation_jitter_deg)
		wasted_sticker.rotation = rng.randf_range(-jitter, jitter) if jitter > 0.0 else 0.0
	_update_wasted_sticker_transform()

func _hide_wasted_sticker() -> void:
	# Hide rather than free — keeps the node in the scene so the user's edits persist.
	if wasted_sticker != null and is_instance_valid(wasted_sticker):
		wasted_sticker.hide()

func _update_wasted_sticker_transform() -> void:
	if _syncing_from_node:
		return
	if wasted_sticker == null or not is_instance_valid(wasted_sticker):
		return
	wasted_sticker.position = Vector2(bar_width / 2.0, bar_height / 2.0) + wasted_sticker_offset
	wasted_sticker.scale = Vector2(wasted_sticker_scale, wasted_sticker_scale)

func _get_focus_color() -> Color:
	if focus >= 80.0:
		return Color(0.25, 0.55, 0.20)
	elif focus >= 50.0:
		return Color(0.45, 0.75, 0.30)
	elif focus >= 30.0:
		return Color(0.95, 0.78, 0.22)
	elif focus > 0.0:
		return Color(0.85, 0.32, 0.22)
	return Color(0.20, 0.12, 0.08)

func _make_round_box(bg: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left = radius
	return sb

func _make_frame_box(color: Color, radius: int, width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_right = radius
	sb.corner_radius_bottom_left = radius
	sb.border_color = color
	sb.border_width_left = width
	sb.border_width_top = width
	sb.border_width_right = width
	sb.border_width_bottom = width
	return sb

func _draw() -> void:
	var rect := Rect2(0, 0, bar_width, bar_height)

	# Drop shadow
	draw_style_box(_make_round_box(Color(0, 0, 0, 0.40), 10),
		Rect2(rect.position + Vector2(3, 5), rect.size))

	# Track
	draw_style_box(_make_round_box(COLOR_TRACK, 10), rect)

	# Fill from bottom proportional to focus
	var pct := clampf(focus / 100.0, 0.0, 1.0)
	var fill_h := bar_height * pct
	if fill_h > 0.0:
		var fill_rect := Rect2(Vector2(2, bar_height - fill_h), Vector2(bar_width - 4, fill_h - 2))
		var col := _get_focus_color()
		draw_style_box(_make_round_box(col, 8), fill_rect)
		if fill_h > 16.0:
			var top_h := minf(fill_h * 0.35, 28.0)
			var top_rect := Rect2(fill_rect.position, Vector2(fill_rect.size.x, top_h))
			var hi := col.lerp(Color(1, 1, 1, 1), 0.18)
			hi.a = 1.0
			draw_style_box(_make_round_box(hi, 8), top_rect)
		var stripe_h := minf(fill_h * 0.12, 4.0)
		if stripe_h >= 1.0:
			draw_rect(Rect2(fill_rect.position + Vector2(4, 2),
				Vector2(fill_rect.size.x - 8, stripe_h)), Color(1, 1, 1, 0.28), true)

	# Frame
	draw_style_box(_make_frame_box(COLOR_CREAM, 10, 3), rect)
	draw_style_box(_make_frame_box(COLOR_DARK, 8, 1),
		Rect2(rect.position + Vector2(2, 2), rect.size - Vector2(4, 4)))
