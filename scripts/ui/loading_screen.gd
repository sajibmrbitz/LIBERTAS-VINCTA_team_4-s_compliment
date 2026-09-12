extends Control
## Timed presentation, followed by normal scene loading behind an opaque curtain.
@export_file("*.tscn") var target_scene: String = "res://scenes/main/main.tscn"
@export_range(0.5, 15.0) var display_seconds: float = 5.0
@export var ambience: AudioStream
var failed: bool = false
@onready var curtain: ColorRect = $Curtain
@onready var status_label: Label = $Status
@onready var back_button: Button = $Back
@onready var loading_button: Button = $LoadingButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	back_button.hide()
	back_button.pressed.connect(GameManager.go_home)
	if DisplayServer.get_name() == "headless":
		_enter_game.call_deferred()
		return
	if ambience != null:
		$Ambience.stream = ambience
		$Ambience.play()
	# Begin the five-second presentation after the screen has had a frame to draw.
	await RenderingServer.frame_post_draw
	await get_tree().create_timer(maxf(display_seconds - 0.32, 0.0), true, false, true).timeout
	var tween := create_tween().set_parallel(true)
	tween.tween_property(curtain, "color:a", 1.0, 0.32)
	tween.tween_property($Ambience, "volume_db", -60.0, 0.32)
	await tween.finished
	# Submit opaque black before synchronous resource preparation/instantiation.
	await RenderingServer.frame_post_draw
	_enter_game.call_deferred()

func _enter_game() -> void:
	# Avoid the threaded dependency wait that left this screen stuck.
	var scene := ResourceLoader.load(target_scene, "PackedScene") as PackedScene
	if scene == null or not scene.can_instantiate():
		_fail("Could not load an instantiable scene: " + target_scene)
		return
	var error := get_tree().change_scene_to_packed(scene)
	if error != OK:
		_fail("Could not enter %s (error %s)." % [target_scene, error])

func _fail(reason: String) -> void:
	push_error("LoadingScreen: " + reason)
	failed = true
	curtain.color.a = 0.0
	loading_button.hide()
	status_label.text = "HOLLOWMERE COULD NOT BE OPENED.\nRETURN HOME AND TRY AGAIN."
	back_button.show()
	back_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	if failed and event.is_action_pressed("pause"):
		GameManager.go_home()
