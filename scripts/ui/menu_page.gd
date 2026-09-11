extends Control
## Shared page layout. Content scrolls independently; Back stays reachable.
signal back_requested
const MENU_BUTTON = preload("res://scenes/ui/components/menu_button.tscn")
var content: VBoxContainer
var back_button: Button
var initial_focus: Control
var scroll: ScrollContainer

func build_page(title: String) -> void:
	var layout := VBoxContainer.new()
	layout.name = "PageLayout"
	add_child(layout)
	layout.anchor_left = 0.09
	layout.anchor_right = 0.56
	layout.anchor_top = 0.12
	layout.anchor_bottom = 0.92
	var heading := make_label(title, "PageTitle")
	layout.add_child(heading)
	layout.add_child(HSeparator.new())
	scroll = ScrollContainer.new()
	scroll.name = "ContentScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	layout.add_child(scroll)
	content = VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	back_button = MENU_BUTTON.instantiate()
	back_button.caption = "BACK"
	back_button.sound_cue = "ui_back"
	layout.add_child(back_button)
	back_button.pressed.connect(func(): back_requested.emit())
	initial_focus = back_button

func make_label(copy: String, variation: String = "Label") -> Label:
	var label := Label.new()
	label.text = copy
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func focus_default() -> void:
	scroll.scroll_vertical = 0
	initial_focus.grab_focus()
