extends CanvasLayer
## Runtime status, reading, pause, transition, and ending presentation.

@export var ui_theme: Theme = preload("res://themes/libertas_ui_theme.tres")
var pause_menu: Control
var root: Control
var senses: Label
var vitals: Label
var room_name: Label
var prompt: Label
var subtitle: Label
var anchor_status: Label
var fade: ColorRect
var pulse: ColorRect
var peripheral: Array[ColorRect] = []
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
	vitals = make_label("", 15)
	vitals.position = Vector2(28, 50)
	root.add_child(vitals)
	room_name = make_label("", 15)
	room_name.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	room_name.offset_left = -330
	room_name.offset_right = -28
	room_name.offset_top = 22
	room_name.offset_bottom = 46
	room_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(room_name)
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
	anchor_status = make_label("", 17)
	anchor_status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	anchor_status.offset_left = -160
	anchor_status.offset_right = 160
	anchor_status.offset_top = 72
	anchor_status.offset_bottom = 100
	anchor_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(anchor_status)
	_build_peripheral()
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
	EventBus.anchor_progress.connect(_anchor_progress)
	EventBus.anchor_cleansed.connect(func(_id, _total): anchor_status.text = "")

func _build_peripheral() -> void:
	var specs := [
		[0.0, 0.0, 1.0, 0.12], [0.0, 0.88, 1.0, 1.0],
		[0.0, 0.12, 0.08, 0.88], [0.92, 0.12, 1.0, 0.88]
	]
	for spec in specs:
		var edge := ColorRect.new()
		edge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		edge.anchor_left = spec[0]
		edge.anchor_top = spec[1]
		edge.anchor_right = spec[2]
		edge.anchor_bottom = spec[3]
		edge.color = Color(0.03, 0.04, 0.045, 0.0)
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(edge)
		peripheral.append(edge)

func make_label(text: String, size: int = 18) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.85, 0.87, 0.86))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _process(delta: float) -> void:
	_layout_for_viewport()
	subtitle.visible = SessionSettings.subtitles_enabled
	var playing_hud := GameManager.zone != "intro" and GameManager.state != GameManager.State.ENDING
	senses.visible = playing_hud
	vitals.visible = playing_hud
	room_name.visible = playing_hud
	senses.text = "  /  ".join(["Hearing " + status("hearing"), "Sight " + status("sight"), "Memory " + status("memory")])
	vitals.text = "Charge %02d  |  HP %03d  |  B %d  G %d  C %d" % [
		ceili(FreedomLedger.flashlight_seconds), ceili(FreedomLedger.hp),
		int(FreedomLedger.inventory.get("battery", 0)), int(FreedomLedger.inventory.get("bottle", 0)), int(FreedomLedger.inventory.get("clock", 0))]
	var room = get_tree().get_first_node_in_group("room")
	room_name.text = room.current_room_id if room != null else ""
	var player = get_tree().get_first_node_in_group("player")
	prompt.visible = false
	if player != null:
		var strain := clampf((player.breath_seconds - 4.0) / 2.0, 0.0, 1.0) if player.holding_breath else 0.0
		for edge in peripheral:
			edge.color.a = strain * 0.62
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

func _layout_for_viewport() -> void:
	var narrow := root.size.x < 900.0
	room_name.offset_top = 78.0 if narrow else 22.0
	room_name.offset_bottom = room_name.offset_top + 24.0
	var half_width := minf(270.0, root.size.x * 0.46)
	var half_height := minf(250.0, maxf(150.0, root.size.y * 0.46))
	modal.offset_left = -half_width
	modal.offset_right = half_width
	modal.offset_top = -half_height
	modal.offset_bottom = half_height

func status(sense: String) -> String:
	return "restored" if sense in FreedomLedger.keys_collected else "sealed"

func enqueue_subtitle(speaker: String, text: String, duration: float) -> void:
	subtitle_queue.append({"speaker": speaker, "text": text, "duration": duration})

func transaction(_sense: String) -> void:
	pulse.color.a = 0.16
	create_tween().tween_property(pulse, "color:a", 0.0, 0.65)

func _anchor_progress(id: String, seconds: float, required: float) -> void:
	anchor_status.text = "%s  %02d / %02d" % [id, floori(seconds), floori(required)] if seconds > 0.0 else ""

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
	var titles := {
		"untouched": "UNTOUCHED", "partial_mercy": "PARTIAL MERCY", "vantree": "VANTREE",
		"severance": "SEVERANCE", "custodian_rest": "CUSTODIAN'S REST", "vessel": "VESSEL"
	}
	var texts := {
		"untouched": "The front door opens before the house learns her shape.\nEvery stolen sense remains sealed.",
		"partial_mercy": "Cold water gives way to older stone.\nTwo seals broken. One left dormant.",
		"vantree": "The conduit recognizes her name.\nBlood and stone carry it downward.",
		"severance": "The last bond breaks. The Deprived One is gone.",
		"custodian_rest": "Els takes the empty place and becomes the living ward.",
		"vessel": "The prison closes around a new key. An unseen hand carries it away."
	}
	clear_modal(titles.get(GameManager.ending, "LIBERTAS VINCTA"))
	var closing := ""
	if GameManager.ending in ["severance", "custodian_rest", "vessel"]:
		closing = "\n\nFreedom was never lost in this house.\nIt was only ever moved from one hand to another.\n\nThe only question was ever whose hand was empty\nwhen the counting stopped."
	var content := make_label(texts.get(GameManager.ending, "") + closing, 20)
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_box.add_child(content)
	if GameManager.ending in ["untouched", "partial_mercy", "vantree"]:
		button("Descend", GameManager.continue_to_part_two).grab_focus()
	else:
		button("New game", GameManager.new_game).grab_focus()
		button("Main menu", GameManager.go_home)
