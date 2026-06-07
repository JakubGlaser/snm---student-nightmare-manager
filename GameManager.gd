extends Node
# Singleton (autoload) that owns the running MainScene and MainMenu instances
# and brokers transitions between them. Set up as autoload "Game" in
# project.godot so any scene can call Game.start_new_game() etc.
#
# Why add/remove from tree instead of toggling visibility?  CanvasLayer
# children of a Node2D keep rendering even when the parent's `visible` is
# false. The only reliable way to fully hide *and* pause a scene is to take
# it out of the SceneTree (we keep the instance reference alive so it can
# come back where it left off).

const MAIN_SCENE := preload("res://MainScene.tscn")
const MAIN_MENU := preload("res://MainMenu.tscn")
const LOADING_SCREEN := preload("res://LoadingScreen.tscn")
const UI_SFX := preload("res://assets/sound/Upravené/ES_Games, Video, Menu UI, Select, Notification 21 - Epidemic Sound.mp3")

var music_enabled: bool = true
var sound_enabled: bool = true

func play_ui_sound() -> void:
	if not sound_enabled:
		return
	var player := AudioStreamPlayer.new()
	player.stream = UI_SFX
	player.pitch_scale = randf_range(0.88, 1.18)
	player.finished.connect(player.queue_free)
	get_tree().root.add_child(player)
	player.play()

func connect_ui_sounds(root_node: Node) -> void:
	for child in root_node.get_children():
		if child is BaseButton:
			if not child.pressed.is_connected(play_ui_sound):
				child.pressed.connect(play_ui_sound)
			if not child.mouse_entered.is_connected(play_ui_sound):
				child.mouse_entered.connect(play_ui_sound)
		connect_ui_sounds(child)

# --- Leaderboard (shared by menu + gameplay) ---

func load_leaderboard() -> Array:
	if not FileAccess.file_exists("user://leaderboard.json"):
		return []
	var file := FileAccess.open("user://leaderboard.json", FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	return parsed if parsed is Array else []

func save_score(player_name: String, score: int, level: int) -> void:
	var board := load_leaderboard()
	board.append({
		"name": player_name,
		"score": score,
		"level": level,
		"date": Time.get_date_string_from_system()
	})
	board.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	if board.size() > 10:
		board = board.slice(0, 10)
	var file := FileAccess.open("user://leaderboard.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(board, "\t"))
	file.close()

# Builds a self-contained leaderboard overlay (dark bg + panel + entries + a
# close button). Caller adds the returned CanvasLayer to its own tree and
# supplies what the button does via on_close.
func build_leaderboard_overlay(close_text: String, on_close: Callable) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 250
	layer.process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.color = Color(0.05, 0.05, 0.05, 0.7)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)

	var panel := Panel.new()
	panel.size = Vector2(580, 530)
	panel.position = Vector2(286, 59)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.94, 0.78, 0.97)
	style.border_color = Color(0.15, 0.065, 0.015, 1.0)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)

	var title := Label.new()
	title.text = "LEADERBOARD"
	title.position = Vector2(0, 14)
	title.size = Vector2(580, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.11, 0.055, 0.02, 1.0))
	panel.add_child(title)

	var board := load_leaderboard()
	if board.is_empty():
		var empty := Label.new()
		empty.text = "No scores yet — go play!"
		empty.position = Vector2(0, 220)
		empty.size = Vector2(580, 40)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 22)
		empty.add_theme_color_override("font_color", Color(0.11, 0.055, 0.02, 1.0))
		panel.add_child(empty)
	else:
		var medals := ["#1", "#2", "#3"]
		for i in min(board.size(), 10):
			var entry: Dictionary = board[i]
			var prefix: String = medals[i] if i < medals.size() else ("#" + str(i + 1))
			var row := Label.new()
			row.text = "%s  %s — %d pts  (lvl %d)" % [
				prefix, entry.get("name", "?"),
				int(entry.get("score", 0)),
				int(entry.get("level", 1))
			]
			row.position = Vector2(36, 64 + i * 40)
			row.add_theme_font_size_override("font_size", 20)
			row.add_theme_color_override("font_color", Color(0.11, 0.055, 0.02, 1.0))
			panel.add_child(row)

	var close_btn := Button.new()
	close_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	close_btn.text = close_text
	close_btn.position = Vector2(190, 468)
	close_btn.size = Vector2(200, 48)
	close_btn.add_theme_font_size_override("font_size", 22)
	panel.add_child(close_btn)
	close_btn.pressed.connect(on_close)
	connect_ui_sounds(panel)
	return layer

