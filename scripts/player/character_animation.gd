extends RefCounted
## Both resources share the same eight ground-plane direction suffixes.
const DIRECTIONS := ["s", "sw", "w", "nw", "n", "ne", "e", "se"]

static func direction_name(facing: Vector2) -> String:
	return DIRECTIONS[posmod(roundi((facing.angle() - PI / 2.0) / (PI / 4.0)), 8)]

static func play(sprite: AnimatedSprite2D, action: String, facing: Vector2) -> bool:
	# Art is optional: never send an absent animation to AnimatedSprite2D.
	if sprite.sprite_frames == null:
		return false
	var direction := direction_name(facing)
	var candidates: Array[String] = [action + "_" + direction, action]
	if action == "run":
		candidates.append("walk_" + direction)
	candidates.append("idle_" + direction)
	candidates.append("idle")
	var next: StringName = &""
	for candidate in candidates:
		if sprite.sprite_frames.has_animation(candidate) and sprite.sprite_frames.get_frame_count(candidate) > 0:
			next = candidate
			break
	if next == &"":
		return false
	if sprite.animation == next:
		return true
	# Preserve gait phase when turning, but start new actions at frame zero.
	var same_action := String(sprite.animation).get_slice("_", 0) == String(next).get_slice("_", 0)
	var frame := sprite.frame
	var progress := sprite.frame_progress
	sprite.play(next)
	if same_action:
		sprite.set_frame_and_progress(mini(frame, sprite.sprite_frames.get_frame_count(next) - 1), progress)
	return true
