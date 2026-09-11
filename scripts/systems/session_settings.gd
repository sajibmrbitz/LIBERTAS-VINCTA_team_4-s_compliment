extends Node
var volumes: Dictionary = {"Master": 0.8, "Music": 0.7, "Ambience": 0.8, "SFX": 0.8}
var fullscreen: bool = false
var subtitles_enabled: bool = true

func _ready() -> void:
	for bus in volumes:
		set_volume(bus, volumes[bus])

func set_volume(bus: String, value: float) -> void:
	volumes[bus] = value
	var index := AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.001)))
		AudioServer.set_bus_mute(index, value <= 0.0)

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)

func set_subtitles(enabled: bool) -> void:
	subtitles_enabled = enabled
