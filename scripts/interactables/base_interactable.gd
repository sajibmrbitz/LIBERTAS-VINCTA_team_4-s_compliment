class_name BaseInteractable
extends Node2D
## Shared interaction contract. Scene presets provide shape; data provides behavior.

@export_enum("door", "locked_door", "key", "letter", "flashlight", "tool", "hiding", "puzzle", "exit", "item", "recharge", "vent", "forge", "anchor", "lore") var kind: String = "door"
@export var interaction_id: String = ""
@export var title: String = ""
@export var display_name: String = ""
@export_multiline var text: String = ""
@export var speaker: String = "ELS"
@export var sense: String = ""
@export var item_id: String = ""
@export var item_amount: int = 1
@export var noise_radius: float = 0.0
@export var required_flag: String = ""
@export var destination: String = ""
@export var entrance: String = "start"
@export var ending_type: String = "untouched"
@export var puzzle_steps: int = 3
@export var action_seconds: float = 0.9
@export var action_animation_override: String = ""
@export var action_position_offset: Vector2 = Vector2.ZERO
@export var action_facing: Vector2 = Vector2.ZERO
@export_enum("low", "medium", "high") var hiding_priority: String = "low"
@export var channel_seconds: float = 20.0

var busy: bool = false
var progress: int = 0
var interrupt_serial: int = 0

func _ready() -> void:
	add_to_group("interactable")
	$Visual/PlaceholderVisual.visible = $Visual/Sprite2D.texture == null
	EventBus.player_detected.connect(func(_source): interrupt_serial += 1)
	EventBus.player_hurt.connect(func(_amount): interrupt_serial += 1)
	refresh()

func available() -> bool:
	if busy:
		return false
	if kind in ["forge", "lore"] and not required_flag.is_empty() and not FreedomLedger.has_requirement(required_flag):
		return false
	if kind == "key":
		return sense not in FreedomLedger.keys_collected
	if kind == "letter":
		return interaction_id not in FreedomLedger.letter_ids
	if kind in ["flashlight", "tool", "item", "forge", "lore"]:
		return not FreedomLedger.flags.get(interaction_id, false)
	if kind == "anchor":
		return interaction_id not in FreedomLedger.anchors_cleansed
	return true

func refresh() -> void:
	visible = available() or kind in ["puzzle", "door", "locked_door", "hiding", "exit", "recharge", "vent", "anchor"]

func say(line: String, seconds: float = 2.0, speaker: String = "ELS") -> void:
	EventBus.subtitle_requested.emit(speaker, line, seconds)

func interact(player: Node2D) -> void:
	if not available() or GameManager.state != GameManager.State.PLAYING:
		return
	busy = true
	EventBus.interaction_started.emit(self)
	_prepare_action_pose(player)
	player.play_action(_action_animation(), action_seconds if kind in ["puzzle", "recharge", "anchor"] else 1.0)
	match kind:
		"flashlight": _take_flashlight(player)
		"tool": _take_tools()
		"item": _take_item()
		"letter": _read_letter()
		"hiding": _hide(player)
		"key": _take_key(player)
		"puzzle": await _work_puzzle(player)
		"recharge": await _recharge(player)
		"forge": _activate_forge()
		"lore": _reveal_lore()
		"anchor": await _channel_anchor(player)
		"locked_door": await _unlock_intro(player)
		"door", "vent": await _travel(player)
		"exit": await _exit(player)
	busy = false
	EventBus.interaction_finished.emit(self)
	refresh()

func _action_animation() -> String:
	if not action_animation_override.is_empty():
		return action_animation_override
	if kind in ["key", "letter", "item", "flashlight"]:
		return "pickup"
	if kind in ["locked_door", "door", "puzzle", "vent", "anchor"]:
		return "unlock"
	return "interact"

func _prepare_action_pose(player: Node2D) -> void:
	if action_position_offset != Vector2.ZERO:
		player.global_position = global_position + action_position_offset
		if player is CharacterBody2D:
			player.velocity = Vector2.ZERO
	if action_facing != Vector2.ZERO:
		player.facing = action_facing.normalized()

func _take_flashlight(player: Node2D) -> void:
	FreedomLedger.flags[interaction_id] = true
	FreedomLedger.set_flashlight_seconds(FreedomLedger.MAX_FLASHLIGHT_SECONDS)
	player.set_flashlight(true)
	say("Mine...", 1.8)
	say("How did it get over there?", 2.6)

func _take_tools() -> void:
	FreedomLedger.flags[interaction_id] = true
	FreedomLedger.collect_item("lockpick", 3)
	say("At least I came prepared.")

func _take_item() -> void:
	FreedomLedger.flags[interaction_id] = true
	FreedomLedger.collect_item(item_id, item_amount)
	say(display_name + " collected.", 1.4)

func _read_letter() -> void:
	if FreedomLedger.collect_letter(interaction_id):
		var hud = get_tree().get_first_node_in_group("hud")
		if hud != null:
			hud.show_letter(title, text)

func _hide(player: Node2D) -> void:
	FreedomLedger.record_hiding_use(interaction_id)
	player.enter_hiding(self)

