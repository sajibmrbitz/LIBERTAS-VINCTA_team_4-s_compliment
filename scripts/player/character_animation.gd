extends RefCounted
## Both resources share the same eight ground-plane direction suffixes.
const DIRECTIONS := ["s", "sw", "w", "nw", "n", "ne", "e", "se"]

static func direction_name(facing: Vector2) -> String:
	return DIRECTIONS[posmod(roundi((facing.angle() - PI / 2.0) / (PI / 4.0)), 8)]

static func play(sprite: AnimatedSprite2D, action: String, facing: Vector2) -> void:
	var next := action + "_" + direction_name(facing)
	if sprite.animation == next:
		return
	# Preserve gait phase when turning, but start new actions at frame zero.
	var same_action := String(sprite.animation).get_slice("_", 0) == action
	var frame := sprite.frame
	var progress := sprite.frame_progress
	sprite.play(next)
	if same_action:
		sprite.set_frame_and_progress(frame, progress)
