extends Node
## Assign real streams on the Main/Audio scene instance; empty slots remain silent.
@export var rain: AudioStream
@export var drip: AudioStream
@export var breathing: AudioStream
@export var building_creak: AudioStream
@export var house_ambience: AudioStream
@export var wood_footsteps: AudioStream
@export var stone_footsteps: AudioStream
@export var water_footsteps: AudioStream
@export var key_sting: AudioStream
@export var monster_breathing: AudioStream
@export var monster_search: AudioStream
@export var door: AudioStream
@export var lockpick: AudioStream
@export var flashlight: AudioStream
@export var ui: AudioStream
@export var calm_music: AudioStream
@export var searching_music: AudioStream
@export var chase_music: AudioStream
var players: Dictionary = {}
var tension: String = ""
var fade_tween: Tween

func _ready() -> void:
	for cue in ["rain", "drip", "breathing", "building_creak", "house_ambience", "wood_footsteps", "stone_footsteps", "water_footsteps", "key_sting", "monster_breathing", "monster_search", "door", "lockpick", "flashlight", "ui"]:
		var audio := AudioStreamPlayer.new()
		audio.name = cue.to_pascal_case()
		audio.bus = "Ambience" if cue in ["rain", "drip", "breathing", "building_creak", "house_ambience"] else "SFX"
		audio.stream = get(cue)
		add_child(audio)
		players[cue] = audio
		if cue in ["rain", "house_ambience"]:
			audio.finished.connect(audio.play)
	for state in ["CALM", "SEARCHING", "CHASE"]:
		var audio := AudioStreamPlayer.new()
		audio.name = state
		audio.bus = "Music"
		audio.stream = get(state.to_lower() + "_music")
		audio.volume_db = -60.0
		add_child(audio)
		players[state] = audio
		audio.finished.connect(audio.play)
	EventBus.audio_requested.connect(play_cue)
	EventBus.tension_changed.connect(set_tension)
	EventBus.sense_restored.connect(func(_sense): play_cue("key_sting"))
	play_cue("house_ambience")
	set_tension("CALM")

func play_cue(cue: String) -> void:
	if players.has(cue) and players[cue].stream != null:
		players[cue].play()

func set_tension(state: String) -> void:
	if state == tension:
		return
	tension = state
	if fade_tween != null:
		fade_tween.kill()
	fade_tween = create_tween().set_parallel(true)
	for candidate in ["CALM", "SEARCHING", "CHASE"]:
		var audio: AudioStreamPlayer = players[candidate]
		if candidate == state and audio.stream != null and not audio.playing:
			audio.play()
		fade_tween.tween_property(audio, "volume_db", -8.0 if candidate == state else -60.0, 1.2)
