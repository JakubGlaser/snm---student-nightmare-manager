@tool
extends Node2D

@export var bar_width: float = 50.0:
	set(value):
		bar_width = value
		_apply_label_layout()
		queue_redraw()

@export var bar_height: float = 220.0:
	set(value):
		bar_height = value
		_apply_label_layout()
		queue_redraw()

# Visible in the editor so you can preview the bar fill/color without running.
@export_range(0.0, 100.0, 1.0) var editor_preview_focus: float = 70.0:
	set(value):
		editor_preview_focus = value
		if Engine.is_editor_hint():
			focus = value
			queue_redraw()
			_update_label()

var focus: float = 0.0
var focus_decay_rate: float = 1.0

var is_active: bool = true
var bonus_focus: float = 0.0
var decay_paused: bool = false
var is_qte: bool = false

signal student_died

var focus_label: Label

func _ready() -> void:
	focus_label = Label.new()
	focus_label.set("theme_override_font_sizes/font_size", 24)
	focus_label.set("theme_override_colors/font_color", Color.WHITE)
	focus_label.set("theme_override_colors/font_outline_color", Color.BLACK)
	focus_label.set("theme_override_constants/outline_size", 6)
	focus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	focus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(focus_label)
	_apply_label_layout()

	if Engine.is_editor_hint():
		focus = editor_preview_focus
	else:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		focus = rng.randf_range(50.0, 79.0)
	queue_redraw()
	_update_label()

func _apply_label_layout() -> void:
	if focus_label == null:
		return
	focus_label.position = Vector2(0, -32)
	focus_label.size = Vector2(bar_width, 28)

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

func set_qte_letter(letter: String) -> void:
	is_qte = true
	focus_label.text = letter
	focus_label.set("theme_override_colors/font_color", Color.YELLOW)

func clear_qte() -> void:
	is_qte = false
	focus_label.set("theme_override_colors/font_color", Color.WHITE)
	_update_label()

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
		student_died.emit()
	queue_redraw()
	_update_label()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not is_active or decay_paused:
		return
	if bonus_focus > 0:
		var decay = focus_decay_rate * 2.0 * delta
		bonus_focus -= decay
		focus -= decay
		if bonus_focus < 0:
			bonus_focus = 0.0
	else:
		focus -= focus_decay_rate * delta

	if focus <= 0.0:
		focus = 0.0
		is_active = false
		student_died.emit()

	queue_redraw()
	_update_label()

func _update_label() -> void:
	if focus_label == null:
		return
	if not is_qte:
		focus_label.text = str(int(focus)) + "%"

func _get_focus_color() -> Color:
	if focus >= 80.0:
		return Color(0.0, 0.4, 0.0)
	elif focus >= 50.0:
		return Color(0.0, 1.0, 0.0)
	elif focus >= 30.0:
		return Color(1.0, 1.0, 0.0)
	elif focus > 0.0:
		return Color(1.0, 0.0, 0.0)
	return Color(0.0, 0.0, 0.0)

func _draw() -> void:
	var rect := Rect2(0, 0, bar_width, bar_height)
	draw_rect(Rect2(rect.position + Vector2(2, 2), rect.size), Color(0, 0, 0, 0.35), true)
	draw_rect(rect, Color(0.12, 0.10, 0.08, 0.92), true)
	var pct := clampf(focus / 100.0, 0.0, 1.0)
	var fill_h := bar_height * pct
	if fill_h > 0.0:
		var fill_rect := Rect2(Vector2(0, bar_height - fill_h), Vector2(bar_width, fill_h))
		draw_rect(fill_rect, _get_focus_color(), true)
	draw_rect(rect, Color(1, 0.94, 0.78, 1), false, 3.0)