var main_scene_instance: Node = null
var main_menu_instance: Node = null
var loading_screen_instance: Node = null
var pending_main_scene: Node = null

func _ready() -> void:
	# Defer one frame so the SceneTree finishes wiring up Main.tscn before we
	# start adding our own scenes to the root.
	await get_tree().process_frame
	show_menu()

func has_game_in_progress() -> bool:
	return main_scene_instance != null and is_instance_valid(main_scene_instance)

func show_menu() -> void:
	_detach_game()
	get_tree().paused = false
	var freshly_instanced := false
	if main_menu_instance == null or not is_instance_valid(main_menu_instance):
		main_menu_instance = MAIN_MENU.instantiate()
		freshly_instanced = true
	if not main_menu_instance.is_inside_tree():
		get_tree().root.add_child(main_menu_instance)
	# Fresh instances haven't run their _ready yet, so @onready vars are nil.
	# Wait one frame; otherwise call refresh directly.
	if freshly_instanced:
		await get_tree().process_frame
	if main_menu_instance.has_method("refresh_continue_state"):
		main_menu_instance.refresh_continue_state()

func start_new_game() -> void:
	# Wipe any existing run, then show the loading screen. It instantiates the
	# fresh MainScene itself (the actual "loading" work, done in the
	# background while the player reads tips) and hands off to it via
	# enter_prepared_game() once they click through.
	if main_scene_instance and is_instance_valid(main_scene_instance):
		if main_scene_instance.is_inside_tree():
			get_tree().root.remove_child(main_scene_instance)
		main_scene_instance.queue_free()
		main_scene_instance = null
	if pending_main_scene and is_instance_valid(pending_main_scene):
		pending_main_scene.queue_free()
		pending_main_scene = null
	_detach_menu()
	loading_screen_instance = LOADING_SCREEN.instantiate()
	get_tree().root.add_child(loading_screen_instance)

# Instantiates the next MainScene off-screen (not added to the tree, so its
# _ready never runs — no music, no game logic ticking) so the one real "loading"
# cost — building the node tree from the preloaded PackedScene — happens while
# the player is reading tips rather than as a hitch right when the game would
# otherwise appear.
func prepare_pending_main_scene() -> void:
	if pending_main_scene and is_instance_valid(pending_main_scene):
		pending_main_scene.queue_free()
	pending_main_scene = MAIN_SCENE.instantiate()

# Drops the prepared instance straight into the tree and tears the loading
# screen down. Called by the loading screen once the player clicks through.
func enter_prepared_game() -> void:
	if pending_main_scene == null or not is_instance_valid(pending_main_scene):
		prepare_pending_main_scene()
	main_scene_instance = pending_main_scene
	pending_main_scene = null
	if loading_screen_instance and is_instance_valid(loading_screen_instance):
		if loading_screen_instance.is_inside_tree():
			get_tree().root.remove_child(loading_screen_instance)
		loading_screen_instance.queue_free()
		loading_screen_instance = null
	get_tree().root.add_child(main_scene_instance)

func resume_game() -> void:
	if not has_game_in_progress():
		return
	_detach_menu()
	if not main_scene_instance.is_inside_tree():
		get_tree().root.add_child(main_scene_instance)
	get_tree().paused = false

func return_to_menu_from_game() -> void:
	show_menu()

# Permanently throw away the current run (used after game over) so Continue
# correctly reports "no game in progress" and shows its disabled sprite.
func discard_game() -> void:
	if main_scene_instance and is_instance_valid(main_scene_instance):
		if main_scene_instance.is_inside_tree():
			get_tree().root.remove_child(main_scene_instance)
		main_scene_instance.queue_free()
		main_scene_instance = null
	show_menu()

func quit_game() -> void:
	get_tree().quit()

func _detach_menu() -> void:
	if main_menu_instance and is_instance_valid(main_menu_instance) and main_menu_instance.is_inside_tree():
		get_tree().root.remove_child(main_menu_instance)

func _detach_game() -> void:
	if main_scene_instance and is_instance_valid(main_scene_instance) and main_scene_instance.is_inside_tree():
		get_tree().root.remove_child(main_scene_instance)
