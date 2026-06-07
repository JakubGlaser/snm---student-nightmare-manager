extends CanvasLayer
# Reusable tutorial overlay. Shows a sequence of full-screen tutorial images that
# the player flips through with the on-screen arrows (no auto-advance). Clicking
# the right arrow on the LAST page closes the overlay and emits `closed`, so
# whoever opened it (main menu or in-game menu) can restore its own state.

signal closed

# Pages in order. Note the mixed file extensions (.PNG / .png) are intentional —
# they must match the real filenames on disk exactly.
const PAGES: Array[Texture2D] = [
	preload("res://assets/tutorial/Tutorial1.PNG"),
	preload("res://assets/tutorial/Tutorial2.PNG"),
	preload("res://assets/tutorial/Tutorial3.PNG"),
	preload("res://assets/tutorial/Tutorial4.png"),
	preload("res://assets/tutorial/Tutorial5.PNG"),
	preload("res://assets/tutorial/Tutorial6.PNG"),
	preload("res://assets/tutorial/Tutorial7.PNG"),
	preload("res://assets/tutorial/Tutorial8.PNG"),
	preload("res://assets/tutorial/Tutorial9.PNG"),
]

@onready var image: TextureRect = $Image
@onready var left_arrow: TextureButton = $LeftArrow
@onready var right_arrow: TextureButton = $RightArrow

var current_page: int = 0

func _ready() -> void:
	# Keep working while the SceneTree is paused (in-game tutorial pauses the game).
	process_mode = Node.PROCESS_MODE_ALWAYS
	left_arrow.process_mode = Node.PROCESS_MODE_ALWAYS
	right_arrow.process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	left_arrow.pressed.connect(_on_left_pressed)
	right_arrow.pressed.connect(_on_right_pressed)

# Called by the menu's tutorial/info button.
func open() -> void:
	current_page = 0
	_update_page()
	visible = true

func close() -> void:
	visible = false
	closed.emit()

func _update_page() -> void:
	image.texture = PAGES[current_page]
	# No "previous" before the first page — hide the left arrow there.
	left_arrow.visible = current_page > 0

func _on_left_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		_update_page()

func _on_right_pressed() -> void:
	if current_page < PAGES.size() - 1:
		current_page += 1
		_update_page()
	else:
		# Right arrow on the last page returns the player to where they came from.
		close()
