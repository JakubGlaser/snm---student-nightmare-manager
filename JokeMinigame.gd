extends Panel

signal joke_finished(success: bool)

# Minigame settings
@export var cursor_speed: float = 600.0
@export var sweet_spot_width: float = 80.0

@onready var background_bar = $BackgroundBar
@onready var sweet_spot = $BackgroundBar/SweetSpot
@onready var cursor = $BackgroundBar/Cursor
@onready var instruction_label = $InstructionLabel

var is_playing: bool = false
var cursor_direction: int = 1
var bar_width: float = 0.0

func _ready():
	visible = false
	# Ensure this runs even when the SceneTree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_minigame():
	visible = true
	is_playing = true
	
	# Pause the entire game so students stop decaying and the level timer stops
	get_tree().paused = true
	
	bar_width = background_bar.size.x
	
	# Setup SweetSpot
	sweet_spot.size.x = sweet_spot_width
	sweet_spot.size.y = background_bar.size.y
	# Randomize sweet spot position along the bar
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var min_x = 0.0
	var max_x = bar_width - sweet_spot_width
	sweet_spot.position.x = rng.randf_range(min_x, max_x)
	sweet_spot.position.y = 0
	
	# Reset cursor
	cursor.position.x = 0
	cursor.position.y = 0
	cursor.size.y = background_bar.size.y
	cursor_direction = 1
	instruction_label.text = "Press SPACE when the white line is in the green zone!"

func _process(delta: float):
	if not is_playing:
		return
		
	# Move cursor back and forth
	cursor.position.x += cursor_speed * cursor_direction * delta
	
	if cursor.position.x >= bar_width - cursor.size.x:
		cursor.position.x = bar_width - cursor.size.x
		cursor_direction = -1
	elif cursor.position.x <= 0:
		cursor.position.x = 0
		cursor_direction = 1

func _input(event: InputEvent):
	if not is_playing:
		return
		
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo):
		# Player pressed Spacebar
		check_win_condition()
		# Consume the event so it doesn't trigger anything else like a button twice
		get_viewport().set_input_as_handled()

func check_win_condition():
	is_playing = false
	
	var cursor_center = cursor.position.x + (cursor.size.x / 2.0)
	var ss_start = sweet_spot.position.x
	var ss_end = ss_start + sweet_spot.size.x
	
	var success = false
	if cursor_center >= ss_start and cursor_center <= ss_end:
		success = true
		instruction_label.text = "NAILED IT! (+20% Focus)"
	else:
		instruction_label.text = "MISSED! (-10% Focus)"
		
	# Wait a short moment so the player sees the result, then end
	var timer = get_tree().create_timer(1.0)
	# Because we are paused and process_mode is ALWAYS on this node, we can bind to timeout without issue
	timer.timeout.connect(_on_result_timeout.bind(success))

func _on_result_timeout(success: bool):
	visible = false
	get_tree().paused = false
	joke_finished.emit(success)
