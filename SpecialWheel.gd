extends Control

signal wheel_finished(result: String)

const OPTION_TEXTURE := preload("res://sprites/Special Ability Option.png")
const OPTION_SELECTED_TEXTURE := preload("res://sprites/Special Ability Option Selected.png")

const ABILITIES := [
	{
		"id": "sadluck_ai_slop",
		"title": "Sadluck AI slop",
		"description": "Everyone gets 120% focus!"
	},
	{
		"id": "josefs_tobacco",
		"title": "Josef's tobacco",
		"description": "All actions are 2x effective this level!"
	},
	{
		"id": "ceneks_endless_speech",
		"title": "Cenek's endless speech",
		"description": "Focus frozen + time runs 4x faster!"
	},
	{
		"id": "djs_failed_calculation",
		"title": "DJ's failed calculation",
		"description": "-20 focus now, but 120% next level!"
	}
]

var is_spinning: bool = false
var is_stopping: bool = false
var spin_speed: float = 12.0
var current_pos: float = 0.0
var deceleration_rate: float = 0.0
var option_rows: Array[TextureRect] = []
var option_labels: Array[Label] = []

@onready var options_container: VBoxContainer = $OptionsScroll/OptionsContainer
@onready var options_scroll: ScrollContainer = $OptionsScroll
@onready var instruction_label: Label = $InstructionLabel
@onready var result_label: Label = $ResultLabel
@onready var desc_label: Label = $DescLabel

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_option_rows()

func start_minigame():
	visible = true
	is_spinning = true
	is_stopping = false
	spin_speed = 12.0
	current_pos = randf() * ABILITIES.size()
	result_label.text = ""
	desc_label.text = ""
	instruction_label.text = "Press SPACE to stop the wheel!"
	
	get_tree().paused = true
	_update_highlight()

func _process(delta: float):
	if not is_spinning:
		return
	
	current_pos = fposmod(current_pos + (spin_speed * delta), ABILITIES.size())
	
	if is_stopping:
		spin_speed -= deceleration_rate * delta
		if spin_speed <= 0.5:
			spin_speed = 0.0
			is_spinning = false
			var snapped = int(round(current_pos)) % ABILITIES.size()
			current_pos = float(snapped)
			_update_highlight()
			_on_wheel_stopped()
			return
	
	_update_highlight()

func _input(event: InputEvent):
	if not is_spinning or is_stopping:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			is_stopping = true
			deceleration_rate = spin_speed / 2.5
			instruction_label.text = "Stopping..."
			get_viewport().set_input_as_handled()

func _build_option_rows():
	for child in options_container.get_children():
		child.queue_free()
	
	option_rows.clear()
	option_labels.clear()
	
	for ability in ABILITIES:
		var row := TextureRect.new()
		row.custom_minimum_size = Vector2(0, 50)
		row.texture = OPTION_TEXTURE
		row.ignore_texture_size = true
		row.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var label := Label.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color(0.15, 0.065, 0.015))
		label.add_theme_constant_override("outline_size", 8)
		label.add_theme_font_size_override("font_size", 20)
		label.text = ability["title"]
		
		row.add_child(label)
		options_container.add_child(row)
		option_rows.append(row)
		option_labels.append(label)

func _update_highlight():
	var active = int(current_pos) % ABILITIES.size()
	for i in range(option_rows.size()):
		var is_active = i == active
		option_rows[i].texture = OPTION_SELECTED_TEXTURE if is_active else OPTION_TEXTURE
		option_labels[i].modulate = Color.WHITE if is_active else Color(0.82, 0.82, 0.82)
		option_labels[i].add_theme_font_size_override("font_size", 22 if is_active else 18)
		option_labels[i].text = ABILITIES[i]["title"]
	
	_keep_active_option_visible(active)

func _keep_active_option_visible(active: int):
	if active < 0 or active >= option_rows.size():
		return
	
	var row := option_rows[active]
	var row_top := int(row.position.y)
	var row_bottom := row_top + int(row.size.y)
	var visible_top := options_scroll.scroll_vertical
	var visible_bottom := visible_top + int(options_scroll.size.y)
	
	if row_top < visible_top:
		options_scroll.scroll_vertical = row_top
	elif row_bottom > visible_bottom:
		options_scroll.scroll_vertical = row_bottom - int(options_scroll.size.y)

func _on_wheel_stopped():
	var final_index = int(current_pos) % ABILITIES.size()
	var ability: Dictionary = ABILITIES[final_index]
	
	instruction_label.text = ""
	result_label.text = ability["title"] + "!"
	desc_label.text = ability["description"]
	
	var timer = get_tree().create_timer(3.0, true)
	timer.timeout.connect(_on_result_timeout.bind(ability["id"]))

func _on_result_timeout(result_id: String):
	visible = false
	get_tree().paused = false
	wheel_finished.emit(result_id)
