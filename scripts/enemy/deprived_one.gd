extends CharacterBody2D

const CharacterAnimation := preload("res://scripts/player/character_animation.gd")

enum State {
	WANDER_BLIND,
	PATROL_AUDIO,
	INVESTIGATE,
	HUNT_AUDIO,
	PATROL_SIGHT,
	CHASE,
	INVESTIGATE_LAST_SEEN,
	PREDICT_HUNT,
	AMBUSH
}

@export var blind_speed: float = 115.0
@export var patrol_speed: float = 128.0
@export var audio_hunt_speed: float = 192.0
@export var sight_chase_speed: float = 230.0
@export var true_form_speed: float = 205.0
@export var hearing_scale: float = 740.0
@export var vision_range: float = 384.0
@export var shadow_vision_range: float = 128.0
@export var field_of_view: float = 110.0
@export var flashlight_range_multiplier: float = 1.35
@export var catch_distance: float = 26.0
@export var debug_detection: bool = false

var state: State = State.WANDER_BLIND
var player: Node2D
var room: Node2D
var target: Vector2
var last_seen: Vector2
var facing := Vector2.LEFT
var path := PackedVector2Array()
var path_clock: float = 0.0
var state_clock: float = 0.0
var state_limit: float = 10.0
var lost_sight: float = 0.0
var chase_break: float = 6.5
var sight_confirm: float = 0.0
var patrol_index: int = 0
var recent_hides: Array[String] = []
var memory_points: Array[Vector2] = []
var noise_pings: Array[int] = []
var witnessed_hide: String = ""
var route_clock: float = 0.0
var stalled_time: float = 0.0
var ambush_clock: float = 3.0
var hit_cooldown: float = 0.0
var stun_seconds: float = 0.0
var detection_active: bool = false

@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D

func _ready() -> void:
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	room = get_tree().get_first_node_in_group("room")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	target = global_position
	EventBus.noise_created.connect(_hear)
	EventBus.player_hidden.connect(_hidden)
	EventBus.player_left_hiding.connect(_left_hiding)
	EventBus.sense_restored.connect(_restored)
	EventBus.player_caught.connect(_attack)
	_play_visual("idle")
	change_state(_patrol_state())
	_observe_debug()

func change_state(next: State) -> void:
	state = next
	state_clock = 0.0
	path_clock = 0.0
	match state:
		State.WANDER_BLIND:
			state_limit = randf_range(8.0, 15.0)
		State.INVESTIGATE:
			state_limit = 4.0
		State.HUNT_AUDIO:
			state_limit = 6.0
		State.CHASE:
			chase_break = randf_range(5.0, 8.0)
		State.INVESTIGATE_LAST_SEEN:
			state_limit = 4.0
		State.PREDICT_HUNT:
			state_limit = 8.0
		State.AMBUSH:
			state_limit = 4.5
	var searching := state in [State.INVESTIGATE, State.HUNT_AUDIO, State.INVESTIGATE_LAST_SEEN, State.PREDICT_HUNT, State.AMBUSH]
	EventBus.tension_changed.emit("CHASE" if state == State.CHASE else ("SEARCHING" if searching else "CALM"))
	if searching:
		EventBus.audio_requested.emit("monster_search")

func _patrol_state() -> State:
	if _stage() == 0:
		return State.WANDER_BLIND
	if _stage() == 1:
		return State.PATROL_AUDIO
	return State.PATROL_SIGHT

func _stage() -> int:
	return int(FreedomLedger.part2_seed.get("monster_stage", FreedomLedger.current_stage)) if FreedomLedger.current_part == 2 else FreedomLedger.current_stage

func _has_sense(sense: String) -> bool:
	var active: bool = sense in FreedomLedger.part2_seed.get("senses", []) if FreedomLedger.current_part == 2 else sense in FreedomLedger.keys_collected
	return active and not _sense_blocked(sense)

