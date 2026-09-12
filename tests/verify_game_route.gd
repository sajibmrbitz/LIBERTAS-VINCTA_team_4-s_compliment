extends Node

var checks := 0
var main: Node2D
var failures: Array[String] = []

func _ready() -> void:
	get_tree().current_scene = null
	Engine.time_scale = 12.0
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
			_check(main.room.layout.has("rooms"), "Missing literal room regions in " + zone)
			print("REACHED " + zone + ": " + ", ".join(main.room.layout.names))
			return true
	_check(false, "Transition timed out: " + zone)
	get_tree().quit(1)
	return false

func _use(id: String) -> void:
	var prop: BaseInteractable = main.room.props.get_node_or_null(NodePath(id))
	_check(prop != null, "Missing interaction " + id)
	if prop == null:
		return
	var player: CharacterBody2D = main.get_node("Entities/Player")
	player.position = prop.position + Vector2(0, 30)
	player.velocity = Vector2.ZERO
	await get_tree().physics_frame
	player._find_interactable()
	_check(player.target_interactable == prop, "Cannot select " + id)
	await prop.interact(player)
	if GameManager.state == GameManager.State.READING:
		main.get_node("UI").close_modal()
		await get_tree().process_frame

func _solve(id: String) -> void:
	var prop: BaseInteractable = main.room.props.get_node(NodePath(id))
	for _step in prop.puzzle_steps:
		await _use(id)
	_check(FreedomLedger.flags.get(prop.interaction_id, false), id + " did not unlock")

func _check_rule_table() -> void:
	FreedomLedger.reset()
	_check(FreedomLedger.eligible("untouched"), "Untouched must begin eligible")
	FreedomLedger.record_detection()
	_check(not FreedomLedger.eligible("untouched"), "A detection must close Untouched")
	FreedomLedger.reset()
	FreedomLedger.restore_sense("hearing")
	for i in 4:
		FreedomLedger.collect_letter("rule_letter_" + str(i))
	_check(FreedomLedger.eligible("vantree"), "Vantree requires one key and four letters")
	FreedomLedger.restore_sense("sight")
	_check(FreedomLedger.eligible("partial_mercy"), "Partial Mercy requires two keys")
	FreedomLedger.restore_sense("memory")
	_check(FreedomLedger.eligible("loop"), "Three keys must select the Loop")
	var save := FreedomLedger.snapshot()
	for field in ["keys", "letters", "entity_stage", "ending_type", "loop_counter", "part2_seed"]:
		_check(save.has(field), "Save schema missing " + field)

func _run() -> void:
	_check_rule_table()
	GameManager.new_game()
	if not await _wait_zone("intro"):
		return
	await _use("IntroExit")
	_check(FreedomLedger.flags.get("intro_door_tried", false), "First door attempt was not recorded")
	await _use("Flashlight")
	await _use("LockpickTool")
	_check(int(FreedomLedger.inventory.lockpick) == 3, "Tool pouch must contain three lockpicks")
	await _use("IntroExit")
	if not await _wait_zone("ground"):
		return
	var ground_ids: Array = main.room.layout.rooms.map(func(room): return room.id)
	_check(ground_ids == ["GF-01", "GF-02", "GF-03", "GF-04", "GF-05", "GF-06", "GF-07", "GF-08", "GF-09", "GF-10"], "Ground room IDs changed")
	await _solve("PianoSeal")
	await _use("HearingKey")
	_check(FreedomLedger.hearing_restored and FreedomLedger.current_stage == 1, "Hearing stage did not activate")
	await _use("Vantree01")
	await _use("Vantree02")
	await _use("UpperStairs")
	if not await _wait_zone("upper"):
		return
	await _use("Vantree03")
	await _use("Vantree04")
	_check(FreedomLedger.letters_found == 4 and FreedomLedger.flags.get("lore_jailer_hint", false), "Four-letter Jailer threshold failed")
	await _use("UpperStairs")
	if not await _wait_zone("ground"):
		return
	await _use("BasementStairs")
	if not await _wait_zone("basement"):
		return
	_check(FreedomLedger.eligible("vantree"), "Ritual Conduit should be open")
	await _use("RitualConduit")
	_check(GameManager.state == GameManager.State.ENDING and GameManager.ending == "vantree", "Vantree Part I ending did not trigger")
	GameManager.continue_to_part_two()
	if not await _wait_zone("roots"):
		return
	_check(FreedomLedger.current_part == 2, "Part II did not start")
	_check(FreedomLedger.part2_seed.get("touch_mutation", false), "Vantree seed missing Touch mutation")
	_check(FreedomLedger.part2_seed.get("blood_magic", false), "Vantree seed missing Blood Magic")
	_check(FreedomLedger.part2_seed.get("senses", []).is_empty(), "Vantree monster inherited a sealed Part I sense")
	_check(is_equal_approx(FreedomLedger.max_hp, 80.0), "Vantree HP soft cap missing")
	await _use("VantreeAltar")
	await _use("Vantree08")
	await _use("EchoThreshold")
	if not await _wait_zone("echoes"):
		return
	await _use("SigilForge")
	var player: CharacterBody2D = main.get_node("Entities/Player")
	player.sigil_cooldown = 0.0
	_check(player.use_sigil(), "First Blood Sigil failed")
	player.sigil_cooldown = 0.0
	_check(player.use_sigil(), "Second Blood Sigil failed")
	_check(FreedomLedger.mechanic_uses >= 3, "Echo mechanic gate did not count three uses")
	await _use("NexusDescent")
	if not await _wait_zone("nexus"):
		return
	FreedomLedger.flags["automation_channel"] = true
	await _use("LnA")
	_check(GameManager.state == GameManager.State.ENDING and GameManager.ending == "severance", "Severance ending did not complete")
	_check("LN-A" in FreedomLedger.anchors_cleansed, "Nexus anchor did not persist")
	FreedomLedger.reset()
	FreedomLedger.restore_sense("hearing")
	FreedomLedger.restore_sense("sight")
	FreedomLedger.restore_sense("memory")
	GameManager.state = GameManager.State.PLAYING
	GameManager.finish("loop")
	await get_tree().create_timer(0.5, false).timeout
	_check(FreedomLedger.current_stage == 0 and FreedomLedger.keys_collected.is_empty(), "Loop did not reset keys and entity")
	_check(FreedomLedger.loop_counter == 1 and FreedomLedger.part2_seed.is_empty(), "Loop generated an invalid Part II seed")
	FreedomLedger.reset_for_loop()
	_check(FreedomLedger.flags.get("vantree_memory_fragment_A", false), "Second loop did not unlock memory fragment A")
	print("ROUTE CHECK: %s checks, %s failures. Canon Vantree route, Part II, finale, and false-exit loop verified." % [checks, failures.size()])
	var active_scene := get_tree().current_scene
	if active_scene != null and active_scene != self:
		active_scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if failures.is_empty() else 1)
