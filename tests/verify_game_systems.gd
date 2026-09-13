extends Node

const ROOM := preload("res://scenes/levels/ground_floor.tscn")
const PLAYER := preload("res://scenes/player/player.tscn")
const ENEMY := preload("res://scenes/enemy/deprived_one.tscn")
const ANCHOR := preload("res://scenes/interactables/anchor.tscn")
const AUDIO := preload("res://scenes/systems/audio_director.tscn")

var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	Engine.time_scale = 20.0
	AudioServer.set_bus_mute(0, true)
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func _run() -> void:
	_check_inputs_and_seeds()
	var audio: Node = AUDIO.instantiate()
	add_child(audio)
	_check(audio.players.has("monster_screech") and audio.players.monster_screech.stream != null, "Monster escalation cue is not playable")
	_check(audio.players.SEARCHING.stream != null and audio.players.CHASE.stream != null, "Threat music layers are incomplete")
	var room: Node2D = ROOM.instantiate()
	add_child(room)
	var player: CharacterBody2D = PLAYER.instantiate()
	player.position = Vector2(500, 500)
	add_child(player)
	GameManager.zone = "ground"
	GameManager.state = GameManager.State.PLAYING
	FreedomLedger.reset()
	FreedomLedger.flags["flashlight"] = true
	FreedomLedger.set_flashlight_seconds(90.0)
	player.flashlight_enabled = true
	player.is_sprinting = false
	player._update_flashlight_charge(2.0)
	_check(is_equal_approx(FreedomLedger.flashlight_seconds, 88.0), "Flashlight normal drain is not one second per second")
	player.is_sprinting = true
	player._update_flashlight_charge(2.0)
	_check(is_equal_approx(FreedomLedger.flashlight_seconds, 82.0), "Sprint flashlight drain is not triple")
	_check(is_equal_approx(player.walk_speed, 141.0) and is_equal_approx(player.sprint_speed, 256.0) and is_equal_approx(player.crouch_speed, 70.0), "Player movement tunables changed")
	_check(is_equal_approx(player.breath_capacity, 6.0) and is_equal_approx(player.breath_cooldown_seconds, 15.0), "Breath timing tunables changed")
	var radii: Array[float] = []
	var listener := func(_point: Vector2, radius: float, _surface: String): radii.append(radius)
	EventBus.noise_created.connect(listener)
	for surface in ["CARPET", "WOOD", "STONE", "WATER", "GLASS"]:
		NoiseModel.emit_step(Vector2.ZERO, 0.24, surface)
	_check(radii == [64.0, 256.0, 320.0, 448.0, 576.0], "Floor noise radii changed")
	EventBus.noise_created.disconnect(listener)
	var enemy: CharacterBody2D = ENEMY.instantiate()
	enemy.position = Vector2(750, 500)
	add_child(enemy)
	await get_tree().physics_frame
	var expected_states := ["WANDER_BLIND", "PATROL_AUDIO", "INVESTIGATE", "HUNT_AUDIO", "PATROL_SIGHT", "CHASE", "INVESTIGATE_LAST_SEEN", "PREDICT_HUNT", "AMBUSH"]
	_check(enemy.State.keys() == expected_states, "Enemy state table does not match the specification")
	_check(enemy.state == enemy.State.WANDER_BLIND, "Stage 0 did not begin blind wandering")
	_check(is_equal_approx(enemy.blind_speed, 115.0) and is_equal_approx(enemy.patrol_speed, 142.0), "Enemy patrol speeds changed")
	_check(is_equal_approx(enemy.audio_hunt_speed, 216.0) and is_equal_approx(enemy.sight_chase_speed, 282.0) and is_equal_approx(enemy.true_form_speed, 238.0), "Enemy hunt speeds changed")
	_check(is_equal_approx(enemy.audio_hunt_seconds, 10.0) and is_equal_approx(enemy.path_refresh_seconds, 0.28), "Enemy pursuit timing changed")
	_check(is_equal_approx(enemy.ambush_chance, 0.55) and is_equal_approx(enemy.ambush_interval, 2.5) and is_equal_approx(enemy.ambush_seconds, 10.0), "Enemy ambush pressure changed")
	_check(enemy.sight_chase_speed > player.sprint_speed, "Stage 2 can still be escaped by sprinting in a straight line")
	FreedomLedger.restore_sense("hearing")
	_check(enemy.state == enemy.State.PATROL_AUDIO, "Key 1 did not activate PATROL_AUDIO")
	enemy._hear(Vector2(600, 500), 300.0, "WOOD")
	_check(enemy.state == enemy.State.INVESTIGATE, "First audible ping did not trigger INVESTIGATE")
	enemy._hear(Vector2(610, 500), 300.0, "WOOD")
	_check(enemy.state == enemy.State.HUNT_AUDIO, "Two pings inside six seconds did not trigger HUNT_AUDIO")
	enemy.state_clock = 9.5
	enemy._hear(Vector2(625, 500), 300.0, "WOOD")
	_check(enemy.state == enemy.State.HUNT_AUDIO and enemy.state_clock == 0.0 and enemy.target == Vector2(625, 500), "Fresh noise did not renew and redirect the audio hunt")
	FreedomLedger.restore_sense("sight")
	_check(enemy.state == enemy.State.PATROL_SIGHT, "Key 2 did not activate PATROL_SIGHT")
	enemy.facing = Vector2.LEFT
	enemy.position = Vector2(750, 500)
	player.position = Vector2(500, 500)
	enemy._update_vision(0.3)
	_check(enemy.state != enemy.State.CHASE, "Sight confirmed in less than 0.6 seconds")
	enemy._update_vision(0.31)
	_check(enemy.state == enemy.State.CHASE, "Sight did not confirm after 0.6 seconds")
	FreedomLedger.record_hiding_use("dining_table_hide")
	FreedomLedger.restore_sense("memory")
	_check(enemy.state == enemy.State.PREDICT_HUNT, "Key 3 did not immediately activate PREDICT_HUNT")
	_check("dining_table_hide" in enemy.recent_hides, "Stage 3 did not pre-seed used hiding places")
	_check(is_equal_approx(enemy._move_speed(), enemy.true_form_speed), "Stage 3 prediction dropped back to patrol speed")
	player.facing = Vector2.RIGHT
	_check(enemy._predict_exit() and enemy.state == enemy.State.AMBUSH, "Stage 3 did not intercept a known exit ahead of the player")
	var story_lines: Array[String] = []
	var story_listener := func(_speaker: String, line: String, _duration: float): story_lines.append(line)
	EventBus.subtitle_requested.connect(story_listener)
	room._story_once("test_once", "ELS", "test line")
	room._story_once("test_once", "ELS", "test line")
	_check(story_lines == ["test line"], "One-time story beat repeated")
	EventBus.subtitle_requested.disconnect(story_listener)
	var hide: BaseInteractable = room.props.get_node("DiningTableHide")
	for _i in 5:
		FreedomLedger.record_hiding_use(hide.interaction_id)
	_check(enemy._hide_score(hide) == 30, "Repeated hiding priority did not cap at High")
	await _check_branch_abilities(player, enemy)
	await _check_anchor_interrupt(player)
	enemy.queue_free()
	player.queue_free()
	room.queue_free()
	audio.queue_free()
	await get_tree().process_frame
	print("SYSTEM CHECK: %s checks, %s failures. Tunables, state machine, resources, abilities, and channel resets verified." % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _check_inputs_and_seeds() -> void:
	for action in ["move_up", "move_down", "move_left", "move_right", "sprint", "crouch", "interact", "flashlight", "hold_breath", "gadget", "ability", "stun", "pause"]:
		_check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), "Input action missing: " + action)
	FreedomLedger.reset()
	FreedomLedger.begin_part_two("untouched")
	_check(FreedomLedger.part2_seed.senses.is_empty(), "Untouched seed must have no monster senses")
	_check(FreedomLedger.part2_seed.full_gadgets, "Untouched seed must retain full gadgets")
	_check(int(FreedomLedger.inventory.battery) >= 3 and int(FreedomLedger.inventory.bottle) >= 3 and int(FreedomLedger.inventory.clock) >= 3, "Untouched gadget kit incomplete")
	FreedomLedger.reset()
	FreedomLedger.restore_sense("hearing")
	FreedomLedger.begin_part_two("vantree")
	_check(FreedomLedger.part2_seed.senses.is_empty() and FreedomLedger.part2_seed.touch_mutation and FreedomLedger.part2_seed.blood_magic, "Vantree branch seed is incorrect")
	_check(is_equal_approx(FreedomLedger.max_hp, 80.0), "Vantree HP soft cap is incorrect")
	FreedomLedger.reset()
	FreedomLedger.restore_sense("hearing")
	FreedomLedger.restore_sense("sight")
	FreedomLedger.begin_part_two("partial_mercy")
	_check(FreedomLedger.part2_seed.senses == ["hearing", "sight"], "Mercy seed did not preserve exactly two senses")
	_check(FreedomLedger.part2_seed.dormant_senses == ["memory"] and FreedomLedger.part2_seed.hybrid_magic, "Mercy dormant-sense branch is incorrect")

