extends Node
## Gameplay hearing only. Audible footsteps are owned by Player/FootstepAudio.
const RADII := {"CARPET": 64.0, "WOOD": 256.0, "STONE": 320.0, "RUBBLE": 160.0, "WATER": 448.0, "GLASS": 576.0, "GENERIC": 256.0}

func emit_step(point: Vector2, intensity: float, surface: String) -> void:
	var radius := float(RADII.get(surface, RADII.GENERIC))
	if intensity >= 0.9:
		radius += 128.0
	elif intensity <= 0.1:
		radius *= 0.45
	EventBus.noise_created.emit(point, radius, surface)
