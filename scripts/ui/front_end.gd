extends "res://scripts/ui/menu_navigation.gd"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_navigation($BackgroundRoot/PageContent)
	var menu = add_page("menu", preload("res://scenes/ui/main_menu.tscn"))
	menu.selected.connect(select)
	var scenes := {
		"story": preload("res://scenes/ui/story_page.tscn"),
		"controls": preload("res://scenes/ui/controls_page.tscn"),
		"settings": preload("res://scenes/ui/settings_page.tscn"),
		"credits": preload("res://scenes/ui/credits_page.tscn")
	}
	for id in scenes:
		var page = add_page(id, scenes[id])
		page.back_requested.connect(func(): navigate("menu"))
	show_initial()

func select(destination: String) -> void:
	match destination:
		"start": leave_to(GameManager.new_game)
		"continue": leave_to(GameManager.continue_game)
		"quit":
			if not OS.has_feature("web"):
				leave_to(get_tree().quit)
		_: navigate(destination)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		if current_id != "menu":
			EventBus.audio_requested.emit("ui_back")
			navigate("menu")
		get_viewport().set_input_as_handled()
