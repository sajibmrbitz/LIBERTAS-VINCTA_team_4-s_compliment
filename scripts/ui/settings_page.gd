extends "res://scripts/ui/menu_page.gd"
var sliders: Dictionary = {}
var fullscreen_toggle: CheckButton
var subtitles_toggle: CheckButton

func _ready() -> void:
	build_page("SETTINGS")
	content.add_child(make_label("AUDIO", "Small"))
	for bus in ["Master", "Music", "SFX", "Ambience"]:
		if AudioServer.get_bus_index(bus) < 0:
			continue
		var row := HBoxContainer.new()
		content.add_child(row)
		var label := make_label(bus.to_upper(), "Small")
		label.custom_minimum_size.x = 115
		row.add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.custom_minimum_size = Vector2(100, 28)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value = SessionSettings.volumes.get(bus, 1.0)
		row.add_child(slider)
		var value_label := make_label(str(roundi(slider.value * 100)) + "%", "Small")
		value_label.custom_minimum_size.x = 48
		row.add_child(value_label)
		slider.value_changed.connect(func(value: float):
			SessionSettings.set_volume(bus, value)
			value_label.text = str(roundi(value * 100)) + "%")
		sliders[bus] = slider
		if bus == "Master":
			initial_focus = slider
	content.add_child(make_label("DISPLAY", "Small"))
	fullscreen_toggle = CheckButton.new()
	fullscreen_toggle.text = "Fullscreen  /  OFF"
	fullscreen_toggle.toggled.connect(SessionSettings.set_fullscreen)
	fullscreen_toggle.toggled.connect(func(enabled: bool): fullscreen_toggle.text = "Fullscreen  /  " + ("ON" if enabled else "OFF"))
	content.add_child(fullscreen_toggle)
	content.add_child(make_label("ACCESSIBILITY", "Small"))
	subtitles_toggle = CheckButton.new()
	subtitles_toggle.text = "Subtitles  /  ON"
	subtitles_toggle.toggled.connect(SessionSettings.set_subtitles)
	subtitles_toggle.toggled.connect(func(enabled: bool): subtitles_toggle.text = "Subtitles  /  " + ("ON" if enabled else "OFF"))
	content.add_child(subtitles_toggle)
	content.add_child(make_label("Changes apply immediately for this session.", "Small"))

func focus_default() -> void:
	for bus in sliders:
		sliders[bus].value = SessionSettings.volumes[bus]
	var mode := DisplayServer.window_get_mode()
	fullscreen_toggle.set_pressed_no_signal(mode in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN])
	subtitles_toggle.set_pressed_no_signal(SessionSettings.subtitles_enabled)
	fullscreen_toggle.text = "Fullscreen  /  " + ("ON" if fullscreen_toggle.button_pressed else "OFF")
	subtitles_toggle.text = "Subtitles  /  " + ("ON" if subtitles_toggle.button_pressed else "OFF")
	super.focus_default()
