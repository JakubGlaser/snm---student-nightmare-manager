extends Control

signal wheel_finished(result: String)

const PROJECT_FONT := preload("res://assets/fonts/Nunito-Regular.ttf")
const WHEEL_GRAPHIC := preload("res://WheelGraphic.gd")
const SLOT_SFX := preload("res://assets/sound/ES_Games, Casino, Gambling, Slot Machine, Gambling, Slot Machine, Reels Rolling, Loop, Middle - Epidemic Sound.mp3")

# Dedicated bus so we can pitch-shift the spin loop independently of its
# playback tempo: as the wheel brakes we slow the track (player.pitch_scale)
# while raising the perceived pitch (pitch-shift effect).
const SPIN_BUS := "WheelSpin"
const SPIN_TEMPO_MIN := 0.45   # slowest playback tempo at full stop
const SPIN_PITCH_MAX := 1.7    # highest pitch-shift at full stop

func _make_bold_font() -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = PROJECT_FONT
	fv.variation_embolden = 0.6
	return fv

# Each entry drives one slice of the wheel. `color` is the slice fill.
const ABILITIES := [
	{
		"id": "sadluck_ai_slop",
		"title": "Sadluck AI slop",
		"description": "Everyone gets 120% focus!",
		"color": Color(0.45, 0.65, 0.30)
	},
	{
		"id": "josefs_tobacco",
		"title": "Josef's tobacco",
		"description": "All actions are 2x effective this level!",
		"color": Color(0.88, 0.55, 0.20)
	},
	{
		"id": "ceneks_endless_speech",
		"title": "Cenek's endless speech",
		"description": "Focus frozen + time runs 4x faster!",
		"color": Color(0.35, 0.55, 0.78)
	},
	{
		"id": "djs_failed_calculation",
		"title": "DJ's failed calculation",
		"description": "-20 focus now, but 120% next level!",
		"color": Color(0.72, 0.40, 0.62)
	},
	{
		"id": "vitek_lecture_skip",
		"title": "Vítek's Lecture Skip",
		"description": "Lecture skipped — next level NOW!",
		"color": Color(0.82, 0.22, 0.22)
	}
]

var is_spinning: bool = false
var is_stopping: bool = false
var spin_speed: float = 0.0          # radians / second
var deceleration_rate: float = 0.0
var rotation_angle: float = 0.0      # radians
var stop_start_speed: float = 0.0    # spin_speed at the moment braking began

var wheel: Control
var spin_sfx: AudioStreamPlayer
var pitch_effect: AudioEffectPitchShift

@onready var instruction_label: Label = $InstructionLabel
@onready var result_label: Label = $ResultLabel
@onready var desc_label: Label = $DescLabel

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_wheel()
	_setup_audio()

func _setup_audio():
	# Create (or reuse) a private bus carrying a pitch-shift effect.
	var idx := AudioServer.get_bus_index(SPIN_BUS)
	if idx == -1:
		idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, SPIN_BUS)
		AudioServer.set_bus_send(idx, "Master")
		pitch_effect = AudioEffectPitchShift.new()
		pitch_effect.pitch_scale = 1.0
		AudioServer.add_bus_effect(idx, pitch_effect)
	else:
		for e in range(AudioServer.get_bus_effect_count(idx)):
			var eff := AudioServer.get_bus_effect(idx, e)
			if eff is AudioEffectPitchShift:
				pitch_effect = eff
				break

	spin_sfx = AudioStreamPlayer.new()
	spin_sfx.process_mode = Node.PROCESS_MODE_ALWAYS
	spin_sfx.bus = SPIN_BUS
	# Duplicate so we can flip loop on without mutating the shared const resource.
	var stream: AudioStream = SLOT_SFX.duplicate()
	if stream is AudioStreamMP3:
		stream.loop = true
	spin_sfx.stream = stream
	add_child(spin_sfx)

func _build_wheel():
	wheel = Control.new()
	wheel.set_script(WHEEL_GRAPHIC)
	wheel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wheel)
	wheel.label_font = _make_bold_font()
	var segs: Array = []
	for ability in ABILITIES:
		segs.append({ "title": ability["title"], "color": ability["color"] })
	wheel.segments = segs
	_layout_wheel()

func _layout_wheel():
	# Square wheel, centered horizontally, sitting under the instruction label.
	var d : float = min(size.x - 80.0, 320.0)
	wheel.size = Vector2(d, d)
	wheel.position = Vector2((size.x - d) * 0.5, 96.0)

func start_minigame():
	visible = true
	is_spinning = true
	is_stopping = false
	spin_speed = randf_range(11.0, 15.0)
	rotation_angle = randf() * TAU
	result_label.text = ""
	desc_label.text = ""
	instruction_label.text = "Press SPACE to stop the wheel!"

	_layout_wheel()
	wheel.rotation_angle = rotation_angle
	wheel.queue_redraw()

	# Reset + start the rolling-reels loop at normal tempo / pitch.
	spin_sfx.pitch_scale = 1.0
	if pitch_effect != null:
		pitch_effect.pitch_scale = 1.0
	if Game.sound_enabled:
		spin_sfx.play()

	get_tree().paused = true

func _process(delta: float):
	if not is_spinning:
		return

	rotation_angle = fposmod(rotation_angle + spin_speed * delta, TAU)

	if is_stopping:
		spin_speed -= deceleration_rate * delta
		# Wind the audio down in lock-step with the wheel: slower tempo, higher pitch.
		var progress : float = 1.0 - clamp(spin_speed / max(stop_start_speed, 0.001), 0.0, 1.0)
		spin_sfx.pitch_scale = lerp(1.0, SPIN_TEMPO_MIN, progress)
		if pitch_effect != null:
			pitch_effect.pitch_scale = lerp(1.0, SPIN_PITCH_MAX, progress)
		if spin_speed <= 0.2:
			spin_speed = 0.0
			is_spinning = false
			spin_sfx.stop()
			wheel.rotation_angle = rotation_angle
			wheel.queue_redraw()
			_on_wheel_stopped()
			return

	wheel.rotation_angle = rotation_angle
	wheel.queue_redraw()

func _input(event: InputEvent):
	if not is_spinning or is_stopping:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			is_stopping = true
			stop_start_speed = spin_speed
			deceleration_rate = spin_speed / randf_range(2.2, 3.2)
			instruction_label.text = "Stopping..."
			get_viewport().set_input_as_handled()

# Which slice sits under the fixed needle (pointing straight up = angle -PI/2).
func _current_index() -> int:
	var n := ABILITIES.size()
	var seg := TAU / n
	var rel := fposmod(-PI / 2.0 - rotation_angle, TAU)
	return int(rel / seg) % n

func _on_wheel_stopped():
	var idx := _current_index()
	var ability: Dictionary = ABILITIES[idx]

	instruction_label.text = ""
	result_label.text = str(ability["title"]) + "!"
	desc_label.text = str(ability["description"])

	var timer = get_tree().create_timer(3.0, true)
	timer.timeout.connect(_on_result_timeout.bind(ability["id"]))

func _on_result_timeout(result_id: String):
	visible = false
	get_tree().paused = false
	wheel_finished.emit(result_id)
