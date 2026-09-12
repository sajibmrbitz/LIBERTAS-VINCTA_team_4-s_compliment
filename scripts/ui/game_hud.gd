extends CanvasLayer
## Minimal runtime UI with a replaceable Theme; gameplay never depends on UI art.
@export var ui_theme: Theme = preload("res://themes/libertas_ui_theme.tres")
var pause_menu: Control
var root: Control
var senses: Label
var prompt: Label
var subtitle: Label
var fade: ColorRect
var pulse: ColorRect
var modal: PanelContainer
var modal_box: VBoxContainer
var subtitle_queue: Array[Dictionary] = []
var subtitle_time: float = 0.0
var modal_mode: String = ""
var ending_shown: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("hud")
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = ui_theme
	add_child(root)
	senses = make_label("", 16)
	senses.position = Vector2(28, 22)
	root.add_child(senses)
	prompt = make_label("[E]", 19)
	root.add_child(prompt)
	subtitle = make_label("", 22)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	subtitle.offset_left = 100
	subtitle.offset_right = -100
	subtitle.offset_top = -118
	subtitle.offset_bottom = -36
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(subtitle)
	pulse = ColorRect.new()
	pulse.color = Color(0.45, 0.52, 0.56, 0.0)
	pulse.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(pulse)
	fade = ColorRect.new()
	fade.color = Color(0.015, 0.018, 0.024, 0.0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)
	modal = PanelContainer.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	modal.offset_left = -270
	modal.offset_right = 270
	modal.offset_top = -250
	modal.offset_bottom = 250
	root.add_child(modal)
	modal_box = VBoxContainer.new()
	modal_box.add_theme_constant_override("separation", 14)
	modal.add_child(modal_box)
	modal.hide()
	pause_menu = preload("res://scenes/ui/pause_menu.tscn").instantiate()
	root.add_child(pause_menu)
	EventBus.subtitle_requested.connect(enqueue_subtitle)
	EventBus.sense_restored.connect(transaction)
	EventBus.player_caught.connect(func(): create_tween().tween_property(fade, "color:a", 1.0, 1.0))

func make_label(text: String, size: int = 18) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.85, 0.87, 0.86))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _process(delta: float) -> void:
	subtitle.visible = SessionSettings.subtitles_enabled
	senses.visible = GameManager.zone != "intro" and GameManager.state != GameManager.State.ENDING
	senses.text = "  /  ".join(["Hearing " + status("hearing"), "Sight " + status("sight"), "Memory " + status("memory")])
	var player = get_tree().get_first_node_in_group("player")
	prompt.visible = false
	if player != null and GameManager.state == GameManager.State.PLAYING:
		prompt.visible = is_instance_valid(player.target_interactable) or player.hidden_spot != null
		var target: Node2D = player.hidden_spot if player.hidden_spot != null else player.target_interactable
		prompt.text = "[E]"
		if is_instance_valid(target) and not target.display_name.is_empty():
			prompt.text += " " + target.display_name
		prompt.size = prompt.get_minimum_size()
		var point: Vector2 = player.get_global_transform_with_canvas().origin
		prompt.position = Vector2(clampf(point.x - prompt.size.x * 0.5, 12, root.size.x - prompt.size.x - 12), point.y - 98)
	if not get_tree().paused:
		subtitle_time -= delta
		if subtitle_time <= 0.0:
			if not subtitle_queue.is_empty():
				var item: Dictionary = subtitle_queue.pop_front()
				subtitle.text = (item.speaker + "\n" if not item.speaker.is_empty() else "") + item.text
				subtitle_time = item.duration
			else:
				subtitle.text = ""
	if GameManager.state == GameManager.State.ENDING and not ending_shown:
		ending_shown = true
		show_ending()

func status(sense: String) -> String:
	return "restored" if sense in FreedomLedger.keys_collected else "sealed"

func enqueue_subtitle(speaker: String, text: String, duration: float) -> void:
	subtitle_queue.append({"speaker": speaker, "text": text, "duration": duration})

func transaction(_sense: String) -> void:
	pulse.color.a = 0.16
	create_tween().tween_property(pulse, "color:a", 0.0, 0.65)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameManager.state == GameManager.State.READING:
			close_modal()
		elif GameManager.state == GameManager.State.PAUSED:
			pause_menu.back()
		elif GameManager.state in [GameManager.State.PLAYING, GameManager.State.INTRO]:
			GameManager.pause_game()
			show_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and GameManager.state == GameManager.State.READING:
		close_modal()
		get_viewport().set_input_as_handled()

func clear_modal(title: String) -> void:
	for child in modal_box.get_children():
		modal_box.remove_child(child)
		child.queue_free()
	var heading := make_label(title, 25)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_box.add_child(heading)
	modal.show()

func button(text: String, callback: Callable) -> Button:
	var control = preload("res://scenes/ui/components/menu_button.tscn").instantiate()
	control.caption = text
	control.custom_minimum_size.y = 38
	control.pressed.connect(callback)
	modal_box.add_child(control)
	return control

func show_pause() -> void:
	pause_menu.open()

func show_letter(title: String, text: String) -> void:
	GameManager.read_letter()
	clear_modal(title)
	modal_mode = "letter"
	
	var content := make_label(text.replace("\\n", "\n"), 20)
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_box.add_child(content)
	button("Close [E / Esc]", close_modal).grab_focus()

func close_modal() -> void:
	modal.hide()
	GameManager.resume()

func show_ending() -> void:
	fade.color.a = 0.88
	var titles := {"full_awakening": "FULL AWAKENING", "partial_mercy": "PARTIAL MERCY", "vantree": "VANTREE"}
	var texts := {
		"full_awakening": "The front door opens.\nBehind Els, nothing remains deprived.\n\nShe steps out. The house listens.",
		"partial_mercy": "Cold water gives way to open air.\nTwo seals broken. One still holding.\n\nEls leaves the last key behind.",
		"vantree": "Els closes the ledger.\nThe Vantree seal holds.\n\nFor now, she chooses to remain its custodian."
	}
	clear_modal(titles.get(GameManager.ending, "LIBERTAS VINCTA"))
	var content := make_label(texts.get(GameManager.ending, ""), 20)
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_box.add_child(content)
	button("New game", GameManager.new_game).grab_focus()
	button("Quit", func(): get_tree().quit())
