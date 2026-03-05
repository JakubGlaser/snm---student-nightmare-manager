extends Node2D

@onready var main_scene = get_parent().get_parent() # QuestionManager -> UI -> MainScene
@onready var students_node = main_scene.get_node("Characters/Students")

@onready var left_button = $GroupLeftButton
@onready var center_button = $GroupCenterButton
@onready var right_button = $GroupRightButton
@onready var instruction_label = $InstructionLabel

var is_selecting: bool = false
var is_qte_active: bool = false

var active_group_students: Array = []
var current_qte_student: Sprite2D = null
var current_qte_letter: String = ""
var qte_timer: float = 0.0
var max_qte_time: float = 2.0

func _ready():
	left_button.visible = false
	center_button.visible = false
	right_button.visible = false
	instruction_label.visible = false
	
	left_button.pressed.connect(_on_group_selected.bind("left"))
	center_button.pressed.connect(_on_group_selected.bind("center"))
	right_button.pressed.connect(_on_group_selected.bind("right"))

func start_question():
	if is_selecting or is_qte_active:
		return
		
	# Pause ALL student decay
	for student in students_node.get_children():
		if student.has_method("set_decay_paused"):
			student.set_decay_paused(true)
			
	is_selecting = true
	left_button.visible = true
	center_button.visible = true
	right_button.visible = true
	instruction_label.text = "Select a group to ask a question!"
	instruction_label.visible = true

func _on_group_selected(group_name: String):
	if not is_selecting: return
	
	is_selecting = false
	left_button.visible = false
	center_button.visible = false
	right_button.visible = false
	
	active_group_students.clear()
	
	# Mapping based on typical layout indices (1-10)
	var indices = []
	if group_name == "left":
		indices = [0, 3, 6, 7] # Student 1, 4, 7, 8
	elif group_name == "center":
		indices = [1, 4, 9] # Student 2, 5, 10
	elif group_name == "right":
		indices = [2, 5, 8] # Student 3, 6, 9
		
	var all_students = students_node.get_children()
	for idx in indices:
		if idx < all_students.size():
			var s = all_students[idx]
			if s.is_active:
				active_group_students.append(s)
				if s.has_method("add_bonus_focus"):
					s.add_bonus_focus(30.0)
					
	if active_group_students.is_empty():
		end_question()
		return
		
	instruction_label.visible = false
	start_qte_loop()

func start_qte_loop():
	is_qte_active = true
	spawn_next_qte()

func spawn_next_qte():
	if not is_qte_active: return
	
	# Only keep alive students
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
	
	# Pick random uppercase letter A-Z
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	current_qte_letter = chars[rng.randi() % chars.length()]
	
	if current_qte_student.has_method("set_qte_letter"):
		current_qte_student.set_qte_letter(current_qte_letter)
		
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
		# Only process A-Z keys to avoid failing on modifier keys
		if pressed_char >= 'A' and pressed_char <= 'Z':
			if pressed_char == current_qte_letter:
				success_qte()
			else:
				fail_qte()
			get_viewport().set_input_as_handled()

func success_qte():
	if current_qte_student and current_qte_student.has_method("clear_qte"):
		current_qte_student.clear_qte()
	current_qte_student = null
	
	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(spawn_next_qte)

func fail_qte():
	if current_qte_student and current_qte_student.has_method("clear_qte"):
		current_qte_student.clear_qte()
	current_qte_student = null
	end_question()

func end_question():
	is_qte_active = false
	is_selecting = false
	instruction_label.visible = false
	
	var all_students = students_node.get_children()
	for student in all_students:
		if student.has_method("set_decay_paused"):
			student.set_decay_paused(false)
			
	active_group_students.clear()
