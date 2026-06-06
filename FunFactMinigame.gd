extends Panel

signal funfact_finished(success: bool)

const FACT_OPTION_TEXTURE := preload("res://sprites/Minigame Option.png")
const FACT_OPTION_SELECTED_TEXTURE := preload("res://sprites/Minigame Option Selected.png")

const EVAL_GREEN := Color(0.10, 0.38, 0.13)
const EVAL_RED  := Color(0.55, 0.12, 0.12)
const COLOR_DEFAULT := Color(0.11, 0.055, 0.02, 1.0)
const COLOR_OUTLINE := Color(1.0, 0.94, 0.78, 0.55)
const SCENE_OUTLINE_SIZE := 4

func _set_eval_style(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	label.add_theme_constant_override("outline_size", 0)

func _reset_eval_style(label: Label) -> void:
	label.add_theme_color_override("font_color", COLOR_DEFAULT)
	label.add_theme_color_override("font_outline_color", COLOR_OUTLINE)
	label.add_theme_constant_override("outline_size", SCENE_OUTLINE_SIZE)

# Each entry: { "fact": "...", "is_fun": true/false }
# We store them grouped: fun facts and boring facts
var fun_facts: Array = [
	"The first movie ever made was only 2 seconds long — it showed a man sneezing.",
	"Netflix was originally a DVD-by-mail service founded in 1997.",
	"The Wilhelm Scream has been used in over 400 movies and TV shows.",
	"Pac-Man was originally called Puck Man but was renamed to avoid vandalism.",
	"The Lion King was the first Disney animated film with an original story.",
	"The longest movie ever made is 857 hours long — it's called 'Logistics'.",
	"SpongeBob's voice actor also voices the Ice King in Adventure Time.",
	"Mario was originally called 'Jumpman' and was a carpenter, not a plumber.",
	"The first YouTube video ever uploaded was called 'Me at the Zoo'.",
	"In the original Monopoly, the richest player was supposed to LOSE.",
	"The 'Friends' theme song was almost 'Shiny Happy People' by R.E.M.",
	"Shrek was originally going to be voiced by Chris Farley before Mike Myers.",
	"Baby Shark is the most watched YouTube video of all time with 14+ billion views.",
	"The Minecraft world is bigger than the surface of Neptune.",
	"Tom & Jerry won 7 Academy Awards — more than most Hollywood actors.",
	"The first text message ever sent just said 'Merry Christmas'.",
	"The creator of the Game Boy was originally a janitor at Nintendo.",
	"Tetris was invented by a Soviet computer scientist in 1984.",
	"Disney's Frozen was in development for over 70 years before release.",
	"The original name for Google was 'BackRub'.",
]

var boring_facts: Array = [
	"The average TV remote has about 40 buttons.",
	"Most film reels are stored at a temperature of 35°F.",
	"The standard frame rate for cinema is 24 frames per second.",
	"A typical newspaper uses about 4 different font sizes.",
	"Radio signals travel at the speed of light.",
	"The average podcast episode is about 41 minutes long.",
	"HDMI cables use 19 pins for data transmission.",
	"Vinyl records spin at either 33 or 45 revolutions per minute.",
	"The first TV broadcast resolution was only 30 lines.",
	"Most streaming services use adaptive bitrate encoding.",
	"An average movie script is about 120 pages long.",
	"The standard aspect ratio for widescreen films is 16:9.",
	"Bluetooth technology uses the 2.4 GHz frequency band.",
	"The average TV is turned on for 7 hours and 50 minutes per day.",
	"Digital cameras store images as JPEG files by default.",
	"The average length of a pop song is 3 minutes and 30 seconds.",
	"Most e-readers use e-ink displays that refresh at about 1 Hz.",
	"USB 3.0 can transfer data at up to 5 Gbps.",
	"The first color TV cost about $1,000 in 1954.",
	"FM radio was patented in 1933 by Edwin Armstrong.",
	"The average smartphone screen is about 6.5 inches.",
	"MP3 files compress audio to about 1/10 of its original size.",
	"The first commercial video game console was the Magnavox Odyssey.",
	"LCD screens use liquid crystals sandwiched between glass panels.",
	"Wi-Fi stands for nothing — it's just a brand name.",
	"The refresh rate of most monitors is 60 Hz.",
	"Optical fiber cables transmit data using pulses of light.",
	"The first email was sent in 1971 by Ray Tomlinson.",
	"Satellite TV signals travel about 22,000 miles from Earth.",
	"The average video game takes about 3-5 years to develop.",
]

@onready var fact_button_1 = $VBoxContainer/FactButton1
@onready var fact_button_2 = $VBoxContainer/FactButton2
@onready var fact_button_3 = $VBoxContainer/FactButton3
@onready var fact_label_1: Label = $VBoxContainer/FactButton1/FactLabel
@onready var fact_label_2: Label = $VBoxContainer/FactButton2/FactLabel
@onready var fact_label_3: Label = $VBoxContainer/FactButton3/FactLabel
@onready var title_label = $TitleLabel
@onready var result_label = $ResultLabel

var current_facts: Array = [] # Array of { "fact": String, "is_fun": bool }
var used_fun_facts: Array = []
var used_boring_facts: Array = []

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	fact_button_1.pressed.connect(_on_fact_chosen.bind(0))
	fact_button_2.pressed.connect(_on_fact_chosen.bind(1))
	fact_button_3.pressed.connect(_on_fact_chosen.bind(2))

func start_minigame():
	visible = true
	result_label.text = ""
	_reset_eval_style(result_label)
	title_label.text = "Pick the most interesting fun fact!"
	
	get_tree().paused = true
	
	_generate_choices()
	
	var buttons = [fact_button_1, fact_button_2, fact_button_3]
	var labels = [fact_label_1, fact_label_2, fact_label_3]
	for i in range(3):
		buttons[i].texture_normal = FACT_OPTION_TEXTURE
		buttons[i].texture_hover = FACT_OPTION_SELECTED_TEXTURE
		buttons[i].texture_pressed = FACT_OPTION_SELECTED_TEXTURE
		buttons[i].modulate = Color.WHITE
		buttons[i].disabled = false
		labels[i].modulate = Color.WHITE
		labels[i].text = current_facts[i]["fact"]
		_fit_fact_label(labels[i], labels[i].text)
		_reset_eval_style(labels[i])

func _get_unused_fun_fact() -> String:
	# Reset pool if exhausted
	if used_fun_facts.size() >= fun_facts.size():
		used_fun_facts.clear()
	
	var available = []
	for f in fun_facts:
		if f not in used_fun_facts:
			available.append(f)
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var pick = available[rng.randi() % available.size()]
	used_fun_facts.append(pick)
	return pick

func _get_unused_boring_fact() -> String:
	if used_boring_facts.size() >= boring_facts.size():
		used_boring_facts.clear()
	
	var available = []
	for f in boring_facts:
		if f not in used_boring_facts:
			available.append(f)
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var pick = available[rng.randi() % available.size()]
	used_boring_facts.append(pick)
	return pick

func _generate_choices():
	current_facts.clear()
	
	# 1 fun fact, 2 boring facts
	var fun_one = { "fact": _get_unused_fun_fact(), "is_fun": true }
	var boring_one = { "fact": _get_unused_boring_fact(), "is_fun": false }
	var boring_two = { "fact": _get_unused_boring_fact(), "is_fun": false }
	
	current_facts = [fun_one, boring_one, boring_two]
	
	# Shuffle the array so the fun fact isn't always first
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(current_facts.size() - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var temp = current_facts[i]
		current_facts[i] = current_facts[j]
		current_facts[j] = temp

func _on_fact_chosen(index: int):
	var chosen = current_facts[index]
	var success = chosen["is_fun"]
	
	# Disable all buttons
	fact_button_1.disabled = true
	fact_button_2.disabled = true
	fact_button_3.disabled = true
	
	# Highlight the correct answer
	var buttons = [fact_button_1, fact_button_2, fact_button_3]
	var labels = [fact_label_1, fact_label_2, fact_label_3]
	for i in range(3):
		if current_facts[i]["is_fun"]:
			buttons[i].texture_normal = FACT_OPTION_SELECTED_TEXTURE
			_set_eval_style(labels[i], EVAL_GREEN)
		else:
			buttons[i].modulate = Color(0.55, 0.55, 0.55)
			labels[i].add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))

	if success:
		result_label.text = "Great pick! Students are engaged! (+15% Focus)"
		_set_eval_style(result_label, EVAL_GREEN)
	else:
		result_label.text = "That was boring... Students lost interest. (-10% Focus)"
		_set_eval_style(result_label, EVAL_RED)
	
	# Wait then close
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(_on_result_timeout.bind(success))

func _on_result_timeout(success: bool):
	# Reset button colors
	var buttons = [fact_button_1, fact_button_2, fact_button_3]
	var labels = [fact_label_1, fact_label_2, fact_label_3]
	for i in range(3):
		buttons[i].texture_normal = FACT_OPTION_TEXTURE
		buttons[i].modulate = Color.WHITE
		_reset_eval_style(labels[i])
	
	visible = false
	get_tree().paused = false
	funfact_finished.emit(success)

func _fit_fact_label(label: Label, text: String):
	var font_size := 15
	if text.length() > 118:
		font_size = 10
	elif text.length() > 105:
		font_size = 11
	elif text.length() > 82:
		font_size = 12
	elif text.length() > 62:
		font_size = 13
	elif text.length() > 46:
		font_size = 14
	
	label.add_theme_font_size_override("font_size", font_size)
