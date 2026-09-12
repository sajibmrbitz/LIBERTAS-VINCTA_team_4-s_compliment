extends Node
## Animates the generated closed-door sprite around its left edge.
var door_sprite: Sprite2D
var destination_label: Label
var closed_position: Vector2
var closed_scale: Vector2
var closed_rotation: float
var open_position: Vector2
var open_scale: Vector2
var arrival_completed: bool = false

func configure(sprite: Sprite2D, label: Label) -> void:
	door_sprite = sprite
	destination_label = label
	closed_position = sprite.position
	closed_scale = sprite.scale
	closed_rotation = sprite.rotation
	var width := sprite.texture.get_width() * closed_scale.x
	open_scale = Vector2(closed_scale.x * 0.28, closed_scale.y)
	open_position = closed_position + Vector2(-width * 0.36, 0)

func set_open_immediate(opened: bool) -> void:
	if not is_instance_valid(door_sprite):
		return
	door_sprite.position = open_position if opened else closed_position
	door_sprite.scale = open_scale if opened else closed_scale
	door_sprite.rotation = deg_to_rad(-4.0) if opened else closed_rotation
	if is_instance_valid(destination_label):
		destination_label.modulate.a = 0.0 if opened else 1.0

func animate_open(opened: bool, duration: float = 0.42) -> void:
	if not is_instance_valid(door_sprite):
		return
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(door_sprite, "position", open_position if opened else closed_position, duration)
	tween.tween_property(door_sprite, "scale", open_scale if opened else closed_scale, duration)
	tween.tween_property(door_sprite, "rotation", deg_to_rad(-4.0) if opened else closed_rotation, duration)
	if is_instance_valid(destination_label):
		tween.tween_property(destination_label, "modulate:a", 0.0 if opened else 1.0, duration * 0.7)
	await tween.finished

func depart(player: CharacterBody2D) -> void:
	var doorway: Vector2 = get_parent().get_parent().global_position
	player.control_enabled = false
	player.velocity = Vector2.ZERO
	player.facing = Vector2.UP
	var staging := doorway + Vector2(0, 56)
	var align := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	align.tween_property(player, "global_position", staging, 0.22)
	await align.finished
	EventBus.audio_requested.emit("door")
	await animate_open(true)
	player.animation_hold = 0.0
	player.play_animation("walk")
	var enter := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	enter.tween_property(player, "global_position", doorway + Vector2(0, 8), 0.48)
	enter.tween_property(player.get_node("Visual"), "modulate:a", 0.0, 0.38).set_delay(0.10)
	await enter.finished

func arrive(player: CharacterBody2D) -> void:
	var doorway: Vector2 = get_parent().get_parent().global_position
	set_open_immediate(true)
	player.control_enabled = false
	player.velocity = Vector2.ZERO
	player.global_position = doorway + Vector2(0, 8)
	player.facing = Vector2.DOWN
	player.get_node("Visual").modulate.a = 0.0
	player.animation_hold = 0.0
	player.play_animation("walk")
	var emerge := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	emerge.tween_property(player, "global_position", doorway + Vector2(0, 56), 0.52)
	emerge.tween_property(player.get_node("Visual"), "modulate:a", 1.0, 0.34)
	await emerge.finished
	player.play_animation("idle")
	EventBus.audio_requested.emit("door")
	await animate_open(false)
	player.control_enabled = true
	arrival_completed = true