func _take_key(player: Node2D) -> void:
	if not FreedomLedger.has_requirement(required_flag):
		say("The seal is still holding.")
	elif FreedomLedger.restore_sense(sense):
		if sense == "hearing":
			EventBus.audio_requested.emit("monster_screech")
			FreedomLedger.flags["piano_screech"] = true
		elif sense == "memory":
			FreedomLedger.flags["true_form_revealed"] = true
		say({"hearing": "Something heard that.", "sight": "It turned toward the light.", "memory": "It knows this place now."}[sense], 2.8)
		GameManager.save_checkpoint(player.global_position)
	else:
		say("Another seal holds this one.")

func _work_puzzle(player: Node2D) -> void:
	if not FreedomLedger.has_requirement(required_flag):
		say("Not yet.")
		return
	if progress == 0 and not FreedomLedger.consume_item("lockpick"):
		say("I need a lockpick.")
		return
	player.control_enabled = false
	EventBus.audio_requested.emit("lockpick")
	await get_tree().create_timer(action_seconds, false).timeout
	if GameManager.state != GameManager.State.PLAYING:
		return
	player.control_enabled = true
	progress += 1
	EventBus.noise_created.emit(global_position, 300.0, "GENERIC")
	if progress >= puzzle_steps:
		FreedomLedger.flags[interaction_id] = true
		say("The seal gives.")
	else:
		say("Click. " + str(progress) + " of " + str(puzzle_steps) + ".", 1.1)

func _recharge(player: Node2D) -> void:
	if FreedomLedger.flashlight_seconds >= FreedomLedger.MAX_FLASHLIGHT_SECONDS:
		say("The battery is already full.")
		return
	player.control_enabled = false
	player.velocity = Vector2.ZERO
	say("Charging...", 1.2)
	await get_tree().create_timer(12.0, false).timeout
	if GameManager.state == GameManager.State.PLAYING:
		FreedomLedger.set_flashlight_seconds(FreedomLedger.MAX_FLASHLIGHT_SECONDS)
		player.control_enabled = true
		say("Full charge.")

func _activate_forge() -> void:
	FreedomLedger.flags[interaction_id] = true
	FreedomLedger.flags["part2_ability_unlocked"] = true
	FreedomLedger.damage(FreedomLedger.max_hp * 0.08)
	FreedomLedger.mechanic_uses += 1
	EventBus.ability_used.emit("forge")
	if FreedomLedger.part2_seed.get("touch_mutation", false):
		say("The stone answers through my hands.")
	else:
		say("The sigil takes its price.")

func _reveal_lore() -> void:
	FreedomLedger.flags[interaction_id] = true
	if noise_radius > 0.0:
		EventBus.noise_created.emit(global_position, noise_radius, "GENERIC")
	say(text, 4.0, speaker)

func _channel_anchor(player: Node2D) -> void:
	if not FreedomLedger.has_requirement(required_flag):
		say(text if not text.is_empty() else "The anchor refuses the pattern.")
		return
	player.control_enabled = false
	player.velocity = Vector2.ZERO
	var started_serial := interrupt_serial
	var elapsed := 0.0
	while elapsed < channel_seconds:
		await get_tree().physics_frame
		if interrupt_serial != started_serial or GameManager.state != GameManager.State.PLAYING:
			player.control_enabled = true
			EventBus.anchor_progress.emit(interaction_id, 0.0, channel_seconds)
			say("The pattern broke.")
			return
		if not Input.is_action_pressed("interact") and elapsed > 0.2 and not FreedomLedger.flags.get("automation_channel", false):
			player.control_enabled = true
			EventBus.anchor_progress.emit(interaction_id, 0.0, channel_seconds)
			return
		elapsed += get_physics_process_delta_time()
		EventBus.anchor_progress.emit(interaction_id, elapsed, channel_seconds)
	FreedomLedger.cleanse_anchor(interaction_id)
	player.control_enabled = true
	say("Anchor cleansed.")
	if ending_type in ["severance", "custodian_rest", "vessel"]:
		EventBus.ending_triggered.emit(ending_type)

func _unlock_intro(player: CharacterBody2D) -> void:
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

func _travel(player: CharacterBody2D) -> void:
	if not FreedomLedger.has_requirement(required_flag):
		say(text if not text.is_empty() else "The passage is sealed.")
		return
	await _depart(player)
	GameManager.travel.call_deferred(destination, entrance)

func _exit(player: CharacterBody2D) -> void:
	var candidate := ending_type
	if ending_type == "front_door":
		if FreedomLedger.current_stage == 0 and not FreedomLedger.flags.get("door_tested", false):
			FreedomLedger.flags["door_tested"] = true
			EventBus.audio_requested.emit("door")
			return
		candidate = "untouched" if FreedomLedger.current_stage == 0 else ("loop" if FreedomLedger.current_stage == 3 else "")
	if not candidate.is_empty() and FreedomLedger.eligible(candidate):
		await _depart(player)
		EventBus.ending_triggered.emit(candidate)
	else:
		say(text if not text.is_empty() else "This way is still sealed.")

func _depart(player: CharacterBody2D) -> void:
	var presentation: Node = get_node_or_null("Visual/DoorPresentation")
	if presentation != null and presentation.has_method("depart"):
		await presentation.depart(player)
	else:
		EventBus.audio_requested.emit("door")
