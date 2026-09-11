extends "res://scripts/ui/menu_navigation.gd"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_navigation($PageContent)
	var menu = add_page("menu", preload("res://scenes/ui/main_menu.tscn"), true)
	menu.selected.connect(select)
	for id in ["settings", "controls"]:
		var packed: PackedScene = load("res://scenes/ui/" + id + "_page.tscn")
		var page = add_page(id, packed)
		page.back_requested.connect(func(): navigate("menu"))
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED

func open() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	show()
	show_initial()

func back() -> void:
	if busy:
		return
	EventBus.audio_requested.emit("ui_back")
	if current_id == "menu":
		resume_game()
	else:
		navigate("menu")

func resume_game() -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null:
		focus.release_focus()
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED
	GameManager.resume()

func select(destination: String) -> void:
	match destination:
		"resume": resume_game()
		"restart": leave_to(GameManager.restart_checkpoint)
		"home": leave_to(GameManager.go_home)
		_: navigate(destination)
