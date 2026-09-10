extends Node
const MULTIPLIERS := {"CARPET": 0.35, "WOOD": 1.0, "STONE": 0.85, "WATER": 1.65, "GLASS": 2.0, "GENERIC": 1.0}
func emit_step(point: Vector2, intensity: float, surface: String) -> void:
	EventBus.noise_created.emit(point, intensity * float(MULTIPLIERS.get(surface, 1.0)), surface)
	var cue := "water_footsteps" if surface == "WATER" else ("stone_footsteps" if surface == "STONE" else "wood_footsteps")
	EventBus.audio_requested.emit(cue)