func _check_branch_abilities(player: CharacterBody2D, enemy: CharacterBody2D) -> void:
	FreedomLedger.reset()
	FreedomLedger.restore_sense("hearing")
	FreedomLedger.begin_part_two("vantree")
	FreedomLedger.flags["part2_ability_unlocked"] = true
	GameManager.zone = "echoes"
	var hp_before := FreedomLedger.hp
	_check(player.use_sigil(), "Blood Sigil could not cast")
	_check(is_equal_approx(FreedomLedger.hp, hp_before - FreedomLedger.max_hp * 0.08), "Blood Sigil HP cost is not 8 percent")
	_check(player.sigil_cooldown == 20.0 and int(FreedomLedger.flags.sigil_until) > Time.get_ticks_msec(), "Blood Sigil timing is incorrect")
	player.stun_cooldown = 0.0
	enemy.position = player.position + Vector2(100, 0)
	hp_before = FreedomLedger.hp
	_check(player.use_stun(), "Stun Rite could not cast")
	_check(is_equal_approx(FreedomLedger.hp, hp_before - FreedomLedger.max_hp * 0.20), "Stun Rite HP cost is not 20 percent")
	_check(player.stun_cooldown >= 59.0 and enemy.stun_seconds >= 5.5, "Stun Rite timing is incorrect")
	FreedomLedger.reset()
	FreedomLedger.restore_sense("hearing")
	FreedomLedger.restore_sense("sight")
	FreedomLedger.begin_part_two("partial_mercy")
	FreedomLedger.flags["part2_ability_unlocked"] = true
	player.sigil_cooldown = 0.0
	hp_before = FreedomLedger.hp
	_check(player.use_sigil(), "Partial Sigil could not cast")
	_check(is_equal_approx(FreedomLedger.hp, hp_before - FreedomLedger.max_hp * 0.04), "Partial Sigil HP cost is not 4 percent")

func _check_anchor_interrupt(player: CharacterBody2D) -> void:
	FreedomLedger.flags["automation_channel"] = true
	FreedomLedger.anchors_cleansed.clear()
	GameManager.state = GameManager.State.PLAYING
	var anchor: BaseInteractable = ANCHOR.instantiate()
	anchor.interaction_id = "interrupt_test"
	anchor.channel_seconds = 2.0
	add_child(anchor)
	anchor.interact(player)
	await get_tree().create_timer(0.15, false).timeout
	EventBus.player_detected.emit(null)
	await get_tree().create_timer(0.15, false).timeout
	_check("interrupt_test" not in FreedomLedger.anchors_cleansed, "Detection did not reset anchor channel")
	_check(not anchor.busy and player.control_enabled, "Interrupted anchor did not return control")
	anchor.queue_free()
