extends Control
signal selected(destination: String)
const MENU_BUTTON = preload("res://scenes/ui/components/menu_button.tscn")
@export var pause_context: bool = false
@export var logo_texture: Texture2D
var first_button: Button

func _ready() -> void:
	var heading := VBoxContainer.new()
	heading.name = "TitleBlock"
	add_child(heading)
	heading.anchor_left = 0.09
	heading.anchor_right = 0.85
	heading.anchor_top = 0.19
	var title := Label.new()
	title.text = "LIBERTAS VINCTA"
	title.theme_type_variation = "GameTitle"
	heading.add_child(title)
	var logo := TextureRect.new()
	logo.name = "LogoTexture"
	logo.texture = logo_texture
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(0, 80)
	logo.visible = logo_texture != null
	heading.add_child(logo)
	title.visible = logo_texture == null
	var tagline := Label.new()
	tagline.text = "PAUSED" if pause_context else "SOME FREEDOMS SHOULD STAY LOST"
	tagline.theme_type_variation = "Small"
	heading.add_child(tagline)
	var navigation := VBoxContainer.new()
	navigation.name = "Navigation"
	add_child(navigation)
	navigation.anchor_left = 0.09
	navigation.anchor_right = 0.39
	navigation.anchor_top = 0.43
	navigation.add_theme_constant_override("separation", 10)
	var choices := {"START GAME": "start", "STORY": "story", "CONTROLS": "controls", "SETTINGS": "settings", "CREDITS": "credits", "QUIT": "quit"}
	if not pause_context and GameManager.has_save():
		choices = {"CONTINUE": "continue", "START GAME": "start", "STORY": "story", "CONTROLS": "controls", "SETTINGS": "settings", "CREDITS": "credits", "QUIT": "quit"}
	if pause_context:
		choices = {"RESUME": "resume", "SETTINGS": "settings", "CONTROLS": "controls", "RESTART": "restart", "MAIN MENU": "home"}
	for caption in choices:
		if caption == "QUIT" and OS.has_feature("web"):
			continue
		var button = MENU_BUTTON.instantiate()
		button.caption = caption
		navigation.add_child(button)
		button.pressed.connect(func(): selected.emit(choices[caption]))
		if first_button == null:
			first_button = button
	var buttons := navigation.get_children()
	for index in range(buttons.size()):
		var button: Control = buttons[index]
		button.focus_neighbor_top = button.get_path_to(buttons[(index - 1 + buttons.size()) % buttons.size()])
		button.focus_neighbor_bottom = button.get_path_to(buttons[(index + 1) % buttons.size()])
		button.focus_previous = button.focus_neighbor_top
		button.focus_next = button.focus_neighbor_bottom
	var footer := Label.new()
	footer.text = "TEAM 4'S COMPLIMENT"
	footer.theme_type_variation = "Small"
	add_child(footer)
	footer.anchor_left = 0.09
	footer.anchor_top = 0.93

func focus_default() -> void:
	first_button.grab_focus()
