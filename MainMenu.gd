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

# Audio levels (in dB) — fully independent of each other. Tweak to taste.
# VideoStreamPlayer.volume_db tops out at +24 dB; if a video still distorts at
# high boost, the source recording itself is too quiet and needs amplifying.
const OPENING_VOLUME_DB := 12.0     # opening video, boosted loud
const CREDITS_VOLUME_DB := 6.0      # credits video, a bit quieter than opening
const MENU_MUSIC_VOLUME_DB := -12.0 # menu music, turned down

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
@onready var credits_video: VideoStreamPlayer = $UI/CreditsVideo
@onready var opening_video: VideoStreamPlayer = $UI/OpeningVideo
@onready var settings_screen: ColorRect = $UI/SettingsScreen
@onready var settings_sound: AudioStreamPlayer = $SettingsSound

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
	# Videos and menu music have independent volumes: videos boosted loud, menu
	# music turned down (see the constants above).
	menu_music.volume_db = MENU_MUSIC_VOLUME_DB
	credits_video.stream = load("res://assets/Credits.ogv")
	credits_video.volume_db = CREDITS_VOLUME_DB
	credits_video.finished.connect(_on_credits_finished)
	opening_video.stream = load("res://assets/Opening.ogv")
	opening_video.volume_db = OPENING_VOLUME_DB
	opening_video.finished.connect(_on_opening_finished)
	settings_screen.gui_input.connect(_on_settings_screen_input)
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
	# _ready runs once per launch (the menu instance is reused on return-to-menu),
	# so this plays the opening as the very first thing when the game starts.
	_play_opening()

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
	# There is, of course, no real settings menu. Show the cheeky black screen
	# and play its sound; the menu music steps aside meanwhile.
	menu_music.stop()
	settings_screen.visible = true
	if settings_sound.stream != null:
		settings_sound.play()

func _on_settings_screen_input(event: InputEvent) -> void:
	# Click (or any key) anywhere closes the screen and returns to the menu.
	var dismiss: bool = (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventKey and event.pressed and not event.echo)
	if dismiss:
		_close_settings()

func _close_settings() -> void:
	settings_screen.visible = false
	settings_sound.stop()
	if Game.music_enabled:
		menu_music.play()

var leaderboard_overlay: CanvasLayer = null

func _on_leaderboard_pressed() -> void:
	if leaderboard_overlay != null and is_instance_valid(leaderboard_overlay):
		return
	# NOTE: don't capture a not-yet-assigned local in the close callback — GDScript
	# lambdas capture by value, so it would capture `null`. Close via a method that
	# reads the member variable at click time instead.
	leaderboard_overlay = Game.build_leaderboard_overlay("Close", _close_leaderboard)
	add_child(leaderboard_overlay)

func _close_leaderboard() -> void:
	if leaderboard_overlay != null and is_instance_valid(leaderboard_overlay):
		leaderboard_overlay.queue_free()
		leaderboard_overlay = null

func _on_exit_pressed() -> void:
	Game.quit_game()

func _on_openings_pressed() -> void:
	_play_opening()

# Plays the opening video full-screen (menu music steps aside for the video's
# own audio). Used both on launch and when the Openings button is pressed.
func _play_opening() -> void:
	if opening_video.stream == null:
		return
	menu_music.stop()
	opening_video.visible = true
	opening_video.play()

func _on_opening_finished() -> void:
	# Video done -> back to the main menu.
	opening_video.stop()
	opening_video.visible = false
	if Game.music_enabled:
		menu_music.play()

func _on_credits_pressed() -> void:
	# Play the credits video full-screen; the menu music steps aside so it
	# doesn't clash with the video's own audio.
	if credits_video.stream == null:
		return
	menu_music.stop()
	credits_video.visible = true
	credits_video.play()

func _on_credits_finished() -> void:
	# Video done -> back to the main menu.
	credits_video.stop()
	credits_video.visible = false
	if Game.music_enabled:
		menu_music.play()

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
