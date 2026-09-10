extends CharacterBody2D
const CharacterAnimation := preload("res://scripts/player/character_animation.gd")
## Ground-plane locomotion: collision is a foot footprint, independent of art.
@export var walk_speed: float = 160.0
@export var sprint_speed: float = 260.0
@export var crouch_speed: float = 80.0
@export_range(0.1, 1.0) var depth_ratio: float = 0.55
@export var acceleration: float = 1100.0
@export var interaction_radius: float = 76.0
var control_enabled: bool = true
var is_crouching: bool = false
var hidden_spot: Node2D
var flashlight_enabled: bool = false
var facing: Vector2 = Vector2.RIGHT
var noise_clock: float = 0.0
var target_interactable: Node2D
var animation_state: String = "idle"
var animation_hold: float = 0.0
@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D

func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	EventBus.player_caught.connect(_caught)
	play_animation("idle")

func _physics_process(delta: float) -> void:
	animation_hold = maxf(0.0, animation_hold - delta)
	target_interactable = null
	if not control_enabled or GameManager.state != GameManager.State.PLAYING:
		velocity = Vector2.ZERO
		return
	if Input.is_action_just_pressed("flashlight") and FreedomLedger.flags.get("flashlight", false) and hidden_spot == null:
		set_flashlight(not flashlight_enabled)
	if hidden_spot != null:
		if Input.is_action_just_pressed("interact"):
			leave_hiding()
		return
	is_crouching = Input.is_action_pressed("crouch")
	var axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed := crouch_speed if is_crouching else (sprint_speed if Input.is_action_pressed("sprint") else walk_speed)
	var desired := Vector2(axis.x, axis.y * depth_ratio) * speed
	velocity = velocity.move_toward(desired, acceleration * delta)
	move_and_slide()
	if axis.length_squared() > 0.01:
		facing = axis.normalized()
	_update_animation(axis, speed)
	visual.scale.y = 0.65 if is_crouching else 1.0
	noise_clock -= delta
	if get_real_velocity().length() > 10.0 and noise_clock <= 0.0:
		noise_clock = 0.52 if is_crouching else (0.27 if speed == sprint_speed else 0.42)
		var intensity := 0.06 if is_crouching else (1.0 if speed == sprint_speed else 0.24)
		var room = get_tree().get_first_node_in_group("room")
		var surface: String = room.surface_at(global_position) if room != null else "GENERIC"
		NoiseModel.emit_step(global_position, intensity, surface)
	_find_interactable()
	if Input.is_action_just_pressed("interact") and is_instance_valid(target_interactable):
		target_interactable.interact(self)

func _find_interactable() -> void:
	var nearest := interaction_radius
	for candidate in get_tree().get_nodes_in_group("interactable"):
		if not candidate.available():
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < nearest:
			var ray := PhysicsRayQueryParameters2D.create(global_position, candidate.global_position, 1, [get_rid()])
			if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
				nearest = distance
				target_interactable = candidate

func set_flashlight(enabled: bool) -> void:
	flashlight_enabled = enabled
	$Visual/Flashlight.visible = enabled
	EventBus.flashlight_changed.emit(enabled)
	EventBus.audio_requested.emit("flashlight")
	play_action("flashlight")

func enter_hiding(spot: Node2D) -> void:
	hidden_spot = spot
	velocity = Vector2.ZERO
	set_flashlight(false)
	visual.modulate.a = 0.18
	EventBus.player_hidden.emit(spot.interaction_id)

func leave_hiding() -> void:
	if hidden_spot == null:
		return
	var id: String = hidden_spot.interaction_id
	hidden_spot = null
	visual.modulate.a = 1.0
	EventBus.player_left_hiding.emit(id)

func _caught() -> void:
	control_enabled = false
	velocity = Vector2.ZERO
	visual.scale.y = 1.0
	visual.modulate.a = 1.0
	play_animation("death")

func _update_animation(axis: Vector2, speed: float) -> void:
	$Visual/Flashlight.rotation = facing.angle()
	if animation_hold > 0.0:
		return
	var animation := "idle"
	if axis.length() > 0.01:
		animation = "run" if speed == sprint_speed else "walk"
	play_animation(animation)
	sprite.speed_scale = 0.6 if is_crouching else 1.0

func play_action(animation: String, seconds: float = 1.0) -> void:
	animation_hold = maxf(seconds, 1.0)
	play_animation(animation)
	sprite.set_frame_and_progress(0, 0.0)

func play_animation(animation: String) -> void:
	animation_state = animation
	sprite.speed_scale = 1.0
	CharacterAnimation.play(sprite, animation, facing)