func _sense_blocked(sense: String) -> bool:
	if Time.get_ticks_msec() >= int(FreedomLedger.flags.get("sigil_until", 0)):
		return false
	var sigil := Vector2(float(FreedomLedger.flags.get("sigil_x", -99999.0)), float(FreedomLedger.flags.get("sigil_y", -99999.0)))
	if global_position.distance_to(sigil) > 192.0:
		return false
	if FreedomLedger.part2_seed.get("hybrid_magic", false):
		return sense in FreedomLedger.part2_seed.get("dormant_senses", [])
	return true

func _restored(sense: String) -> void:
	if sense == "memory":
		recent_hides.clear()
		for id in FreedomLedger.hiding_usage:
			if int(FreedomLedger.hiding_usage[id]) > 0:
				recent_hides.append(str(id))
		while recent_hides.size() > 5:
			recent_hides.pop_front()
		target = room.clamp_point(Vector2(180.0, player.global_position.y))
		sprite.scale = Vector2.ONE * 0.62
		sprite.modulate = Color(0.88, 0.76, 0.76)
		change_state(State.PREDICT_HUNT)
	else:
		change_state(_patrol_state())

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(room) or GameManager.state != GameManager.State.PLAYING:
		velocity = Vector2.ZERO
		return
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	if stun_seconds > 0.0:
		stun_seconds -= delta
		velocity = Vector2.ZERO
		_play_visual("stagger")
		return
	state_clock += delta
	route_clock -= delta
	ambush_clock -= delta
	_update_vision(delta)
	_detect_touch()
	_update_state(delta)
	if GameManager.state != GameManager.State.PLAYING:
		return
	_move(delta)
	_resolve_contact()
	_observe_debug()

func _update_vision(delta: float) -> void:
	var sees := can_see_player()
	if sees:
		sight_confirm += delta
		last_seen = player.global_position
		lost_sight = 0.0
		if _stage() >= 3 and route_clock <= 0.0:
			route_clock = 1.0
			memory_points.append(last_seen)
			if memory_points.size() > 5:
				memory_points.pop_front()
		if sight_confirm >= 0.6 and state != State.CHASE:
			_begin_detection()
			change_state(State.CHASE)
	else:
		sight_confirm = 0.0

func _detect_touch() -> void:
	if FreedomLedger.current_part != 2 or not FreedomLedger.part2_seed.get("touch_mutation", false) or _sense_blocked("touch"):
		return
	if player.get_real_velocity().length() < 10.0:
		return
	var transmission: float = room.vibration_transmission_at(player.global_position)
	if global_position.distance_to(player.global_position) <= transmission and state not in [State.CHASE, State.HUNT_AUDIO]:
		target = player.global_position
		_begin_detection()
		change_state(State.HUNT_AUDIO)

func _update_state(delta: float) -> void:
	match state:
		State.WANDER_BLIND:
			if global_position.distance_to(target) < 30.0 or state_clock >= state_limit:
				_choose_patrol_target()
				state_limit = randf_range(8.0, 15.0)
				state_clock = 0.0
		State.PATROL_AUDIO, State.PATROL_SIGHT:
			if global_position.distance_to(target) < 30.0 or state_clock > 9.0:
				_choose_patrol_target()
				state_clock = 0.0
			if _stage() >= 3 and ambush_clock <= 0.0:
				ambush_clock = 3.0
				if randf() <= 0.35:
					_predict_exit()
		State.INVESTIGATE:
			if global_position.distance_to(target) < 36.0:
				velocity = Vector2.ZERO
				if state_clock >= state_limit:
					change_state(_patrol_state())
			elif state_clock > 10.0:
				change_state(_patrol_state())
		State.HUNT_AUDIO:
			if state_clock >= state_limit:
				detection_active = false
				change_state(_patrol_state())
		State.CHASE:
			if can_see_player():
				target = player.global_position
			else:
				lost_sight += delta
				target = last_seen
				if lost_sight >= chase_break:
					detection_active = false
					change_state(State.INVESTIGATE_LAST_SEEN)
		State.INVESTIGATE_LAST_SEEN:
			if global_position.distance_to(target) < 36.0 and state_clock >= state_limit:
				if _stage() >= 3:
					_predict()
				else:
					change_state(_patrol_state())
			elif state_clock > 10.0:
				change_state(_patrol_state())
		State.PREDICT_HUNT:
			if global_position.distance_to(target) < 36.0:
				_check_remembered_hide()
				change_state(State.INVESTIGATE_LAST_SEEN)
			elif state_clock >= state_limit:
				change_state(_patrol_state())
		State.AMBUSH:
			if state_clock >= state_limit:
				change_state(_patrol_state())

