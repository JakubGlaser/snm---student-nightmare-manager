extends Node2D
# Bridges the menu -> gameplay transition with a fixed-length loading screen.
# The MainScene gets instantiated here — the only real "loading" cost left,
# since its PackedScene is preloaded at startup — so that hitch happens while
# the player is reading tips instead of right as the game would appear.

const MIN_DURATION := 5.0
const TIP_ROTATE_INTERVAL := 7.0

# Ken Burns-style drift: the background starts a bit zoomed OUT, slowly grows
# in while panning, then eases back — looping for as long as the screen is up.
const BACKGROUND_ZOOM_MIN := 0.8
const BACKGROUND_ZOOM_MAX := 1.1
const BACKGROUND_PAN_DISTANCE := 60.0
const BACKGROUND_PAN_DURATION := 14.0

var tips: Array[String] = [
	"Don't let anyone fall to zero – one burned-out student speeds up the focus drop for their whole group.",
	"Keep an eye on your cooldowns and rotate your actions so you always have something ready.",
	"Save your strong items and the Wheel of Luck for crisis moments in higher levels.",
	"The Question is great not only for its bonus but also because focus doesn't drop during it.",
	"The goal is to last as long as possible – every level past ten is +1000 score.",
	"\"We know our visuals sucks\" — random Dev",
	"\"Haku stop eating my eaaaaaar for god sake!\" — random Dev",
	"\"It's 1 am, I need to reeest!!!\" — random Dev",
	"Hey player, go to sleep, it's 2 am right now.",
	"\"We don't have to think, we have Claude to think\" — random Dev",
	"\"Burn in silicon hell you piece of ****, die on *********** you are f**** talking calculator, what do you think of yourself\" — random Dev to Claude",
]

# One of the images in this folder is picked at random as the background each
# time the loading screen appears (scanned at runtime so adding/removing art
# doesn't require touching code).
const BACKGROUND_DIR := "res://assets/loading screen/"

var elapsed := 0.0
var tip_elapsed := 0.0
var tip_index := 0
var min_time_reached := false
var revealed := false

@onready var background: TextureRect = $UI/Background
@onready var tip_label: Label = $UI/TipPanel/TipLabel
@onready var tip_counter: Label = $UI/TipPanel/Nav/TipCounter
@onready var prev_button: Button = $UI/TipPanel/Nav/PrevButton
@onready var next_button: Button = $UI/TipPanel/Nav/NextButton
@onready var start_button: Button = $UI/StartButton
@onready var loading_music: AudioStreamPlayer = $LoadingMusic

func _ready() -> void:
	if Game.music_enabled:
		(loading_music.stream as AudioStreamMP3).loop = true
		loading_music.play()
	background.texture = _pick_random_background()
	background.pivot_offset = background.size / 2.0
	background.scale = Vector2(BACKGROUND_ZOOM_MIN, BACKGROUND_ZOOM_MIN)
	var base_x := background.position.x
	var pan_tween := create_tween().set_loops()
	pan_tween.tween_property(background, "position:x", base_x - BACKGROUND_PAN_DISTANCE, BACKGROUND_PAN_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pan_tween.tween_property(background, "position:x", base_x, BACKGROUND_PAN_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var zoom_tween := create_tween().set_loops()
	zoom_tween.tween_property(background, "scale", Vector2(BACKGROUND_ZOOM_MAX, BACKGROUND_ZOOM_MAX), BACKGROUND_PAN_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	zoom_tween.tween_property(background, "scale", Vector2(BACKGROUND_ZOOM_MIN, BACKGROUND_ZOOM_MIN), BACKGROUND_PAN_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tip_index = randi() % tips.size()
	_refresh_tip()
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	start_button.pressed.connect(_on_start_pressed)
	start_button.modulate = Color(1, 1, 1, 0)
	Game.connect_ui_sounds(self)
	# Kick off the real instantiation now, while the screen is up.
	Game.prepare_pending_main_scene()

func _process(delta: float) -> void:
	if not min_time_reached:
		elapsed += delta
		if elapsed >= MIN_DURATION:
			min_time_reached = true
			_reveal_start_button()

	tip_elapsed += delta
	if tip_elapsed >= TIP_ROTATE_INTERVAL:
		tip_elapsed = 0.0
		_step_tip(1)

func _reveal_start_button() -> void:
	if revealed:
		return
	revealed = true
	start_button.disabled = false
	var tw := create_tween()
	tw.tween_property(start_button, "modulate:a", 1.0, 0.5)

func _pick_random_background() -> Texture2D:
	var dir := DirAccess.open(BACKGROUND_DIR)
	if dir == null:
		return null
	var candidates: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "png":
			candidates.append(BACKGROUND_DIR + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	if candidates.is_empty():
		return null
	return load(candidates[randi() % candidates.size()]) as Texture2D

func _refresh_tip() -> void:
	tip_label.text = tips[tip_index]
	tip_counter.text = "%d / %d" % [tip_index + 1, tips.size()]

func _step_tip(direction: int) -> void:
	tip_index = (tip_index + direction + tips.size()) % tips.size()
	tip_elapsed = 0.0
	_refresh_tip()

func _on_prev_pressed() -> void:
	_step_tip(-1)

func _on_next_pressed() -> void:
	_step_tip(1)

func _on_start_pressed() -> void:
	if start_button.disabled:
		return
	Game.enter_prepared_game()
