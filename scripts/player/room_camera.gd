extends Camera2D
@export var horizontal_response: float = 9.0
@export var vertical_response: float = 4.0
@export var vertical_tracking: float = 0.25
var player: Node2D
var room_center_y: float = 430.0
var focus: Vector2
var focus_seconds: float = 0.0
var trauma: float = 0.0
var shake_clock: float = 0.0

func _ready() -> void:
	top_level = true
	position_smoothing_enabled = false
	player = get_parent()
	EventBus.player_detected.connect(func(_source): add_trauma(0.55))
	EventBus.sense_restored.connect(func(_sense): add_trauma(0.8))
	EventBus.player_hurt.connect(func(_amount): add_trauma(0.7))
	snap_to_player()

func snap_to_player() -> void:
	if player == null:
		player = get_parent()
	global_position = Vector2(player.global_position.x, room_center_y)
	reset_smoothing()

func cinematic_focus(point: Vector2, seconds: float) -> void:
	focus = point
	focus_seconds = seconds

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	shake_clock += delta
	trauma = maxf(0.0, trauma - delta * 1.35)
	var target := Vector2(player.global_position.x, room_center_y + (player.global_position.y - 480.0) * vertical_tracking)
	if focus_seconds > 0.0:
		focus_seconds -= delta
		target = focus
	global_position.x = lerpf(global_position.x, target.x, 1.0 - exp(-horizontal_response * delta))
	global_position.y = lerpf(global_position.y, target.y, 1.0 - exp(-vertical_response * delta))
	var strength := trauma * trauma
	offset = Vector2(sin(shake_clock * 43.0), cos(shake_clock * 37.0)) * strength * 8.0

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)
