extends Node

var checks := 0
var main: Node2D
var failures: Array[String] = []

func _ready() -> void:
	get_tree().current_scene = null
	Engine.time_scale = 8.0
	AudioServer.set_bus_mute(0, true)
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func _wait_zone(zone: String) -> bool:
	var deadline := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		var current := get_tree().current_scene
		if current != null and current.scene_file_path == "res://scenes/main/main.tscn" and current.room.zone_id == zone and GameManager.state == GameManager.State.PLAYING:
			main = current
			for enemy in get_tree().get_nodes_in_group("enemy"):
				enemy.set_physics_process(false)
			_check(main.room.get_node_or_null("Backdrop/ImportedArchitecture") != null, "Missing art in " + zone)
			if zone != "intro":
				var player: CharacterBody2D = main.get_node("Entities/Player")
				var arrival_door: BaseInteractable = main._passage_for_entry()
				var presentation: Node = arrival_door.get_node("Visual/DoorPresentation")
				_check(player.global_position.distance_to(arrival_door.global_position + Vector2(0, 56)) < 1.0, "Player did not finish beside the arrival door in " + zone)
				_check(presentation.arrival_completed, "Arrival door did not complete its close animation in " + zone)
				_check(presentation.door_sprite.scale.is_equal_approx(presentation.closed_scale), "Arrival door remained open in " + zone)
			print("REACHED " + zone + ": " + ", ".join(main.room.layout.names))
			return true
	_check(false, "Transition timed out: " + zone)
	get_tree().quit(1)
	return false

func _use(id: String) -> void:
	var prop: BaseInteractable = main.room.props.get_node(NodePath(id))
	var player: Node2D = main.get_node("Entities/Player")
	player.position = prop.position + Vector2(0, 30)
	player.velocity = Vector2.ZERO
	await get_tree().physics_frame
	player._find_interactable()
	_check(player.target_interactable == prop, "Cannot select " + id)
	if player.target_interactable == prop:
		await prop.interact(player)

func _seal(id: String, key: String) -> void:
	for i in 3:
		await _use(id)
	await _use(key)

func _run() -> void:
	GameManager.new_game()
	if not await _wait_zone("intro"):
		return
	var player: Node2D = main.get_node("Entities/Player")
	player.position = Vector2(1720, 530)
	player._find_interactable()
	_check(player.target_interactable == null, "The far corridor should be outside door interaction range")
	await _use("IntroExit")
	_check(FreedomLedger.flags.get("intro_door_tried", false), "First door attempt did not acknowledge lock")
	await _use("IntroExit")
	_check(GameManager.zone == "intro", "Door opened without tools")
	await _use("Flashlight")
	await _use("LockpickTool")
	await _use("IntroExit")
	if not await _wait_zone("ground"):
		return
	await _seal("PianoSeal", "HearingKey")
	_check(FreedomLedger.hearing_restored, "Hearing not restored")
	await _use("UpperStairs")
	if not await _wait_zone("upper"):
		return
	await _use("GroundStairs")
	if not await _wait_zone("ground"):
		return
	_check(GameManager.entry == "end", "Upper return entrance wrong")
	await _use("UpperStairs")
	if not await _wait_zone("upper"):
		return
	await _seal("VanitySeal", "SightKey")
	_check(FreedomLedger.sight_restored, "Sight not restored")
	await _use("BasementStairs")
	if not await _wait_zone("basement"):
		return
	_check(FreedomLedger.eligible("partial_mercy"), "Partial Mercy exit unavailable with two senses")
	await _use("UpperStairs")
	if not await _wait_zone("upper"):
		return
	await _use("BasementStairs")
	if not await _wait_zone("basement"):
		return
	await _seal("RitualSeal", "MemoryKey")
	_check(FreedomLedger.memory_restored, "Memory not restored")
	await _use("ServiceReturn")
	if not await _wait_zone("ground"):
		return
	await _use("FrontDoor")
	_check(GameManager.state == GameManager.State.ENDING and GameManager.ending == "full_awakening", "Full Awakening ending unreachable")
	print("ROUTE CHECK: %s checks, %s failures. Intro, ground, upper, basement, return routes and final ending verified." % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
