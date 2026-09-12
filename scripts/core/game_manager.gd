extends Node

enum State { INTRO, PLAYING, PAUSED, READING, CAUGHT, ENDING, MENU }
const SAVE_PATH := "user://libertas_vincta_save.json"

var state: State = State.MENU
var zone: String = "intro"
var entry: String = "start"
var checkpoint: Dictionary = {}
var ending: String = ""
var return_state: State = State.PLAYING
var arrival_pending: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.player_caught.connect(caught)
	EventBus.ending_triggered.connect(finish)

func new_game() -> void:
	get_tree().paused = false
	FreedomLedger.reset()
	zone = "intro"
	entry = "start"
	checkpoint.clear()
	ending = ""
	arrival_pending = false
	state = State.INTRO
	return_state = State.PLAYING
	_load_game_scene()

func go_home() -> void:
	get_tree().paused = false
	checkpoint.clear()
	zone = "intro"
	entry = "start"
	ending = ""
	arrival_pending = false
	return_state = State.PLAYING
	state = State.MENU
	get_tree().change_scene_to_file("res://scenes/ui/front_end.tscn")

func save_checkpoint(position: Vector2) -> void:
	checkpoint = {"zone": zone, "position": position, "ledger": FreedomLedger.snapshot()}
	var serializable := checkpoint.duplicate(true)
	serializable.position = [position.x, position.y]
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(serializable, "  "))

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func continue_game() -> void:
	if not has_save():
		new_game()
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or not data.has("ledger"):
		new_game()
		return
	FreedomLedger.restore_snapshot(data.ledger)
	zone = str(data.get("zone", "ground"))
	var p: Array = data.get("position", [240.0, 490.0])
	checkpoint = {"zone": zone, "position": Vector2(float(p[0]), float(p[1])), "ledger": FreedomLedger.snapshot()}
	entry = "checkpoint"
	arrival_pending = false
	ending = ""
	state = State.PLAYING
	_load_game_scene()

func travel(destination: String, entrance: String = "start") -> void:
	get_tree().paused = false
	zone = destination
	entry = entrance
	arrival_pending = true
	state = State.PLAYING
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func restart_checkpoint() -> void:
	get_tree().paused = false
	if checkpoint.is_empty():
		new_game()
		return
	FreedomLedger.restore_snapshot(checkpoint.ledger)
	zone = checkpoint.zone
	entry = "checkpoint"
	arrival_pending = false
	ending = ""
	state = State.PLAYING
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func caught() -> void:
	if state != State.PLAYING:
		return
	state = State.CAUGHT
	EventBus.audio_requested.emit("monster_breathing")
	await get_tree().create_timer(1.2, false).timeout
	restart_checkpoint()

func finish(kind: String) -> void:
	if state != State.PLAYING or not FreedomLedger.eligible(kind):
		return
	if kind == "loop":
		_trigger_loop()
		return
	ending = kind
	FreedomLedger.ending_type = kind
	state = State.ENDING

func continue_to_part_two() -> void:
	if ending not in ["untouched", "vantree", "partial_mercy"]:
		return
	FreedomLedger.begin_part_two(ending)
	EventBus.part_two_started.emit(FreedomLedger.part2_seed)
	ending = ""
	state = State.PLAYING
	zone = "roots"
	entry = "start"
	arrival_pending = false
	checkpoint.clear()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _trigger_loop() -> void:
	state = State.INTRO
	FreedomLedger.reset_for_loop()
	EventBus.loop_started.emit(FreedomLedger.loop_counter)
	zone = "ground"
	entry = "start"
	ending = ""
	checkpoint.clear()
	arrival_pending = false
	await get_tree().create_timer(0.35, false).timeout
	state = State.PLAYING
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func pause_game() -> void:
	if state not in [State.PLAYING, State.INTRO]:
		return
	return_state = state
	state = State.PAUSED
	get_tree().paused = true

func resume() -> void:
	get_tree().paused = false
	state = return_state

func read_letter() -> void:
	return_state = state
	state = State.READING
	get_tree().paused = true

func _load_game_scene() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")
	if error != OK:
		push_error("Could not open loading screen (error %s)." % error)
		go_home()
