extends Sprite2D

var focus: float = 0.0
var focus_decay_rate: float = 1.0 # Focus lost per second

var is_active: bool = true

signal student_died

var focus_label: Label

var tint_shader_code = """
shader_type canvas_item;
uniform vec4 tint_color : source_color = vec4(1.0);
void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	if (tex_color.a > 0.0) {
		COLOR = vec4(tint_color.rgb, tex_color.a);
	} else {
		COLOR = tex_color;
	}
}
"""

func _ready():
	var shader = Shader.new()
	shader.code = tint_shader_code
	
	var mat = ShaderMaterial.new()
	mat.shader = shader
	self.material = mat
	
	focus_label = Label.new()
	focus_label.position = Vector2(-200, -400) # Centered on their face (relative to original sprite scale)
	focus_label.set("theme_override_font_sizes/font_size", 300)
	focus_label.set("theme_override_colors/font_color", Color.WHITE)
	focus_label.set("theme_override_colors/font_outline_color", Color.BLACK)
	focus_label.set("theme_override_constants/outline_size", 40)
	add_child(focus_label)
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	focus = rng.randf_range(50.0, 79.0)
	update_filter()

func reset_for_new_level(new_decay_rate: float):
	if not is_active: return
	
	focus_decay_rate = new_decay_rate
	bonus_focus = 0.0
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	focus = rng.randf_range(50.0, 79.0)
	
	update_filter()

var bonus_focus: float = 0.0
var decay_paused: bool = false
var is_qte: bool = false

func add_bonus_focus(amount: float):
	if not is_active: return
	bonus_focus += amount
	focus += amount
	if focus > 100.0:
		focus = 100.0
	update_filter()

func set_decay_paused(paused: bool):
	decay_paused = paused

func set_qte_letter(letter: String):
	is_qte = true
	focus_label.text = letter
	focus_label.set("theme_override_colors/font_color", Color.YELLOW)

func clear_qte():
	is_qte = false
	focus_label.set("theme_override_colors/font_color", Color.WHITE)
	update_filter()

func modify_focus(amount: float):
	if not is_active:
		return
		
	focus += amount
	if focus > 100.0:
		focus = 100.0
	elif focus <= 0.0:
		focus = 0.0
		is_active = false
		student_died.emit()
		
	update_filter()

func _process(delta: float):
	if not is_active or decay_paused:
		return
		
	if bonus_focus > 0:
		# Double decay for the bonus portion
		var decay = focus_decay_rate * 2.0 * delta
		bonus_focus -= decay
		focus -= decay
		if bonus_focus < 0:
			bonus_focus = 0.0 # clamp
	else:
		# Standard decay
		focus -= focus_decay_rate * delta
	
	if focus <= 0.0:
		focus = 0.0
		is_active = false
		student_died.emit()
		
	update_filter()

func update_filter():
	if not is_qte:
		focus_label.text = str(int(focus)) + "%"
	
	var color = Color(1, 1, 1)
	if focus >= 80.0:
		color = Color(0.0, 0.4, 0.0) # Dark Green
	elif focus >= 50.0:
		color = Color(0.0, 1.0, 0.0) # Green
	elif focus >= 30.0:
		color = Color(1.0, 1.0, 0.0) # Yellow
	elif focus > 0.0:
		color = Color(1.0, 0.0, 0.0) # Red
	else:
		color = Color(0.0, 0.0, 0.0) # Black
		
	if self.material and self.material is ShaderMaterial:
		self.material.set_shader_parameter("tint_color", color)
