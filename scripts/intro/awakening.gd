extends Node
## Presentation-only recovery. All timers/tweens/animation respect gameplay pause.
@export var prone_animation: StringName = &"death_w"
@export var use_reverse_collapse_for_wake: bool = true
@export_range(0.5, 1.0) var wake_speed: float = 0.8
@export_range(1.08, 1.12) var intimate_zoom: float = 1.10
var presentation: StringName = &""

func begin(player: Node2D, hud: CanvasLayer) -> void:
	GameManager.state = GameManager.State.INTRO
	player.control_enabled = false
	player.velocity = Vector2.ZERO
	var sprite: AnimatedSprite2D = player.get_node("Visual/AnimatedSprite2D")
	var camera: Camera2D = player.get_node("Camera2D")
	var normal_zoom := camera.zoom
	var shadow: Polygon2D = player.get_node("Visual/Shadow")
	var normal_shadow := shadow.scale
	camera.zoom = normal_zoom * intimate_zoom
	hud.fade.color = Color.BLACK
	presentation = &"INTRO_PRONE"
	# death_w row 2, column 11: face toward floor, arms folded underneath.
	# No death signal/state/audio and no transform changes to body or collision.
	var has_pose := sprite.sprite_frames != null and sprite.sprite_frames.has_animation(prone_animation)
	if has_pose:
		has_pose = sprite.sprite_frames.get_frame_count(prone_animation) > 0
	if has_pose:
		sprite.animation = prone_animation
		sprite.pause()
		sprite.set_frame_and_progress(sprite.sprite_frames.get_frame_count(prone_animation) - 1, 1.0)
		shadow.scale = Vector2(1.7, 0.65)
	else:
		push_warning("Awakening: collapsed animation missing; concealing body until recovery.")
		player.get_node("Visual").modulate.a = 0.0
	_add_dropped_flashlight_beam()
	EventBus.audio_requested.emit("rain")
	await _wait(0.5)
	EventBus.audio_requested.emit("drip")
	await _wait(0.6)
	EventBus.audio_requested.emit("drip")
	EventBus.audio_requested.emit("breathing")
	await _wait(0.1)
	var reveal := create_tween()
	reveal.tween_property(hud.fade, "color:a", 0.0, 1.4)
	await reveal.finished
	EventBus.audio_requested.emit("building_creak")
	await _say("...Where am I?", 1.7, 0.2)
	await _say("Els Vantree... Hollowmere. The appraisal.", 2.1, 0.2)
	await _say("They offered too much. I signed without reading the addendum.", 2.5, 0.2)
	EventBus.subtitle_requested.emit("ELS", "After that... nothing. Six hours just gone.", 2.2)
	presentation = &"INTRO_WAKING"
	var pullback := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	pullback.tween_property(camera, "zoom", normal_zoom, 1.25)
	pullback.tween_property(shadow, "scale", normal_shadow, 1.25)
	if has_pose and use_reverse_collapse_for_wake and not sprite.sprite_frames.get_animation_loop(prone_animation):
		sprite.speed_scale = 1.0
		sprite.play(prone_animation, -wake_speed, true)
	else:
		# Short body dissolve is the alternative to reversing supplied collapse art.
		var dissolve := create_tween()
		dissolve.tween_property(player.get_node("Visual"), "modulate:a", 0.0, 0.18)
		dissolve.tween_callback(func(): _standing(player))
		dissolve.tween_property(player.get_node("Visual"), "modulate:a", 1.0, 0.18)
	# Current 12 frames at 12 FPS / .8 finish in 1.25s. Keep final line readable.
	await _wait(2.2)
	_standing(player)
	camera.zoom = normal_zoom
	shadow.scale = normal_shadow
	player.get_node("Visual").modulate.a = 1.0
	presentation = &""
	player.control_enabled = true
	GameManager.state = GameManager.State.PLAYING

func _standing(player: Node2D) -> void:
	player.facing = Vector2.LEFT
	player.animation_hold = 0.0
	player.play_animation("idle")
	var sprite: AnimatedSprite2D = player.get_node("Visual/AnimatedSprite2D")
	sprite.speed_scale = 1.0
	if sprite.visible:
		sprite.play()

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout

func _say(line: String, seconds: float, gap: float) -> void:
	EventBus.subtitle_requested.emit("ELS", line, seconds)
	await _wait(seconds + gap)

func _add_dropped_flashlight_beam() -> void:
	for prop in get_tree().get_nodes_in_group("interactable"):
		if prop.interaction_id == "flashlight":
			var beam := Polygon2D.new()
			beam.name = "DroppedBeamPlaceholder"
			beam.color = Color(0.8, 0.78, 0.6, 0.10)
			beam.polygon = PackedVector2Array([Vector2(14, -3), Vector2(145, -24), Vector2(145, 24), Vector2(14, 3)])
			beam.z_index = -1
			# Faces away from Els. Parent pickup hides it when its existing flag is set.
			prop.add_child(beam)
			return
