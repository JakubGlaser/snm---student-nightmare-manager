extends TextureRect

const FRAMES_DIR := "res://assets/bg_frames"
const FRAME_COUNT := 96
const FPS := 12.0

var frames: Array[Texture2D] = []
var elapsed: float = 0.0

func _ready() -> void:
	frames.resize(FRAME_COUNT)
	for i in FRAME_COUNT:
		var path := "%s/bg_%04d.jpg" % [FRAMES_DIR, i]
		frames[i] = load(path)
	if frames.size() > 0 and frames[0] != null:
		texture = frames[0]

func _process(delta: float) -> void:
	if frames.is_empty():
		return
	elapsed += delta
	var idx := int(elapsed * FPS) % FRAME_COUNT
	var tex := frames[idx]
	if tex != null and tex != texture:
		texture = tex
