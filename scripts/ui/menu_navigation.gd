extends Control
## One navigation mechanism for front-end and paused gameplay. No scene reloads between pages.
var pages: Dictionary = {}
var current: Control
var current_id: String = ""
var busy: bool = false
var overlay: ColorRect
var page_root: Control

func setup_navigation(host: Control) -> void:
	page_root = host
	overlay = ColorRect.new()
	overlay.name = "TransitionOverlay"
	overlay.color = Color.BLACK
	overlay.modulate.a = 0.0
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.hide()

func add_page(id: String, packed: PackedScene, pause_context: bool = false) -> Control:
	var page: Control = packed.instantiate()
	if id == "menu":
		page.pause_context = pause_context
	page.hide()
	page.process_mode = Node.PROCESS_MODE_DISABLED
	page_root.add_child(page)
	pages[id] = page
	return page

func show_initial() -> void:
	if current != null:
		current.hide()
		current.process_mode = Node.PROCESS_MODE_DISABLED
	current = pages["menu"]
	current_id = "menu"
	current.modulate.a = 1.0
	current.process_mode = Node.PROCESS_MODE_INHERIT
	current.show()
	current.focus_default.call_deferred()

func navigate(id: String) -> void:
	if busy or id == current_id:
		return
	busy = true
	lock_input()
	var next: Control = pages[id]
	next.modulate.a = 0.0
	next.show()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(current, "modulate:a", 0.0, 0.20)
	tween.tween_property(next, "modulate:a", 1.0, 0.20)
	await tween.finished
	current.hide()
	current = next
	current_id = id
	current.process_mode = Node.PROCESS_MODE_INHERIT
	overlay.hide()
	busy = false
	current.focus_default()

func lock_input() -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null:
		focus.release_focus()
	current.process_mode = Node.PROCESS_MODE_DISABLED
	overlay.show()

func leave_to(callback: Callable) -> void:
	if busy:
		return
	busy = true
	lock_input()
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.32)
	await tween.finished
	callback.call()

func _input(_event: InputEvent) -> void:
	if busy:
		get_viewport().set_input_as_handled()
