extends Node2D
# Keep the foyer resource with Main; other rooms retain their existing flow.
const INTRO_ROOM := preload("res://scenes/levels/intro_floor.tscn")
const ENEMY := preload("res://scenes/enemy/deprived_one.tscn")
var room: Node2D

func _ready() -> void:
	var packed: PackedScene = INTRO_ROOM if GameManager.zone == "intro" else load("res://scenes/levels/" + GameManager.zone + "_floor.tscn")
	room = packed.instantiate()
	$World.add_child(room)
	var player := $Entities/Player
	var spawn: Vector2 = room.get_node("Markers/ReturnSpawn" if GameManager.entry == "end" else "Markers/PlayerSpawn").global_position
	if GameManager.entry == "checkpoint" and not GameManager.checkpoint.is_empty():
		spawn = GameManager.checkpoint.position
	player.global_position = spawn
	var camera := player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_right = int(room.room_width)
	camera.limit_top = 0
	camera.limit_bottom = 800
	camera.snap_to_player()
	if GameManager.zone == "intro":
		$Awakening.begin(player, $UI)
	else:
		GameManager.state = GameManager.State.PLAYING
		GameManager.save_checkpoint(spawn)
		if FreedomLedger.flags.get("flashlight", false):
			player.set_flashlight(false)
		var enemy := ENEMY.instantiate()
		var enemy_spawn: Vector2 = room.get_node("Markers/EnemySpawn").global_position
		if enemy_spawn.distance_to(spawn) < 650.0:
			enemy_spawn.x = spawn.x + 850.0 if spawn.x < room.room_width - 1000 else spawn.x - 850.0
			enemy_spawn = room.grid.get_point_position(room.nearest_cell(enemy_spawn))
		enemy.position = enemy_spawn
		$Entities.add_child(enemy)
