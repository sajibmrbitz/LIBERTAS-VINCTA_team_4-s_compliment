extends Node
enum State { INTRO, PLAYING, PAUSED, READING, CAUGHT, ENDING, MENU }
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
	var error := get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")
	if error != OK:
		push_error("Could not open loading screen (error %s)." % error)
		go_home()

func go_home() -> void:
	get_tree().paused = false
	FreedomLedger.reset()
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

func travel(destination: String, entrance: String = "start") -> void:
	get_tree().paused = false
	zone = destination
	entry = entrance
	arrival_pending = true
	state = State.PLAYING
	# A room transition is also a safe checkpoint. Main supplies its spawn position.
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
	ending = kind
	state = State.ENDING

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
