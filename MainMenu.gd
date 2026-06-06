extends Node2D

@onready var continue_button: TextureButton = $UI/Buttons/ContinueButton

func _ready() -> void:
	$UI/Buttons/PlayButton.pressed.connect(_on_play_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	$UI/Buttons/SettingsButton.pressed.connect(_on_settings_pressed)
	$UI/Buttons/ExitButton.pressed.connect(_on_exit_pressed)
	refresh_continue_state()

func refresh_continue_state() -> void:
	# Continue is only selectable when there's a paused game waiting.
	var has_game := Game.has_game_in_progress()
	continue_button.disabled = not has_game
	continue_button.modulate = Color(1, 1, 1, 1) if has_game else Color(0.55, 0.55, 0.55, 0.85)

func _on_play_pressed() -> void:
	Game.start_new_game()

func _on_continue_pressed() -> void:
	if continue_button.disabled:
		return
	Game.resume_game()

func _on_settings_pressed() -> void:
	# Reserved for future use.
	pass

func _on_exit_pressed() -> void:
	Game.quit_game()
