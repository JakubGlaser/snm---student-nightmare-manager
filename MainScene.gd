extends Node2D

const SOUND_ON_ICON := preload("res://sprites/Sound On Icon.png")
const SOUND_OFF_ICON := preload("res://sprites/Sound Off Icon.png")
const MUSIC_ON_ICON := preload("res://sprites/Music On Icon.png")
const MUSIC_OFF_ICON := preload("res://sprites/Music Off Icon.png")

@export var level_duration: float = 120.0 # 2 minutes in seconds
var current_time: float = 0.0

@onready var progress_bar: ProgressBar = $UI/ProgressPanel/ProgressBar
@onready var stamina_value_label: Label = $UI/StaminaPanel/Value
@onready var menu_button: TextureButton = $UI/StaminaPanel
@onready var menu_input_blocker: ColorRect = $MenuLayer/MenuInputBlocker
@onready var menu_panel: Panel = $MenuLayer/MenuPanel
@onready var menu_continue_button: TextureButton = $MenuLayer/MenuPanel/OptionsContainer/ContinueButton
@onready var menu_new_game_button: TextureButton = $MenuLayer/MenuPanel/OptionsContainer/NewGameButton
@onready var menu_tutorial_button: TextureButton = $MenuLayer/MenuPanel/OptionsContainer/TutorialButton
@onready var menu_credits_button: TextureButton = $MenuLayer/MenuPanel/OptionsContainer/CreditsButton
@onready var menu_main_menu_button: TextureButton = $MenuLayer/MenuPanel/OptionsContainer/MainMenuButton
@onready var sound_toggle_button: TextureButton = $MenuLayer/MenuPanel/AudioToggles/SoundToggleButton
@onready var music_toggle_button: TextureButton = $MenuLayer/MenuPanel/AudioToggles/MusicToggleButton
@onready var sound_toggle_icon: TextureRect = $MenuLayer/MenuPanel/AudioToggles/SoundToggleButton/SoundToggleIcon
@onready var music_toggle_icon: TextureRect = $MenuLayer/MenuPanel/AudioToggles/MusicToggleButton/MusicToggleIcon
@onready var students_node = $Characters/Students
@onready var joke_minigame_panel = $UI/JokeMinigamePanel
@onready var joke_button = $UI/BottomButtons/JokeButton
@onready var question_manager = $UI/QuestionManager
@onready var question_button = $UI/BottomButtons/QuestionButton
@onready var funfact_minigame_panel = $UI/FunFactMinigamePanel
@onready var funfact_button = $UI/BottomButtons/FunFactButton
@onready var special_wheel_panel = $UI/SpecialWheelPanel
@onready var special_button = $UI/BottomButtons/SpecialButton

@onready var lvl_label: Label = $UI/ProgressPanel/LvlLabel

var total_students: int = 0
var alive_students: int = 0
var current_level: int = 1
var displayed_progress_time: float = 0.0
var sound_enabled: bool = true
var music_enabled: bool = true
var was_paused_before_menu: bool = false
var bottom_button_disabled_states: Dictionary = {}

var joke_cooldown_label: Label
var joke_cooldown: float = 30.0
var current_joke_cooldown: float = 0.0

var funfact_cooldown_label: Label
var funfact_cooldown: float = 45.0
var current_funfact_cooldown: float = 0.0

# Special wheel state
var special_used_this_level: bool = false
var josef_active: bool = false
var cenek_active: bool = false
var dj_next_level_bonus: bool = false
var action_multiplier: float = 1.0

