class_name BaseInteractable
extends Node2D
## One reusable interaction contract; scene presets provide the individual prop types.
@export_enum("door", "locked_door", "key", "letter", "flashlight", "tool", "hiding", "puzzle", "exit") var kind: String = "door"
@export var interaction_id: String = ""
@export var title: String = ""
@export var display_name: String = ""
@export_multiline var text: String = ""
@export var sense: String = ""
@export var required_flag: String = ""
@export var destination: String = ""
@export var entrance: String = "start"
@export var ending_type: String = "full_awakening"
@export var puzzle_steps: int = 3
@export var action_seconds: float = 0.9
var busy: bool = false
var progress: int = 0

func _ready() -> void:
	add_to_group("interactable")
	$Visual/PlaceholderVisual.visible = $Visual/Sprite2D.texture == null
	refresh()

func available() -> bool:
	if busy:
		return false
	if kind == "key":
		return sense not in FreedomLedger.keys_collected
	if kind == "letter":
		return interaction_id not in FreedomLedger.letter_ids
	if kind in ["flashlight", "tool", "puzzle"]:
		return not FreedomLedger.flags.get(interaction_id, false)
	return true

func refresh() -> void:
	visible = available() or kind in ["puzzle", "door", "locked_door", "hiding", "exit"]

func say(line: String, seconds: float = 2.0) -> void:
	EventBus.subtitle_requested.emit("ELS", line, seconds)

func interact(player: Node2D) -> void:
	if not available() or GameManager.state != GameManager.State.PLAYING:
		return
	busy = true
	EventBus.interaction_started.emit(self)
	var action := "interact"
	if kind in ["key", "letter"]:
		action = "pickup"
	elif kind == "tool":
		action = "interact"
	elif kind in ["locked_door", "door", "puzzle"]:
		action = "unlock"
	player.play_action(action, action_seconds if kind == "puzzle" else 1.0)
	match kind:
		"flashlight":
			FreedomLedger.flags[interaction_id] = true
			player.set_flashlight(true)
			say("Mine...", 1.8)
			say("How did it get over there?", 2.6)
		"tool":
			FreedomLedger.flags[interaction_id] = true
			say("At least I came prepared.")
		"letter":
			if FreedomLedger.collect_letter(interaction_id):
				var hud = get_tree().get_first_node_in_group("hud")
				hud.show_letter(title, text)
		"hiding":
			player.enter_hiding(self)
		"key":
			if not required_flag.is_empty() and not FreedomLedger.has_requirement(required_flag):
				say("The seal is still holding.")
			elif FreedomLedger.restore_sense(sense):
				say({"hearing": "Something heard that.", "sight": "It turned toward the light.", "memory": "It knows this place now."}[sense], 2.8)
				GameManager.save_checkpoint(player.global_position)
			else:
				say("Another seal holds this one.")
		"puzzle":
			if not required_flag.is_empty() and not FreedomLedger.has_requirement(required_flag):
				say("Not yet.")
			else:
				player.control_enabled = false
				EventBus.audio_requested.emit("lockpick")
				await get_tree().create_timer(action_seconds, false).timeout
				if GameManager.state == GameManager.State.PLAYING:
					player.control_enabled = true
					progress += 1
					EventBus.noise_created.emit(global_position, 0.55, "GENERIC")
					if progress >= puzzle_steps:
						FreedomLedger.flags[interaction_id] = true
						say("The seal gives.")
					else:
						say("Click. " + str(progress) + " of " + str(puzzle_steps) + ".", 1.1)
		"locked_door":
			if not FreedomLedger.flags.get("intro_door_tried", false):
				FreedomLedger.flags["intro_door_tried"] = true
				say("Locked.", 1.4)
				say("Of course.", 1.4)
			elif not FreedomLedger.flags.get("lockpick_tool", false):
				say("I need my tools.")
			elif not FreedomLedger.flags.get("flashlight", false):
				say("I should take my flashlight.")
			else:
				player.control_enabled = false
				EventBus.audio_requested.emit("lockpick")
				await get_tree().create_timer(1.2, false).timeout
				EventBus.audio_requested.emit("door")
				EventBus.audio_requested.emit("building_creak")
				player.get_node("Camera2D").cinematic_focus(global_position + Vector2(200, -70), 2.0)
				say("Hello?", 1.8)
				await get_tree().create_timer(2.0, false).timeout
				FreedomLedger.flags["intro_complete"] = true
				await _depart(player)
				GameManager.travel.call_deferred("ground")
		"door":
			if not required_flag.is_empty() and not FreedomLedger.has_requirement(required_flag):
				say(text if not text.is_empty() else "The passage is sealed.")
			else:
				await _depart(player)
				GameManager.travel.call_deferred(destination, entrance)
		"exit":
			if FreedomLedger.eligible(ending_type):
				await _depart(player)
				EventBus.ending_triggered.emit(ending_type)
			else:
				say(text if not text.is_empty() else "This way is still sealed.")
	busy = false
	EventBus.interaction_finished.emit(self)
	refresh()

func _depart(player: CharacterBody2D) -> void:
	var presentation: Node = get_node_or_null("Visual/DoorPresentation")
	if presentation != null and presentation.has_method("depart"):
		await presentation.depart(player)
	else:
		EventBus.audio_requested.emit("door")
