extends CharacterBody2D

@export_range(0.0, 1000.0) var walk_speed: float = 160.0
@export_range(0.0, 1000.0) var sprint_speed: float = 260.0
@export_range(0.0, 1000.0) var crouch_speed: float = 80.0
@export_range(0.0, 5000.0) var gravity: float = 1200.0
@export_range(0.0, 5000.0) var terminal_velocity: float = 1000.0

const STANDING_SIZE := Vector2(28.0, 56.0)
const CROUCHING_SIZE := Vector2(28.0, 32.0)

var is_crouching: bool = false
var standing_shape := RectangleShape2D.new()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var placeholder_visual: Polygon2D = $PlaceholderVisual


func _ready() -> void:
	standing_shape.size = STANDING_SIZE
	$Camera2D.reset_smoothing()


func _physics_process(delta: float) -> void:
	_update_crouch()
	# A single horizontal axis keeps movement stable; opposite inputs cancel.
	var direction := Input.get_axis("move_left", "move_right")
	var speed := walk_speed
	if is_crouching:
		speed = crouch_speed
	elif Input.is_action_pressed("sprint"):
		speed = sprint_speed
	velocity.x = direction * speed
	velocity.y = minf(velocity.y + gravity * delta, terminal_velocity)
	move_and_slide()


func _update_crouch() -> void:
	var wants_crouch := Input.is_action_pressed("crouch")
	if not wants_crouch and is_crouching and not _can_stand():
		wants_crouch = true
	if wants_crouch == is_crouching:
		return
	is_crouching = wants_crouch
	var body_size := CROUCHING_SIZE if is_crouching else STANDING_SIZE
	(collision_shape.shape as RectangleShape2D).size = body_size
	collision_shape.position.y = -body_size.y / 2.0
	# Change placeholder posture without moving the feet or adding animations.
	placeholder_visual.scale.y = body_size.y / STANDING_SIZE.y


func _can_stand() -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = standing_shape
	query.transform = global_transform * Transform2D(0.0, Vector2(0.0, -STANDING_SIZE.y / 2.0))
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()