func _choose_patrol_target() -> void:
	patrol_index += 1
	if room.has_method("patrol_target"):
		target = room.patrol_target(_stage(), patrol_index)
		return
	var anchor: float = room.patrol_anchor()
	var spread := 440.0 if patrol_index % 2 == 0 else -440.0
	target = room.clamp_point(Vector2(anchor + spread, 440.0 if patrol_index % 2 == 0 else 570.0))

func _move(delta: float) -> void:
	path_clock -= delta
	if path_clock <= 0.0:
		path_clock = 0.45
		path = room.find_path(global_position, target)
	while not path.is_empty() and global_position.distance_to(path[0]) < 14.0:
		path.remove_at(0)
	var direction := Vector2.ZERO
	if not path.is_empty():
		direction = global_position.direction_to(path[0])
	elif global_position.distance_to(target) > 25.0 and clear_sight(target):
		direction = global_position.direction_to(target)
	var speed := _move_speed()
	velocity = Vector2(direction.x, direction.y * 0.7) * speed
	var before := global_position
	move_and_slide()
	if direction.length_squared() > 0.01:
		facing = direction
		stalled_time = stalled_time + delta if global_position.distance_to(before) < 0.15 else 0.0
	else:
		stalled_time = 0.0
	if stalled_time > 1.5:
		target = room.reachable_fallback(global_position)
		path_clock = 0.0
		stalled_time = 0.0
		change_state(State.INVESTIGATE)
	var animation := "idle"
	if global_position.distance_to(before) > 0.01:
		animation = "run" if state == State.CHASE else "walk"
	_play_visual(animation)

func _move_speed() -> float:
	if _stage() == 0:
		return blind_speed
	if state == State.CHASE:
		return true_form_speed if _stage() >= 3 else sight_chase_speed
	if state == State.HUNT_AUDIO:
		return audio_hunt_speed
	return patrol_speed

func _resolve_contact() -> void:
	if global_position.distance_to(player.global_position) >= catch_distance or hit_cooldown > 0.0:
		return
	if player.hidden_spot != null and player.hidden_spot.interaction_id != witnessed_hide:
		return
	if not clear_sight(player.global_position):
		return
	if _stage() == 0:
		hit_cooldown = 2.0
		player.play_action("stagger", 0.7)
		velocity = -facing * blind_speed
		return
	if FreedomLedger.current_part == 2:
		hit_cooldown = 1.25
		player.take_hit(25.0)
	else:
		EventBus.player_caught.emit()

func _hear(point: Vector2, intensity: float, surface: String) -> void:
	if not _has_sense("hearing") or state == State.CHASE or GameManager.state != GameManager.State.PLAYING:
		return
	var radius := intensity if intensity > 10.0 else intensity * hearing_scale
	if global_position.distance_to(point) > radius:
		return
	var now := Time.get_ticks_msec()
	noise_pings = noise_pings.filter(func(stamp: int): return now - stamp <= 6000)
	noise_pings.append(now)
	target = point
	if surface == "GLASS" or noise_pings.size() >= 2:
		_begin_detection()
		change_state(State.HUNT_AUDIO)
	else:
		change_state(State.INVESTIGATE)

func _begin_detection() -> void:
	if detection_active:
		return
	detection_active = true
	FreedomLedger.record_detection()
	EventBus.player_detected.emit(self)

