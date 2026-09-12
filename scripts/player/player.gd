extends CharacterBody2D

const CharacterAnimation := preload("res://scripts/player/character_animation.gd")
const EstateArt := preload("res://scripts/levels/estate_art.gd")
const SigilField := preload("res://scripts/player/sigil_field.gd")

@export var walk_speed: float = 141.0
@export var sprint_speed: float = 256.0
@export var crouch_speed: float = 70.0
@export_range(0.1, 1.0) var depth_ratio: float = 0.55
@export var acceleration: float = 1100.0
@export var interaction_radius: float = 76.0
@export var breath_capacity: float = 6.0
@export var breath_cooldown_seconds: float = 15.0

var control_enabled: bool = true
var is_crouching: bool = false
var is_sprinting: bool = false
var holding_breath: bool = false
var breath_seconds: float = 0.0
var breath_cooldown: float = 0.0
var hidden_spot: Node2D
var flashlight_enabled: bool = false
var facing: Vector2 = Vector2.RIGHT
var noise_clock: float = 0.0
var target_interactable: Node2D
var animation_state: String = "idle"
var animation_hold: float = 0.0
var sigil_cooldown: float = 0.0
var stun_cooldown: float = 0.0
var touch_evasion_cooldown: float = 0.0

@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var held_flashlight: Sprite2D = $Visual/HeldFlashlight

func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	EventBus.player_caught.connect(_caught)
	held_flashlight.texture = EstateArt.new().texture_for("flashlight_pickup")
	held_flashlight.scale = Vector2.ONE * 14.0 / held_flashlight.texture.get_width()
	play_animation("idle")

func _process(_delta: float) -> void:
	_update_flashlight_presentation()
	queue_redraw()

func _physics_process(delta: float) -> void:
	animation_hold = maxf(0.0, animation_hold - delta)
	breath_cooldown = maxf(0.0, breath_cooldown - delta)
	sigil_cooldown = maxf(0.0, sigil_cooldown - delta)
	stun_cooldown = maxf(0.0, stun_cooldown - delta)
	touch_evasion_cooldown = maxf(0.0, touch_evasion_cooldown - delta)
	_update_flashlight_charge(delta)
	_update_breath(delta)
	target_interactable = null
	if not control_enabled or GameManager.state != GameManager.State.PLAYING:
		velocity = Vector2.ZERO
		return
	if Input.is_action_just_pressed("flashlight") and FreedomLedger.flags.get("flashlight", false) and hidden_spot == null:
		set_flashlight(not flashlight_enabled)
	if Input.is_action_just_pressed("gadget"):
		use_gadget()
	if Input.is_action_just_pressed("ability"):
		use_sigil()
	if Input.is_action_just_pressed("stun"):
		use_stun()
	if hidden_spot != null:
		if Input.is_action_just_pressed("interact"):
			leave_hiding()
		return
	is_crouching = Input.is_action_pressed("crouch")
	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching
	var axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed := crouch_speed if is_crouching else (sprint_speed if is_sprinting else walk_speed)
	var desired := Vector2(axis.x, axis.y * depth_ratio) * speed
	velocity = velocity.move_toward(desired, acceleration * delta)
	move_and_slide()
	_register_touch_evasion()
	if axis.length_squared() > 0.01:
		facing = axis.normalized()
	_update_animation(axis, speed)
	visual.scale.y = 0.65 if is_crouching else 1.0
	noise_clock -= delta
	if get_real_velocity().length() > 10.0 and noise_clock <= 0.0 and not holding_breath:
		noise_clock = 0.52 if is_crouching else (0.27 if is_sprinting else 0.42)
		var intensity := 0.06 if is_crouching else (1.0 if is_sprinting else 0.24)
		var room = get_tree().get_first_node_in_group("room")
		var surface: String = room.surface_at(global_position) if room != null else "GENERIC"
		var emitted_surface := ("CARPET" if is_crouching else "GLASS") if surface == "CREAK" else surface
		NoiseModel.emit_step(global_position, intensity, emitted_surface)
		var gait := "crouch" if is_crouching else ("sprint" if is_sprinting else "walk")
		$FootstepAudio.play_step("WOOD" if surface == "CREAK" else surface, gait)
	_find_interactable()
	if Input.is_action_just_pressed("interact") and is_instance_valid(target_interactable):
		target_interactable.interact(self)

func _update_flashlight_charge(delta: float) -> void:
	if not flashlight_enabled:
		return
	var drain := 3.0 if is_sprinting else 1.0
	FreedomLedger.set_flashlight_seconds(FreedomLedger.flashlight_seconds - delta * drain)
	if FreedomLedger.flashlight_seconds <= 0.0:
		set_flashlight(false)

func _update_breath(delta: float) -> void:
	var wants_breath := Input.is_action_pressed("hold_breath") and breath_cooldown <= 0.0 and hidden_spot == null
	if wants_breath and breath_seconds < breath_capacity:
		holding_breath = true
		breath_seconds += delta
	else:
		if holding_breath:
			breath_cooldown = breath_cooldown_seconds
		holding_breath = false
		breath_seconds = 0.0

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
	flashlight_enabled = enabled and FreedomLedger.flashlight_seconds > 0.0
	$FlashlightFloor.visible = flashlight_enabled
	EventBus.flashlight_changed.emit(flashlight_enabled)
	EventBus.audio_requested.emit("flashlight")
	play_action("flashlight")

