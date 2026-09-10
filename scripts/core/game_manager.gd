extends Node
enum State { INTRO, PLAYING, PAUSED, READING, CAUGHT, ENDING }
var state: State = State.INTRO
var zone: String = "intro"
var entry: String = "start"
var checkpoint: Dictionary = {}
var ending: String = ""
var return_state: State = State.PLAYING

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
	state = State.INTRO
	get_tree().reload_current_scene()

func save_checkpoint(position: Vector2) -> void:
	checkpoint = {"zone": zone, "position": position, "ledger": FreedomLedger.snapshot()}

func travel(destination: String, entrance: String = "start") -> void:
	get_tree().paused = false
	zone = destination
	entry = entrance
	state = State.PLAYING
	# A room transition is also a safe checkpoint. Main supplies its spawn position.
	get_tree().reload_current_scene()

func restart_checkpoint() -> void:
	get_tree().paused = false
	if checkpoint.is_empty():
		new_game()
		return
	FreedomLedger.restore_snapshot(checkpoint.ledger)
	zone = checkpoint.zone
	entry = "checkpoint"
	ending = ""
	state = State.PLAYING
	get_tree().reload_current_scene()

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
