extends Node
## Assign optional streams here; empty hooks intentionally remain silent.
@export var ui_hover: AudioStream
@export var ui_confirm: AudioStream
@export var ui_back: AudioStream
var voice: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	voice = AudioStreamPlayer.new()
	voice.bus = "SFX"
	add_child(voice)
	EventBus.audio_requested.connect(play_cue)

func play_cue(cue: String) -> void:
	var streams := {"ui_hover": ui_hover, "ui_confirm": ui_confirm, "ui_back": ui_back}
	var stream: AudioStream = streams.get(cue)
	if stream != null:
		voice.stream = stream
		voice.play()
