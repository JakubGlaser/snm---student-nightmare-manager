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

var main_scene_instance: Node = null
var main_menu_instance: Node = null

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
	# Wipe any existing run, then spawn a fresh MainScene
	if main_scene_instance and is_instance_valid(main_scene_instance):
		if main_scene_instance.is_inside_tree():
			get_tree().root.remove_child(main_scene_instance)
		main_scene_instance.queue_free()
		main_scene_instance = null
	_detach_menu()
	main_scene_instance = MAIN_SCENE.instantiate()
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

func quit_game() -> void:
	get_tree().quit()

func _detach_menu() -> void:
	if main_menu_instance and is_instance_valid(main_menu_instance) and main_menu_instance.is_inside_tree():
		get_tree().root.remove_child(main_menu_instance)

func _detach_game() -> void:
	if main_scene_instance and is_instance_valid(main_scene_instance) and main_scene_instance.is_inside_tree():
		get_tree().root.remove_child(main_scene_instance)
