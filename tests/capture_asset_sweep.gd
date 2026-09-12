extends Node

const PLAYER := preload("res://scenes/player/player.tscn")
const OUTPUT := "res://build/asset-sweep"
const VIEWS := {
	"intro": [900.0, 1540.0],
	"ground": [420.0, 1080.0, 1800.0, 2520.0, 3240.0, 3960.0, 4680.0, 5400.0, 6120.0, 6800.0],
	"upper": [500.0, 1500.0, 2500.0, 3500.0, 4500.0, 5500.0, 6500.0],
	"basement": [500.0, 1400.0, 2600.0, 3700.0, 4800.0, 5800.0, 6800.0],
	"roots": [600.0, 1500.0, 2500.0, 3500.0, 4600.0, 5600.0],
	"echoes": [600.0, 1700.0, 2750.0, 3850.0, 5000.0],
	"nexus": [900.0]
}

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	AudioServer.set_bus_mute(0, true)
	_capture_all.call_deferred()

func _capture_all() -> void:
	for zone in VIEWS:
		FreedomLedger.reset()
		if zone in ["roots", "echoes", "nexus"]:
			FreedomLedger.restore_sense("hearing")
			FreedomLedger.begin_part_two("vantree")
		GameManager.zone = zone
		GameManager.state = GameManager.State.PLAYING
		var room: Node2D = load("res://scenes/levels/" + zone + "_floor.tscn").instantiate()
		add_child(room)
		var player: CharacterBody2D = PLAYER.instantiate()
		room.add_child(player)
		var camera: Camera2D = player.get_node("Camera2D")
		camera.limit_left = 0
		camera.limit_right = int(room.room_width)
		camera.limit_top = 0
		camera.limit_bottom = 720
		camera.position_smoothing_enabled = false
		camera.make_current()
		for index in VIEWS[zone].size():
			var focus_x: float = float(VIEWS[zone][index])
			player.position = Vector2(focus_x, 610.0)
			camera.snap_to_player()
			camera.force_update_scroll()
			await get_tree().process_frame
			await get_tree().process_frame
			camera.snap_to_player()
			camera.force_update_scroll()
			await RenderingServer.frame_post_draw
			var image := get_viewport().get_texture().get_image()
			var path: String = OUTPUT + "/%s_%02d_%04d.png" % [zone, index, int(focus_x)]
			if image.save_png(path) != OK:
				push_error("Could not save " + path)
		room.queue_free()
		await get_tree().process_frame
	print("ASSET SWEEP CAPTURED: " + str(VIEWS.keys()))
	get_tree().quit()