func use_gadget() -> bool:
	if FreedomLedger.flashlight_seconds < 50.0 and FreedomLedger.consume_item("battery"):
		FreedomLedger.set_flashlight_seconds(FreedomLedger.flashlight_seconds + 45.0)
		EventBus.ability_used.emit("battery")
		return true
	var gadget := "bottle" if int(FreedomLedger.inventory.get("bottle", 0)) > 0 else "clock"
	if not FreedomLedger.consume_item(gadget):
		return false
	var point := global_position + facing * (260.0 if gadget == "bottle" else 180.0)
	EventBus.noise_created.emit(point, 576.0 if gadget == "bottle" else 384.0, "GLASS" if gadget == "bottle" else "GENERIC")
	EventBus.ability_used.emit(gadget)
	return true

func _register_touch_evasion() -> void:
	if GameManager.zone != "echoes" or not FreedomLedger.part2_seed.get("touch_mutation", false) or touch_evasion_cooldown > 0.0:
		return
	var room = get_tree().get_first_node_in_group("room")
	if room == null or room.surface_at(global_position) != "RUBBLE" or get_real_velocity().length() < 20.0:
		return
	var enemy = get_tree().get_first_node_in_group("enemy")
	if enemy != null and global_position.distance_to(enemy.global_position) <= 520.0:
		FreedomLedger.mechanic_uses += 1
		touch_evasion_cooldown = 2.0
		EventBus.ability_used.emit("touch_evasion")

func use_sigil() -> bool:
	if GameManager.zone not in ["echoes", "nexus"] or not FreedomLedger.flags.get("part2_ability_unlocked", false) or sigil_cooldown > 0.0:
		return false
	var cost := FreedomLedger.max_hp * (0.04 if FreedomLedger.part2_seed.get("hybrid_magic", false) else 0.08)
	if FreedomLedger.hp <= cost:
		return false
	FreedomLedger.damage(cost)
	FreedomLedger.mechanic_uses += 1
	FreedomLedger.flags["sigil_until"] = Time.get_ticks_msec() + 12000
	FreedomLedger.flags["sigil_x"] = global_position.x
	FreedomLedger.flags["sigil_y"] = global_position.y
	sigil_cooldown = 20.0
	_spawn_sigil(192.0, 12.0, Color(0.46, 0.11, 0.13, 0.68))
	EventBus.ability_used.emit("blood_sigil")
	return true

func use_stun() -> bool:
	if not FreedomLedger.part2_seed.get("blood_magic", false) or not FreedomLedger.flags.get("part2_ability_unlocked", false) or stun_cooldown > 0.0:
		return false
	var cost := FreedomLedger.max_hp * 0.20
	if FreedomLedger.hp <= cost:
		return false
	FreedomLedger.damage(cost)
	stun_cooldown = 60.0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if global_position.distance_to(enemy.global_position) <= 192.0 and enemy.has_method("stun"):
			enemy.stun(6.0)
	_spawn_sigil(192.0, 0.8, Color(0.72, 0.16, 0.18, 0.8))
	EventBus.ability_used.emit("blood_stun")
	return true

func _spawn_sigil(radius: float, lifetime: float, color: Color) -> void:
	var effect := Node2D.new()
	effect.set_script(SigilField)
	effect.radius = radius
	effect.lifetime = lifetime
	effect.tint = color
	effect.global_position = global_position
	get_tree().current_scene.add_child(effect)

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

func take_hit(amount: float = 25.0) -> void:
	if FreedomLedger.damage(amount):
		EventBus.player_caught.emit()
	else:
		play_action("damage", 0.55)

func _caught() -> void:
	control_enabled = false
	velocity = Vector2.ZERO
	visual.scale.y = 1.0
	visual.modulate.a = 1.0
	play_animation("death")

func _update_animation(axis: Vector2, speed: float) -> void:
	$FlashlightFloor.rotation = facing.angle()
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
	if sprite.visible:
		sprite.play()
		sprite.set_frame_and_progress(0, 0.0)

func play_animation(animation: String) -> void:
	animation_state = animation
	sprite.speed_scale = 1.0
	var has_art := CharacterAnimation.play(sprite, animation, facing)
	sprite.visible = has_art
	$Visual/PlaceholderVisual.visible = not has_art

func _update_flashlight_presentation() -> void:
	var has_flashlight: bool = bool(FreedomLedger.flags.get("flashlight", false))
	held_flashlight.visible = has_flashlight and hidden_spot == null and not (animation_state == "flashlight" and animation_hold > 0.05)
	held_flashlight.position = Vector2(facing.x * 15.0, -28.0 + facing.y * 7.0)
	held_flashlight.rotation = facing.angle() - deg_to_rad(160.0)
	held_flashlight.z_index = -1 if facing.y < -0.25 else 2
	held_flashlight.modulate = Color.WHITE if flashlight_enabled else Color(0.62, 0.65, 0.65, 1.0)

func _draw() -> void:
	if not FreedomLedger.part2_seed.get("touch_mutation", false):
		return
	var room = get_tree().get_first_node_in_group("room")
	if room == null or room.surface_at(global_position) != "STONE":
		return
	for enemy in get_tree().get_nodes_in_group("enemy"):
		var distance := global_position.distance_to(enemy.global_position)
		if distance <= 480.0:
			var local_target := to_local(enemy.global_position)
			draw_circle(local_target.normalized() * minf(56.0, distance * 0.15), 5.0, Color(0.35, 0.76, 0.76, 0.55), false, 2.0)
