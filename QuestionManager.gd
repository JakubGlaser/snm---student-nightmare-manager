extends Node2D

const PROJECT_FONT := preload("res://assets/fonts/Nunito-Regular.ttf")

@onready var main_scene = get_parent().get_parent() # QuestionManager -> UI -> MainScene
@onready var students_node = main_scene.get_node("Characters/Students")

@onready var left_button = $GroupLeftButton
@onready var center_button = $GroupCenterButton
@onready var right_button = $GroupRightButton
@onready var instruction_label = get_node_or_null("InstructionLabel")

var is_selecting: bool = false
var is_qte_active: bool = false

var active_group_students: Array = []
var current_qte_student: Node2D = null
var current_qte_letter: String = ""
var qte_timer: float = 0.0
var max_qte_time: float = 2.0

var qte_center_label: Label

func _ready():
	left_button.visible = false
	center_button.visible = false
	right_button.visible = false
	if instruction_label: instruction_label.visible = false

	left_button.pressed.connect(_on_group_selected.bind("left"))
	center_button.pressed.connect(_on_group_selected.bind("center"))
	right_button.pressed.connect(_on_group_selected.bind("right"))

	# Scene-driven node — drag it in the editor to position it manually.
	# If it gets removed from the scene, fall back to a runtime-built label.
	qte_center_label = get_node_or_null("QteCenterLabel")
	if qte_center_label == null:
		qte_center_label = _build_fallback_center_label()
	qte_center_label.visible = false

func _build_fallback_center_label() -> Label:
	var lbl := Label.new()
	var bold_font := FontVariation.new()
	bold_font.base_font = PROJECT_FONT
	bold_font.variation_embolden = 0.6
	lbl.add_theme_font_override("font", bold_font)
	lbl.add_theme_font_size_override("font_size", 220)
	lbl.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	lbl.add_theme_color_override("font_outline_color", Color(1, 0.94, 0.78, 1))
	lbl.add_theme_constant_override("outline_size", 22)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.z_index = 150
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.size = Vector2(440, 340)
	lbl.position = Vector2(-220, -170)
	add_child(lbl)
	return lbl

func _show_qte_letter(letter: String) -> void:
	qte_center_label.text = letter
	qte_center_label.visible = true

func _hide_qte_letter() -> void:
	qte_center_label.visible = false

func start_question():
	if is_selecting or is_qte_active:
		return

	# Tighten the reaction window as difficulty climbs (2.2s at L1 -> 0.85s at L10+).
	var diff = main_scene.get_difficulty01() if main_scene.has_method("get_difficulty01") else 0.0
	max_qte_time = lerp(2.2, 0.85, diff)

	# Pause ALL student decay
	for student in students_node.get_children():
		if student.has_method("set_decay_paused"):
			student.set_decay_paused(true)

	is_selecting = true
	left_button.visible = true
	center_button.visible = true
	right_button.visible = true
	if instruction_label:
		instruction_label.text = "Select a group to ask a question!"
		instruction_label.visible = true

func _on_group_selected(group_name: String):
	if not is_selecting: return

	is_selecting = false
	left_button.visible = false
	center_button.visible = false
	right_button.visible = false
	if instruction_label: instruction_label.visible = false

	active_group_students.clear()

	# 9 columns arranged as 3 groups of 3 (left -> center -> right)
	var indices = []
	if group_name == "left":
		indices = [0, 1, 2]
	elif group_name == "center":
		indices = [3, 4, 5]
	elif group_name == "right":
		indices = [6, 7, 8]

	var all_students = students_node.get_children()
	for idx in indices:
		if idx < all_students.size():
			var s = all_students[idx]
			if s.is_active:
				active_group_students.append(s)
				if s.has_method("add_bonus_focus"):
					var diff = main_scene.get_difficulty01() if main_scene.has_method("get_difficulty01") else 0.0
					var bonus = lerp(30.0, 42.0, diff) * main_scene.action_multiplier
					s.add_bonus_focus(bonus)

	if active_group_students.is_empty():
		end_question()
		return

	if instruction_label: instruction_label.visible = false
	start_qte_loop()

func start_qte_loop():
	is_qte_active = true
	spawn_next_qte()

func spawn_next_qte():
	if not is_qte_active: return

	var alive_group = []
	for s in active_group_students:
		if s.is_active:
			alive_group.append(s)

	if alive_group.is_empty():
		end_question()
		return

	var rng = RandomNumberGenerator.new()
	rng.randomize()
	current_qte_student = alive_group[rng.randi() % alive_group.size()]

	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	current_qte_letter = chars[rng.randi() % chars.length()]

	_show_qte_letter(current_qte_letter)

	qte_timer = max_qte_time

func _process(delta: float):
	if is_qte_active and qte_timer > 0:
		qte_timer -= delta
		if qte_timer <= 0:
			fail_qte()

func _input(event: InputEvent):
	if not is_qte_active: return

	if event is InputEventKey and event.pressed and not event.echo:
		var pressed_char = char(event.unicode).to_upper()
		if pressed_char >= 'A' and pressed_char <= 'Z':
			if pressed_char == current_qte_letter:
				success_qte()
			else:
				fail_qte()
			get_viewport().set_input_as_handled()

func success_qte():
	_hide_qte_letter()
	current_qte_student = null

	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(spawn_next_qte)

func fail_qte():
	_hide_qte_letter()
	current_qte_student = null
	end_question()

func end_question():
	is_qte_active = false
	is_selecting = false
	if instruction_label: instruction_label.visible = false
	_hide_qte_letter()

	var all_students = students_node.get_children()
	for student in all_students:
		if student.has_method("set_decay_paused"):
			student.set_decay_paused(false)

	active_group_students.clear()

	# Start the question cooldown now that the round is over.
	if main_scene.has_method("on_question_completed"):
		main_scene.on_question_completed()