func _ready():
	menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_input_blocker.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	sound_toggle_button.process_mode = Node.PROCESS_MODE_ALWAYS
	music_toggle_button.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_button.pressed.connect(_on_menu_button_pressed)
	menu_continue_button.pressed.connect(_close_menu)
	menu_new_game_button.pressed.connect(_on_menu_new_game_pressed)
	menu_tutorial_button.pressed.connect(_on_menu_tutorial_pressed)
	menu_credits_button.pressed.connect(_on_menu_credits_pressed)
	menu_main_menu_button.pressed.connect(_on_menu_main_menu_pressed)
	sound_toggle_button.pressed.connect(_on_sound_toggle_pressed)
	music_toggle_button.pressed.connect(_on_music_toggle_pressed)
	_update_audio_toggle_icons()
	
	progress_bar.min_value = 0
	progress_bar.max_value = level_duration
	progress_bar.value = 0
	displayed_progress_time = 0.0
	
	total_students = students_node.get_child_count()
	alive_students = total_students
	
	for student in students_node.get_children():
		if student.has_signal("student_died"):
			student.student_died.connect(_on_student_died)
			
	joke_button.pressed.connect(_on_joke_button_pressed)
	joke_minigame_panel.joke_finished.connect(_on_joke_minigame_finished)
	
	question_button.pressed.connect(_on_question_button_pressed)
	
	funfact_button.pressed.connect(_on_funfact_button_pressed)
	funfact_minigame_panel.funfact_finished.connect(_on_funfact_minigame_finished)
	
	special_button.pressed.connect(_on_special_button_pressed)
	special_wheel_panel.wheel_finished.connect(_on_wheel_finished)
	
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
	
	funfact_cooldown_label = Label.new()
	funfact_cooldown_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	funfact_cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	funfact_cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	funfact_cooldown_label.set("theme_override_font_sizes/font_size", 40)
	funfact_cooldown_label.set("theme_override_colors/font_color", Color.WHITE)
	funfact_cooldown_label.set("theme_override_colors/font_outline_color", Color.BLACK)
	funfact_cooldown_label.set("theme_override_constants/outline_size", 10)
	funfact_cooldown_label.text = ""
	funfact_button.add_child(funfact_cooldown_label)
		
	update_stamina_label()
	start_new_level()

func _process(delta: float):
	if current_time < level_duration:
		current_time += delta
		displayed_progress_time = lerp(displayed_progress_time, current_time, min(delta * 8.0, 1.0))
		progress_bar.value = displayed_progress_time
		
		if current_time >= level_duration:
			progress_bar.value = level_duration
			level_complete()
			
	if current_joke_cooldown > 0:
		current_joke_cooldown -= delta
		joke_cooldown_label.text = str(int(ceil(current_joke_cooldown)))
		if current_joke_cooldown <= 0:
			current_joke_cooldown = 0
			joke_button.disabled = false
			joke_button.modulate = Color(1, 1, 1)
			joke_cooldown_label.text = ""
	
	if current_funfact_cooldown > 0:
		current_funfact_cooldown -= delta
		funfact_cooldown_label.text = str(int(ceil(current_funfact_cooldown)))
		if current_funfact_cooldown <= 0:
			current_funfact_cooldown = 0
			funfact_button.disabled = false
			funfact_button.modulate = Color(1, 1, 1)
			funfact_cooldown_label.text = ""

func _is_any_minigame_open() -> bool:
	return menu_panel.visible or joke_minigame_panel.visible or funfact_minigame_panel.visible or special_wheel_panel.visible or question_manager.is_selecting or question_manager.is_qte_active

func _on_menu_button_pressed():
	if menu_panel.visible:
		_close_menu()
	else:
		was_paused_before_menu = get_tree().paused
		menu_input_blocker.visible = true
		menu_panel.visible = true
		_set_gameplay_buttons_blocked(true)
		get_tree().paused = true

func _close_menu():
	menu_panel.visible = false
	menu_input_blocker.visible = false
	_set_gameplay_buttons_blocked(false)
	get_tree().paused = was_paused_before_menu

func _on_menu_new_game_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_tutorial_pressed():
	print("Tutorial menu option selected. Tutorial screen can be connected here later.")

func _on_menu_credits_pressed():
	print("Credits menu option selected. Credits screen can be connected here later.")

func _on_menu_main_menu_pressed():
	menu_panel.visible = false
	menu_input_blocker.visible = false
	_set_gameplay_buttons_blocked(false)
	get_tree().paused = false
	print("Main Menu option selected. Main menu scene can be connected here later.")

func _set_gameplay_buttons_blocked(blocked: bool):
	var buttons = [joke_button, funfact_button, question_button, special_button]
	if blocked:
		bottom_button_disabled_states.clear()
		for button in buttons:
			bottom_button_disabled_states[button] = button.disabled
			button.disabled = true
	else:
		for button in buttons:
			if bottom_button_disabled_states.has(button):
				button.disabled = bottom_button_disabled_states[button]
		bottom_button_disabled_states.clear()

func _on_sound_toggle_pressed():
	sound_enabled = not sound_enabled
	_set_audio_bus_mute("SFX", not sound_enabled)
	_update_audio_toggle_icons()
	print("Sound ", "ON" if sound_enabled else "OFF")

func _on_music_toggle_pressed():
	music_enabled = not music_enabled
	_set_audio_bus_mute("Music", not music_enabled)
	_update_audio_toggle_icons()
	print("Music ", "ON" if music_enabled else "OFF")

func _update_audio_toggle_icons():
	sound_toggle_icon.texture = SOUND_ON_ICON if sound_enabled else SOUND_OFF_ICON
	music_toggle_icon.texture = MUSIC_ON_ICON if music_enabled else MUSIC_OFF_ICON

