extends Node2D

const SUBTITLE_FRAME_COUNT := 6
const SUBTITLE_FPS := 8.0

# Looping stop-motion paper background, played as a handful of frames (cheaper
# and more fitting than a full video). Frames live in res://assets/Menu/PaperBg.
const BG_FRAME_COUNT := 12
const BG_FPS := 8.0

# Purely decorative hand-drawn "Tutorial" wiggle that loops over a few frames.
# Does nothing functional — it just looks nice. Frames are 1-indexed on disk.
const TUT_ANIM_FRAME_COUNT := 6
const TUT_ANIM_FPS := 8.0

@onready var continue_button: TextureButton = $UI/Buttons/ContinueButton
@onready var menu_music: AudioStreamPlayer = $MenuMusic
@onready var music_toggle: TextureButton = $UI/AudioToggles/MusicToggle
@onready var sound_toggle: TextureButton = $UI/AudioToggles/SoundToggle
@onready var subtitle: TextureRect = $UI/Subtitle
@onready var background: TextureRect = $UI/Background
@onready var openings_button: TextureButton = $UI/OpeningsButton
@onready var credits_button: TextureButton = $UI/CreditsButton
@onready var info_button: TextureButton = $UI/InfoButton
@onready var tutorial = $Tutorial # Tutorial.gd (typed loosely: custom open())
@onready var tutorial_anim: TextureRect = $UI/TutorialAnim

var subtitle_frames: Array[Texture2D] = []
var subtitle_elapsed: float = 0.0

var bg_frames: Array[Texture2D] = []
var bg_elapsed: float = 0.0

var tut_anim_frames: Array[Texture2D] = []
var tut_anim_elapsed: float = 0.0

func _ready() -> void:
	$UI/Buttons/PlayButton.pressed.connect(_on_play_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	$UI/Buttons/SettingsButton.pressed.connect(_on_settings_pressed)
	$UI/Buttons/LeaderboardButton.pressed.connect(_on_leaderboard_pressed)
	$UI/Buttons/ExitButton.pressed.connect(_on_exit_pressed)
	music_toggle.pressed.connect(_on_music_toggle_pressed)
	sound_toggle.pressed.connect(_on_sound_toggle_pressed)
	openings_button.pressed.connect(_on_openings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	info_button.pressed.connect(_on_info_pressed)
	_load_subtitle_frames()
	_load_bg_frames()
	_load_tut_anim_frames()
	refresh_continue_state()
	(menu_music.stream as AudioStreamMP3).loop = true
	# Apply stored global state
	if Game.music_enabled:
		menu_music.play()
	music_toggle.modulate = Color(1, 1, 1, 1) if Game.music_enabled else Color(0.4, 0.4, 0.4, 1)
	sound_toggle.modulate = Color(1, 1, 1, 1) if Game.sound_enabled else Color(0.4, 0.4, 0.4, 1)
	Game.connect_ui_sounds(self)

func _load_bg_frames() -> void:
	bg_frames.clear()
	for i in range(BG_FRAME_COUNT):
		var tex := load("res://assets/Menu/PaperBg/paper_%02d.jpg" % i) as Texture2D
		if tex != null:
			bg_frames.append(tex)
	if bg_frames.size() > 0:
		background.texture = bg_frames[0]

func _load_tut_anim_frames() -> void:
	tut_anim_frames.clear()
	for i in range(1, TUT_ANIM_FRAME_COUNT + 1):
		var tex := load("res://sprites/menu/tutorial animace/Tutorial (%d).PNG" % i) as Texture2D
		if tex != null:
			tut_anim_frames.append(tex)
	if tut_anim_frames.size() > 0:
		tutorial_anim.texture = tut_anim_frames[0]

func refresh_continue_state() -> void:
	# Continue is only selectable when there's a paused game waiting.
	# When disabled the button shows its greyed-out texture_disabled sprite,
	# so it reads clearly as unavailable (vs. the bright colored normal sprite).
	var has_game := Game.has_game_in_progress()
	continue_button.disabled = not has_game
	continue_button.modulate = Color(1, 1, 1, 1)

func _on_play_pressed() -> void:
	Game.start_new_game()

func _on_continue_pressed() -> void:
	if continue_button.disabled:
		return
	Game.resume_game()

func _on_settings_pressed() -> void:
	pass

func _on_leaderboard_pressed() -> void:
	var overlay: CanvasLayer
	overlay = Game.build_leaderboard_overlay("Close", func(): overlay.queue_free())
	add_child(overlay)

func _on_exit_pressed() -> void:
	Game.quit_game()

# TODO: hook these up to real screens. The buttons are wired and ready so you
# can drag them wherever you want in the editor.
func _on_openings_pressed() -> void:
	pass

func _on_credits_pressed() -> void:
	pass

func _on_info_pressed() -> void:
	# Open the tutorial; when it closes, the player is already back in the menu.
	tutorial.open()

func _load_subtitle_frames() -> void:
	subtitle_frames.clear()
	for i in range(1, SUBTITLE_FRAME_COUNT + 1):
		var tex := load("res://assets/Menu/Nightmare/Nightmare_%d.png" % i) as Texture2D
		if tex != null:
			subtitle_frames.append(tex)
	if subtitle_frames.size() > 0:
		subtitle.texture = subtitle_frames[0]

func _process(delta: float) -> void:
	if not subtitle_frames.is_empty():
		subtitle_elapsed += delta
		var idx := int(subtitle_elapsed * SUBTITLE_FPS) % subtitle_frames.size()
		if subtitle.texture != subtitle_frames[idx]:
			subtitle.texture = subtitle_frames[idx]

	if not bg_frames.is_empty():
		bg_elapsed += delta
		var bg_idx := int(bg_elapsed * BG_FPS) % bg_frames.size()
		if background.texture != bg_frames[bg_idx]:
			background.texture = bg_frames[bg_idx]

	if not tut_anim_frames.is_empty():
		tut_anim_elapsed += delta
		var tut_idx := int(tut_anim_elapsed * TUT_ANIM_FPS) % tut_anim_frames.size()
		if tutorial_anim.texture != tut_anim_frames[tut_idx]:
			tutorial_anim.texture = tut_anim_frames[tut_idx]

func _on_music_toggle_pressed() -> void:
	Game.music_enabled = !Game.music_enabled
	if Game.music_enabled:
		menu_music.play()
		music_toggle.modulate = Color(1, 1, 1, 1)
	else:
		menu_music.stop()
		music_toggle.modulate = Color(0.4, 0.4, 0.4, 1)

func _on_sound_toggle_pressed() -> void:
	Game.sound_enabled = !Game.sound_enabled
	sound_toggle.modulate = Color(1, 1, 1, 1) if Game.sound_enabled else Color(0.4, 0.4, 0.4, 1)
