extends Panel

signal wheel_finished(result: String)

var options = [
	"Sadluck AI slop",
	"Josef's tobacco",
	"Čeněk's endless speech",
	"DJ's failed calculation"
]

var descriptions = [
	"Everyone gets 120% focus!",
	"All actions are 2x effective this level!",
	"Focus frozen + time runs 4x faster!",
	"-20 focus now, but 120% next level!"
]

var segment_colors = [
	Color(0.7, 0.1, 0.1),   # Red - Sadluck
	Color(0.6, 0.4, 0.05),  # Brown/Gold - Josef
	Color(0.15, 0.15, 0.7), # Blue - Čeněk
	Color(0.1, 0.55, 0.1),  # Green - DJ
]

var is_spinning: bool = false
var is_stopping: bool = false
var spin_speed: float = 12.0
var current_pos: float = 0.0
var deceleration_rate: float = 0.0

var active_styles: Array = []
var inactive_styles: Array = []

@onready var option_labels: Array = [
	$OptionsContainer/Option1,
	$OptionsContainer/Option2,
	$OptionsContainer/Option3,
	$OptionsContainer/Option4
]
@onready var instruction_label = $InstructionLabel
@onready var result_label = $ResultLabel
@onready var desc_label = $DescLabel

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Pre-create styles for performance
	for i in range(4):
		var a_style = StyleBoxFlat.new()
		a_style.bg_color = segment_colors[i]
		a_style.set_corner_radius_all(6)
		a_style.set_content_margin_all(8)
		active_styles.append(a_style)
		
		var i_style = StyleBoxFlat.new()
		i_style.bg_color = segment_colors[i].darkened(0.6)
		i_style.set_corner_radius_all(6)
		i_style.set_content_margin_all(8)
		inactive_styles.append(i_style)

func start_minigame():
	visible = true
	is_spinning = true
	is_stopping = false
	spin_speed = 12.0
	current_pos = randf() * 4.0
	result_label.text = ""
	desc_label.text = ""
	instruction_label.text = "Press SPACE to stop the wheel!"
	
	get_tree().paused = true
	_update_highlight()

func _process(delta: float):
	if not is_spinning:
		return
	
	current_pos += spin_speed * delta
	while current_pos >= 4.0:
		current_pos -= 4.0
	
	if is_stopping:
		spin_speed -= deceleration_rate * delta
		if spin_speed <= 0.5:
			spin_speed = 0.0
			is_spinning = false
			var snapped = int(round(current_pos)) % 4
			current_pos = float(snapped)
			_update_highlight()
			_on_wheel_stopped()
			return
	
	_update_highlight()

func _update_highlight():
	var active = int(current_pos) % 4
	for i in range(4):
		if i == active:
			option_labels[i].add_theme_stylebox_override("normal", active_styles[i])
			option_labels[i].add_theme_color_override("font_color", Color.WHITE)
			option_labels[i].add_theme_font_size_override("font_size", 24)
			option_labels[i].text = "▶  " + options[i] + "  ◀"
		else:
			option_labels[i].add_theme_stylebox_override("normal", inactive_styles[i])
			option_labels[i].add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			option_labels[i].add_theme_font_size_override("font_size", 18)
			option_labels[i].text = "   " + options[i]

func _input(event: InputEvent):
	if not is_spinning or is_stopping:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			is_stopping = true
			deceleration_rate = spin_speed / 2.5  # ~2.5 seconds to stop
			instruction_label.text = "Stopping..."
			get_viewport().set_input_as_handled()

func _on_wheel_stopped():
	var final_index = int(current_pos) % 4
	var result = options[final_index]
	
	instruction_label.text = ""
	result_label.text = result + "!"
	desc_label.text = descriptions[final_index]
	
	var timer = get_tree().create_timer(2.5)
	timer.timeout.connect(_on_result_timeout.bind(result))

func _on_result_timeout(result: String):
	visible = false
	get_tree().paused = false
	wheel_finished.emit(result)
