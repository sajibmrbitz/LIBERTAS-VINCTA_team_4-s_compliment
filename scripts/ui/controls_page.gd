extends "res://scripts/ui/menu_page.gd"

func _ready() -> void:
	build_page("CONTROLS")
	var grid := GridContainer.new()
	grid.columns = 2
	content.add_child(grid)
	var rows := {
		"MOVE": ["move_left", "move_right"],
		"ROOM DEPTH": ["move_up", "move_down"],
		"SPRINT": ["sprint"], "CROUCH": ["crouch"],
		"INTERACT": ["interact"], "FLASHLIGHT": ["flashlight"], "PAUSE": ["pause"]
	}
	for action in rows:
		var heading := make_label(action, "Small")
		heading.custom_minimum_size.x = 155
		grid.add_child(heading)
		var binding := make_label(bindings_for(rows[action]))
		binding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(binding)
	content.add_child(make_label("Hold Sprint or Crouch while moving. Interact also leaves a hiding place. Flashlight requires its pickup.", "Small"))

func bindings_for(actions: Array) -> String:
	var names: PackedStringArray = []
	for action in actions:
		if not InputMap.has_action(action):
			continue
		for event in InputMap.action_get_events(action):
			var binding: String = event.as_text()
			if event is InputEventKey:
				binding = OS.get_keycode_string(event.get_physical_keycode_with_modifiers() if event.physical_keycode != 0 else event.get_keycode_with_modifiers())
			if not names.has(binding):
				names.append(binding)
	return " / ".join(names) if not names.is_empty() else "Unbound"
