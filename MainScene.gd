extends Node2D

@export var level_duration: float = 120.0 # 2 minutes in seconds
var current_time: float = 0.0

@onready var progress_bar: ProgressBar = $UI/ProgressPanel/ProgressBar
@onready var stamina_value_label: Label = $UI/StaminaPanel/Value
@onready var students_node = $Characters/Students
@onready var joke_minigame_panel = $UI/JokeMinigamePanel
@onready var joke_button = $UI/BottomButtons/JokeButton
@onready var question_manager = $UI/QuestionManager
@onready var question_button = $UI/BottomButtons/QuestionButton

@onready var lvl_label: Label = $UI/ProgressPanel/LvlLabel

var total_students: int = 0
var alive_students: int = 0
var current_level: int = 1

var joke_cooldown_label: Label
var joke_cooldown: float = 30.0
var current_joke_cooldown: float = 0.0

func _ready():
	progress_bar.min_value = 0
	progress_bar.max_value = level_duration
	progress_bar.value = 0
	
	total_students = students_node.get_child_count()
	alive_students = total_students
	
	for student in students_node.get_children():
		if student.has_signal("student_died"):
			student.student_died.connect(_on_student_died)
			
	joke_button.pressed.connect(_on_joke_button_pressed)
	joke_minigame_panel.joke_finished.connect(_on_joke_minigame_finished)
	
	question_button.pressed.connect(_on_question_button_pressed)
	
	joke_cooldown_label = Label.new()
	joke_cooldown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	joke_cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	joke_cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	joke_cooldown_label.set("theme_override_font_sizes/font_size", 40)
	joke_cooldown_label.set("theme_override_colors/font_color", Color.WHITE)
	joke_cooldown_label.set("theme_override_colors/font_outline_color", Color.BLACK)
	joke_cooldown_label.set("theme_override_constants/outline_size", 10)
	joke_cooldown_label.text = ""
	joke_button.add_child(joke_cooldown_label)
		
	update_stamina_label()
	start_new_level()

func _process(delta: float):
	if current_time < level_duration:
		current_time += delta
		progress_bar.value = current_time
		
		if current_time >= level_duration:
			level_complete()
			
	if current_joke_cooldown > 0:
		current_joke_cooldown -= delta
		joke_cooldown_label.text = str(int(ceil(current_joke_cooldown)))
		if current_joke_cooldown <= 0:
			current_joke_cooldown = 0
			joke_button.disabled = false
			joke_button.modulate = Color(1, 1, 1)
			joke_cooldown_label.text = ""

func start_new_level():
	lvl_label.text = "lvl " + str(current_level)
	
	# Base is 1.0 (Level 1). Maxes at 6.5 (Level 12).
	# Math: 1.0 + (level - 1) * 0.5
	var clamped_level = min(current_level, 12)
	var new_decay_rate = 1.0 + ((clamped_level - 1) * 0.5)
	
	for student in students_node.get_children():
		if student.has_method("reset_for_new_level"):
			student.reset_for_new_level(new_decay_rate)

func level_complete():
	current_level += 1
	current_time = 0.0
	progress_bar.value = 0.0
	start_new_level()

func _on_joke_button_pressed():
	# Currently disables button spamming
	if joke_minigame_panel.visible or current_joke_cooldown > 0 or question_manager.is_selecting or question_manager.is_qte_active: return
	joke_minigame_panel.start_minigame()

func _on_question_button_pressed():
	if joke_minigame_panel.visible or question_manager.is_selecting or question_manager.is_qte_active: return
	question_manager.start_question()

func _on_joke_minigame_finished(success: bool):
	current_joke_cooldown = joke_cooldown
	joke_button.disabled = true
	joke_button.modulate = Color(0.5, 0.5, 0.5) # Darken while on cooldown
	joke_cooldown_label.text = str(int(joke_cooldown))
	
	var effect = 20.0 if success else -10.0
	for student in students_node.get_children():
		if student.has_method("modify_focus"):
			student.modify_focus(effect)

func _on_student_died():
	alive_students -= 1
	update_stamina_label()

func update_stamina_label():
	stamina_value_label.text = str(alive_students) + "/" + str(total_students)
