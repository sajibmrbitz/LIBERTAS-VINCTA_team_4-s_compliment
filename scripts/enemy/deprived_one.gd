extends CharacterBody2D
const CharacterAnimation := preload("res://scripts/player/character_animation.gd")
enum State { DORMANT, WANDER, INVESTIGATE, SEARCH, CHASE, PREDICT_HUNT }
@export var walk_speed: float = 100.0
@export var chase_speed: float = 220.0
@export var hearing_scale: float = 740.0
@export var vision_range: float = 390.0
@export var field_of_view: float = 115.0
@export var flashlight_range_multiplier: float = 1.75
@export var crouch_visibility: float = 0.6
@export var darkness_visibility: float = 0.55
@export var catch_distance: float = 26.0
@export var debug_detection: bool = false
var state: State = State.DORMANT
var player: Node2D
var room: Node2D
var target: Vector2
var last_seen: Vector2
var facing := Vector2.LEFT
var path := PackedVector2Array()
var path_clock: float = 0.0
var state_clock: float = 0.0
var lost_sight: float = 0.0
var patrol_index: int = 0
var recent_hides: Array[String] = []
var observed_route: Array[Vector2] = []
var witnessed_hide: String = ""
var route_clock: float = 0.0
var stalled_time: float = 0.0
var investigation_intensity: float = 0.0
var observation_grace: float = 0.0
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
	if FreedomLedger.hearing_restored:
		change_state(State.WANDER)
	_observe_debug()

func change_state(next: State) -> void:
	state = next
	state_clock = 0.0
	path_clock = 0.0
	var tension := "CHASE" if state == State.CHASE else ("SEARCHING" if state in [State.INVESTIGATE, State.SEARCH, State.PREDICT_HUNT] else "CALM")
	EventBus.tension_changed.emit(tension)
	if state == State.SEARCH:
		EventBus.audio_requested.emit("monster_search")

func _restored(_sense: String) -> void:
	if state == State.DORMANT and FreedomLedger.hearing_restored:
		change_state(State.WANDER)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(room) or GameManager.state != GameManager.State.PLAYING:
		velocity = Vector2.ZERO
		return
	state_clock += delta
	route_clock -= delta
	observation_grace = maxf(0.0, observation_grace - delta)
	var sees := can_see_player()
	if sees:
		last_seen = player.global_position
		lost_sight = 0.0
		observation_grace = 0.25
		if FreedomLedger.memory_restored and route_clock <= 0.0:
			route_clock = 1.0
			observed_route.append(last_seen)
			if observed_route.size() > 4:
				observed_route.pop_front()
		if state != State.CHASE:
			EventBus.player_detected.emit(self)
			change_state(State.CHASE)
	match state:
		State.DORMANT:
			velocity = Vector2.ZERO
			_play_visual("idle")
			return
		State.WANDER:
			if global_position.distance_to(target) < 30.0 or state_clock > 10.0:
				patrol_index += 1
				var anchor: float = room.patrol_anchor()
				target = Vector2(clampf(anchor + (360.0 if patrol_index % 2 == 0 else -360.0), 120.0, room.room_width - 120.0), 440.0 if patrol_index % 2 == 0 else 570.0)
				state_clock = 0.0
		State.INVESTIGATE:
			if global_position.distance_to(target) < 35.0 or state_clock > 9.0:
				change_state(State.SEARCH)
		State.SEARCH:
			if FreedomLedger.memory_restored and state_clock > 1.5 and (not recent_hides.is_empty() or observed_route.size() >= 2):
				_predict()
			elif state_clock > 4.5:
				change_state(State.WANDER)
		State.CHASE:
			if sees:
				target = last_seen
			else:
				lost_sight += delta
				target = last_seen
				if lost_sight > 1.4:
					change_state(State.SEARCH)
		State.PREDICT_HUNT:
			if global_position.distance_to(target) < 35.0:
				_check_remembered_hide()
				change_state(State.SEARCH)
				# Consume one prediction: memory is a bounded search, not omniscience.
				observed_route.clear()
			elif state_clock > 8.0:
				change_state(State.WANDER)
	if GameManager.state != GameManager.State.PLAYING:
		return
	_move(delta)
	if FreedomLedger.hearing_restored and global_position.distance_to(player.global_position) < catch_distance:
		if player.hidden_spot == null or player.hidden_spot.interaction_id == witnessed_hide:
			if clear_sight(player.global_position):
				EventBus.player_caught.emit()
	_observe_debug()

