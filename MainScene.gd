extends Node2D

const SOUND_ON_ICON := preload("res://sprites/Sound On Icon.png")
const SOUND_OFF_ICON := preload("res://sprites/Sound Off Icon.png")
const MUSIC_ON_ICON := preload("res://sprites/Music On Icon.png")
const MUSIC_OFF_ICON := preload("res://sprites/Music Off Icon.png")
const ITEM_SPRITE_SHEET := preload("res://sprites/Items SNM.png")
const ITEM_ATLAS_COLUMNS := 3
const ITEM_ATLAS_CELL_SIZE := Vector2(418, 418)
# Inventory slots are now scene-driven: any TextureRect named "Slot*" directly
# under InventoryPanel is picked up. Edit positions/sizes in the editor.
var max_inventory_items: int = 5
const ITEMS := [
	{
		"id": "marshall_mcluhan",
		"theme": "Marshall McLuhan",
		"catchphrase": "The Medium is the Boss Fight.",
		"artifact": "A glowing TV set with a speech bubble trapped inside the screen."
	},
	{
		"id": "lev_manovich",
		"theme": "Lev Manovich",
		"catchphrase": "Database First, Narrative Later.",
		"artifact": "A film reel wrapped around a database cylinder, like cinema being eaten by software."
	},
	{
		"id": "manuel_castells",
		"theme": "Manuel Castells",
		"catchphrase": "I Don't Have Friends, I Have Nodes.",
		"artifact": "A city skyline made of glowing network dots and lines."
	},
	{
		"id": "bolter_grusin",
		"theme": "Bolter-Grusin",
		"catchphrase": "New Media: Now Remaking Old Media Again.",
		"artifact": "A picture frame inside a screen inside a book inside another screen."
	},
	{
		"id": "friedrich_kittler",
		"theme": "Friedrich Kittler",
		"catchphrase": "Your Hardware Has Already Decided.",
		"artifact": "A typewriter fused with a circuit board and a skull-shaped cassette tape."
	},
	{
		"id": "donna_haraway",
		"theme": "Donna Haraway",
		"catchphrase": "Cyborgs Don't Do Natural.",
		"artifact": "A half-human, half-machine hand holding a tiny companion species."
	},
	{
		"id": "matthew_fuller",
		"theme": "Matthew Fuller",
		"catchphrase": "There Is No Escape from Media Ecology.",
		"artifact": "A messy ecosystem terrarium filled with cables, bugs, phones, moss, and antennas."
	},
	{
		"id": "luciano_floridi",
		"theme": "Luciano Floridi",
		"catchphrase": "Welcome to the Infosphere. Please Update Your Ethics.",
		"artifact": "A transparent globe made of data streams with a small moral compass inside."
	},
	{
		"id": "claude_shannon",
		"theme": "Claude Shannon",
		"catchphrase": "Less Noise, More Bits.",
		"artifact": "A pixelated telegraph key shooting clean binary through a storm of static."
	},
]

@export var level_duration: float = 120.0 # 2 minutes in seconds
var current_time: float = 0.0

@onready var progress_bar: ColorRect = $UI/ProgressPanel/ProgressBar
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
@onready var inventory_panel: TextureRect = $UI/InventoryPanel
@onready var ui_layer: CanvasLayer = $UI

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
var inventory_items: Array[int] = []
var inventory_icon_nodes: Array[TextureRect] = []
var hovered_inventory_slot: int = -1
var item_hover_bubble: Panel
var item_hover_label: Label
var teacher_speech_bubble: Panel
var teacher_speech_label: Label
var teacher_speech_token: int = 0

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
	
	_set_progress(0.0)
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
	_build_inventory_slots()
	_build_item_bubbles()
	
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

func _build_inventory_slots():
	inventory_icon_nodes.clear()

	# Each slot is a Panel with a child TextureRect named "Icon". The Panel
	# always shows the styled frame; the Icon shows the item texture when
	# something is held.
	var panels: Array[Panel] = []
	for child in inventory_panel.get_children():
		if child is Panel and String(child.name).begins_with("Slot"):
			panels.append(child)
	panels.sort_custom(func(a, b): return String(a.name).naturalnocasecmp_to(String(b.name)) < 0)
	max_inventory_items = panels.size()

	for i in range(panels.size()):
		var slot: Panel = panels[i]
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.mouse_entered.connect(_on_inventory_item_mouse_entered.bind(i))
		slot.mouse_exited.connect(_on_inventory_item_mouse_exited.bind(i))
		slot.gui_input.connect(_on_inventory_item_gui_input.bind(i))

		var icon: TextureRect = slot.get_node("Icon") as TextureRect
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.pivot_offset = icon.size * 0.5
		inventory_icon_nodes.append(icon)

func _set_progress(p: float) -> void:
	if progress_bar and progress_bar.material:
		progress_bar.material.set_shader_parameter("progress", clampf(p, 0.0, 1.0))

