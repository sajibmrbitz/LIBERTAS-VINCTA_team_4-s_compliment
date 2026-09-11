extends Node
## Presentation only. The existing NoiseModel emits enemy-hearing information.
@export var wood_samples: Array[AudioStream] = []
## Optional future surface -> Array[AudioStream] overrides. Unknown/empty banks use wood.
@export var surface_samples: Dictionary = {}
@export var crouch_volume_db: float = -20.0
@export var walk_volume_db: float = -10.0
@export var sprint_volume_db: float = -4.0
@export_range(0.0, 0.05) var pitch_variation: float = 0.025
var last_sample: AudioStream
var next_voice: int = 0
var random := RandomNumberGenerator.new()
@onready var player: CharacterBody2D = get_parent()
@onready var voices: Array[AudioStreamPlayer] = [$Voice1, $Voice2]

func _ready() -> void:
	random.randomize()

func _physics_process(_delta: float) -> void:
	# Stop residual tails as soon as movement/control stops; pause is inherited.
	if not _can_step():
		for voice in voices:
			if voice.playing:
				voice.stop()

func _can_step() -> bool:
	return player.control_enabled and GameManager.state == GameManager.State.PLAYING and player.hidden_spot == null and player.get_real_velocity().length() > 10.0

func play_step(surface: String, gait: String) -> void:
	if not _can_step():
		return
	var samples: Array[AudioStream] = []
	var configured: Variant = surface_samples.get(surface, wood_samples)
	if configured is Array:
		for sample in configured:
			if sample is AudioStream:
				samples.append(sample)
	if samples.is_empty():
		for sample in wood_samples:
			if sample != null:
				samples.append(sample)
	if samples.is_empty():
		return
	# Compare streams, not indices, so switching fallback surfaces avoids repeats too.
	var choices: Array[AudioStream] = []
	for sample in samples:
		if sample != last_sample:
			choices.append(sample)
	if choices.is_empty():
		choices = samples
	last_sample = choices[random.randi_range(0, choices.size() - 1)]
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = last_sample
	voice.volume_db = crouch_volume_db if gait == "crouch" else (sprint_volume_db if gait == "sprint" else walk_volume_db)
	voice.pitch_scale = random.randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	voice.play()