func _set_audio_bus_mute(bus_name: String, muted: bool):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		print(bus_name, " audio bus is not set up yet.")
		return
	AudioServer.set_bus_mute(bus_index, muted)

func start_new_level():
	lvl_label.text = "lvl " + str(current_level)
	
	# Reset special wheel state for the new level
	special_used_this_level = false
	special_button.disabled = false
	special_button.modulate = Color(1, 1, 1)
	
	# Clear level-duration effects from previous level
	if cenek_active:
		cenek_active = false
		Engine.time_scale = 1.0
		for student in students_node.get_children():
			if student.has_method("set_decay_paused"):
				student.set_decay_paused(false)
	
	if josef_active:
		josef_active = false
		action_multiplier = 1.0
	
	# Base is 1.0 (Level 1). Maxes at 6.5 (Level 12).
	# Math: 1.0 + (level - 1) * 0.5
	var clamped_level = min(current_level, 12)
	var new_decay_rate = 1.0 + ((clamped_level - 1) * 0.5)
	
	for student in students_node.get_children():
		if student.has_method("reset_for_new_level"):
			student.reset_for_new_level(new_decay_rate)
	
	# Apply DJ's next-level bonus: everyone starts at 120%
	if dj_next_level_bonus:
		dj_next_level_bonus = false
		for student in students_node.get_children():
			if student.has_method("set_focus_override"):
				student.set_focus_override(120.0)

func level_complete():
	# Clean up time-scale before transitioning
	if cenek_active:
		Engine.time_scale = 1.0
	
	current_level += 1
	current_time = 0.0
	displayed_progress_time = 0.0
	progress_bar.value = 0.0
	start_new_level()

func _on_joke_button_pressed():
	if _is_any_minigame_open() or current_joke_cooldown > 0: return
	joke_minigame_panel.start_minigame()

func _on_question_button_pressed():
	if _is_any_minigame_open(): return
	question_manager.start_question()

func _on_funfact_button_pressed():
	if _is_any_minigame_open() or current_funfact_cooldown > 0: return
	funfact_minigame_panel.start_minigame()

func _on_special_button_pressed():
	if _is_any_minigame_open() or special_used_this_level: return
	special_wheel_panel.start_minigame()

func _on_joke_minigame_finished(success: bool):
	current_joke_cooldown = joke_cooldown
	joke_button.disabled = true
	joke_button.modulate = Color(0.5, 0.5, 0.5) # Darken while on cooldown
	joke_cooldown_label.text = str(int(joke_cooldown))
	
	var base_effect = 20.0 if success else -10.0
	var effect = base_effect * action_multiplier if success else base_effect
	for student in students_node.get_children():
		if student.has_method("modify_focus"):
			student.modify_focus(effect)

func _on_funfact_minigame_finished(success: bool):
	current_funfact_cooldown = funfact_cooldown
	funfact_button.disabled = true
	funfact_button.modulate = Color(0.5, 0.5, 0.5)
	funfact_cooldown_label.text = str(int(funfact_cooldown))
	
	var base_effect = 15.0 if success else -10.0
	var effect = base_effect * action_multiplier if success else base_effect
	for student in students_node.get_children():
		if student.has_method("modify_focus"):
			student.modify_focus(effect)

func _on_wheel_finished(result_id: String):
	# Mark special as used for this level
	special_used_this_level = true
	special_button.disabled = true
	special_button.modulate = Color(0.5, 0.5, 0.5)
	
	match result_id:
		"sadluck_ai_slop":
			# Give everyone 120% focus instantly
			for student in students_node.get_children():
				if student.has_method("set_focus_override"):
					student.set_focus_override(120.0)
		
		"josefs_tobacco":
			# Double all action effectiveness for this level
			josef_active = true
			action_multiplier = 2.0
		
		"ceneks_endless_speech":
			# Freeze all focus decay + speed up time 4x
			cenek_active = true
			for student in students_node.get_children():
				if student.has_method("set_decay_paused"):
					student.set_decay_paused(true)
			Engine.time_scale = 4.0
		
		"djs_failed_calculation":
			# Everyone loses 20 focus now
			for student in students_node.get_children():
				if student.has_method("modify_focus"):
					student.modify_focus(-20.0)
			# But everyone gets 120% at the start of the next level
			dj_next_level_bonus = true

func _on_student_died():
	alive_students -= 1
	update_stamina_label()

func update_stamina_label():
	stamina_value_label.text = str(alive_students) + "/" + str(total_students)