func _build_item_bubbles():
	item_hover_bubble = _create_text_bubble(Vector2(650, 190), Vector2(245, 82), 15)
	item_hover_bubble.visible = false
	ui_layer.add_child(item_hover_bubble)
	item_hover_label = item_hover_bubble.get_node("Text") as Label
	
	teacher_speech_bubble = _create_text_bubble(Vector2(365, 100), Vector2(390, 92), 20)
	teacher_speech_bubble.visible = false
	ui_layer.add_child(teacher_speech_bubble)
	teacher_speech_label = teacher_speech_bubble.get_node("Text") as Label

func _create_text_bubble(pos: Vector2, bubble_size: Vector2, font_size: int) -> Panel:
	var bubble := Panel.new()
	bubble.position = pos
	bubble.size = bubble_size
	bubble.z_index = 120
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 0.94, 0.78, 0.96)
	style.border_color = Color(0.15, 0.065, 0.015, 1)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	bubble.add_theme_stylebox_override("panel", style)
	
	var label := Label.new()
	label.name = "Text"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 12
	label.offset_top = 10
	label.offset_right = -12
	label.offset_bottom = -10
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.11, 0.055, 0.02, 1))
	label.add_theme_font_size_override("font_size", font_size)
	bubble.add_child(label)
	
	return bubble

func _add_random_item_to_inventory():
	if inventory_items.size() >= max_inventory_items:
		return
	
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var item_index := rng.randi() % ITEMS.size()
	inventory_items.append(item_index)
	_update_inventory_ui()

func _update_inventory_ui():
	for i in range(inventory_icon_nodes.size()):
		var icon := inventory_icon_nodes[i]
		icon.scale = Vector2.ONE
		icon.modulate = Color.WHITE
		if i < inventory_items.size():
			var item_index := inventory_items[i]
			var item: Dictionary = ITEMS[item_index]
			icon.texture = _create_item_texture(item_index)
			icon.tooltip_text = ""
			icon.visible = true
		else:
			icon.texture = null
			icon.tooltip_text = ""
			icon.visible = false
	
	if hovered_inventory_slot >= inventory_items.size():
		hovered_inventory_slot = -1
		item_hover_bubble.visible = false

func _create_item_texture(item_index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = ITEM_SPRITE_SHEET
	var column := item_index % ITEM_ATLAS_COLUMNS
	var row := floori(float(item_index) / ITEM_ATLAS_COLUMNS)
	atlas.region = Rect2(
		Vector2(column, row) * ITEM_ATLAS_CELL_SIZE,
		ITEM_ATLAS_CELL_SIZE
	)
	return atlas

func _on_inventory_item_mouse_entered(slot_index: int):
	if slot_index >= inventory_items.size():
		return
	
	hovered_inventory_slot = slot_index
	var icon := inventory_icon_nodes[slot_index]
	icon.scale = Vector2(1.18, 1.18)
	icon.modulate = Color(1.25, 1.25, 1.25, 1)
	
	var item: Dictionary = ITEMS[inventory_items[slot_index]]
	item_hover_label.text = item["theme"] + "\n\"" + item["catchphrase"] + "\""
	item_hover_bubble.visible = true

func _on_inventory_item_mouse_exited(slot_index: int):
	if slot_index < inventory_icon_nodes.size():
		inventory_icon_nodes[slot_index].scale = Vector2.ONE
		inventory_icon_nodes[slot_index].modulate = Color.WHITE
	
	if hovered_inventory_slot == slot_index:
		hovered_inventory_slot = -1
		item_hover_bubble.visible = false

func _on_inventory_item_gui_input(event: InputEvent, slot_index: int):
	if slot_index >= inventory_items.size() or _is_any_minigame_open():
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var item: Dictionary = ITEMS[inventory_items[slot_index]]
		inventory_items.remove_at(slot_index)
		hovered_inventory_slot = -1
		item_hover_bubble.visible = false
		_update_inventory_ui()
		_show_teacher_speech(str(item["catchphrase"]))
		get_viewport().set_input_as_handled()

func _show_teacher_speech(text: String):
	teacher_speech_token += 1
	var current_token := teacher_speech_token
	teacher_speech_label.text = "\"" + text + "\""
	teacher_speech_bubble.visible = true
	
	var timer := get_tree().create_timer(4.0)
	timer.timeout.connect(func():
		if current_token == teacher_speech_token:
			teacher_speech_bubble.visible = false
	)

func _process(delta: float):
	if current_time < level_duration:
		current_time += delta
		displayed_progress_time = lerp(displayed_progress_time, current_time, min(delta * 8.0, 1.0))
		_set_progress(displayed_progress_time / level_duration)

		if current_time >= level_duration:
			_set_progress(1.0)
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
	# The MENU button now hands off to the separate MainMenu scene managed by
	# the GameManager autoload. The legacy in-scene MenuPanel is no longer used.
	if Engine.has_singleton("Game") or get_node_or_null("/root/Game"):
		Game.return_to_menu_from_game()
	else:
		# Fallback for running this scene standalone in the editor.
		get_tree().paused = not get_tree().paused

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
	_add_random_item_to_inventory()
	
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
	_set_progress(0.0)
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