func _move(delta: float) -> void:
	path_clock -= delta
	if path_clock <= 0.0:
		path_clock = 0.5
		path = room.find_path(global_position, target)
	while not path.is_empty() and global_position.distance_to(path[0]) < 14.0:
		path.remove_at(0)
	var direction := Vector2.ZERO
	if not path.is_empty():
		direction = global_position.direction_to(path[0])
	elif global_position.distance_to(target) > 25.0 and clear_sight(target):
		direction = global_position.direction_to(target)
	var speed := chase_speed if state == State.CHASE else walk_speed
	velocity = Vector2(direction.x, direction.y * 0.7) * speed
	var before := global_position
	move_and_slide()
	if direction.length_squared() > 0.01:
		facing = direction
		stalled_time = stalled_time + delta if global_position.distance_to(before) < 0.15 else 0.0
	else:
		stalled_time = 0.0
	if stalled_time > 1.5:
		# Fall back to a reachable lane; never teleport through walls.
		target = room.reachable_fallback(global_position)
		path_clock = 0.0
		stalled_time = 0.0
		change_state(State.INVESTIGATE)
	var animation := "idle"
	if global_position.distance_to(before) > 0.01:
		animation = "run" if state == State.CHASE else "walk"
	_play_visual(animation)

func _play_visual(animation: String) -> void:
	var has_art := CharacterAnimation.play(sprite, animation, facing)
	sprite.visible = has_art
	$Visual/PlaceholderVisual.visible = not has_art

func _attack() -> void:
	velocity = Vector2.ZERO
	if is_instance_valid(player):
		facing = global_position.direction_to(player.global_position)
	_play_visual("attack")

func _hear(point: Vector2, intensity: float, _surface: String) -> void:
	if not FreedomLedger.hearing_restored or state == State.CHASE or GameManager.state != GameManager.State.PLAYING:
		return
	if global_position.distance_to(point) > intensity * hearing_scale:
		return
	# Ignore tiny follow-up steps while responding to a louder event.
	if state == State.INVESTIGATE and state_clock < 1.0 and intensity < investigation_intensity:
		return
	investigation_intensity = intensity
	target = point
	change_state(State.INVESTIGATE)

func clear_sight(point: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -7), point + Vector2(0, -7), 1, [get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func can_see_player() -> bool:
	if not FreedomLedger.sight_restored or player.hidden_spot != null:
		return false
	var offset: Vector2 = player.global_position - global_position
	var reach := vision_range
	if player.is_crouching:
		reach *= crouch_visibility
	if not room.is_exposed(player.global_position):
		reach *= darkness_visibility
	if player.flashlight_enabled:
		reach *= flashlight_range_multiplier
	if offset.length() > reach:
		return false
	if offset.length() > 50.0 and facing.dot(offset.normalized()) < cos(deg_to_rad(field_of_view * 0.5)):
		return false
	return clear_sight(player.global_position)

func _hidden(id: String) -> void:
	# Only observed entrances are recorded, never every hiding signal globally.
	var observed := FreedomLedger.sight_restored and observation_grace > 0.0 and clear_sight(player.global_position)
	if observed:
		witnessed_hide = id
		target = player.global_position
		last_seen = target
		change_state(State.INVESTIGATE)
		if FreedomLedger.memory_restored:
			recent_hides.erase(id)
			recent_hides.append(id)
			if recent_hides.size() > 3:
				recent_hides.pop_front()

func _left_hiding(id: String) -> void:
	if witnessed_hide == id:
		witnessed_hide = ""

func _predict() -> void:
	if not recent_hides.is_empty():
		var id: String = recent_hides.pop_front()
		for spot in get_tree().get_nodes_in_group("interactable"):
			if spot.interaction_id == id:
				target = spot.global_position
				change_state(State.PREDICT_HUNT)
				return
	if observed_route.size() >= 2:
		var direction: Vector2 = (observed_route[-1] - observed_route[-2]).normalized()
		target = room.clamp_point(observed_route[-1] + direction * 240.0)
		change_state(State.PREDICT_HUNT)

func _check_remembered_hide() -> void:
	if player.hidden_spot != null and global_position.distance_to(player.hidden_spot.global_position) < 45.0:
		EventBus.player_caught.emit()

func _observe_debug() -> void:
	$DebugState.visible = debug_detection
	if debug_detection:
		$DebugState.text = State.keys()[state] + " / " + str(FreedomLedger.current_stage)
		queue_redraw()

func _draw() -> void:
	if not debug_detection:
		return
	draw_arc(Vector2.ZERO, vision_range, facing.angle() - deg_to_rad(field_of_view / 2), facing.angle() + deg_to_rad(field_of_view / 2), 30, Color(0.8, 0.55, 0.2, 0.45), 2.0)
	draw_arc(Vector2.ZERO, hearing_scale, 0, TAU, 48, Color(0.3, 0.6, 0.8, 0.2), 1.0)
	draw_line(Vector2.ZERO, to_local(target), Color(0.8, 0.2, 0.2, 0.7), 2.0)