func clear_sight(point: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -7), point + Vector2(0, -7), 1, [get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func can_see_player() -> bool:
	if not _has_sense("sight") or player.hidden_spot != null:
		return false
	var offset: Vector2 = player.global_position - global_position
	var reach := vision_range if room.is_exposed(player.global_position) else shadow_vision_range
	if player.flashlight_enabled:
		reach *= flashlight_range_multiplier
	if offset.length() > reach:
		return false
	if offset.length() > 50.0 and facing.dot(offset.normalized()) < cos(deg_to_rad(field_of_view * 0.5)):
		return false
	return clear_sight(player.global_position)

func _hidden(id: String) -> void:
	var observed := _has_sense("sight") and sight_confirm > 0.0 and clear_sight(player.global_position)
	if observed:
		witnessed_hide = id
		target = player.global_position
		last_seen = target
		change_state(State.INVESTIGATE_LAST_SEEN)
		if _stage() >= 3:
			recent_hides.erase(id)
			recent_hides.append(id)
			if recent_hides.size() > 5:
				recent_hides.pop_front()

func _left_hiding(id: String) -> void:
	if witnessed_hide == id:
		witnessed_hide = ""

func _predict() -> void:
	var candidates: Array = get_tree().get_nodes_in_group("interactable").filter(func(spot): return spot.kind == "hiding")
	candidates.sort_custom(func(a, b): return _hide_score(a) > _hide_score(b))
	if not candidates.is_empty():
		target = candidates[0].global_position
		change_state(State.PREDICT_HUNT)
		return
	if memory_points.size() >= 2:
		var direction: Vector2 = (memory_points[-1] - memory_points[-2]).normalized()
		target = room.clamp_point(memory_points[-1] + direction * 240.0)
		change_state(State.PREDICT_HUNT)
	else:
		change_state(_patrol_state())

func _hide_score(spot: BaseInteractable) -> int:
	var priority: int = int({"low": 1, "medium": 2, "high": 3}.get(spot.hiding_priority, 1))
	priority = mini(3, priority + int(FreedomLedger.hiding_usage.get(spot.interaction_id, 0)))
	return priority * 10

func _predict_exit() -> void:
	var exits: Array[Vector2] = room.known_exit_positions()
	if exits.is_empty():
		return
	var heading: Vector2 = player.facing
	var best: Vector2 = exits[0]
	var best_dot: float = -2.0
	for point in exits:
		var dot: float = heading.dot(player.global_position.direction_to(point))
		if dot > best_dot:
			best_dot = dot
			best = point
	target = best
	change_state(State.AMBUSH)

func _check_remembered_hide() -> void:
	if player.hidden_spot != null and global_position.distance_to(player.hidden_spot.global_position) < 45.0 and clear_sight(player.hidden_spot.global_position):
		if FreedomLedger.current_part == 2:
			player.take_hit(35.0)
		else:
			EventBus.player_caught.emit()

func stun(seconds: float) -> void:
	stun_seconds = maxf(stun_seconds, seconds)
	velocity = Vector2.ZERO

func _play_visual(animation: String) -> void:
	var has_art := CharacterAnimation.play(sprite, animation, facing)
	sprite.visible = has_art
	$Visual/PlaceholderVisual.visible = not has_art

func _attack() -> void:
	velocity = Vector2.ZERO
	if is_instance_valid(player):
		facing = global_position.direction_to(player.global_position)
	_play_visual("attack")

func _observe_debug() -> void:
	$DebugState.visible = debug_detection
	if debug_detection:
		$DebugState.text = State.keys()[state] + " / " + str(_stage())
		queue_redraw()

func _draw() -> void:
	if not debug_detection:
		return
	draw_arc(Vector2.ZERO, vision_range, facing.angle() - deg_to_rad(field_of_view / 2), facing.angle() + deg_to_rad(field_of_view / 2), 30, Color(0.8, 0.55, 0.2, 0.45), 2.0)
	draw_line(Vector2.ZERO, to_local(target), Color(0.8, 0.2, 0.2, 0.7), 2.0)
