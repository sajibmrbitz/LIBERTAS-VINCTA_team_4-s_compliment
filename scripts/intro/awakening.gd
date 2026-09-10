extends Node
## Silent-safe timed introduction. All waits respect pause.
func begin(player: Node2D, hud: CanvasLayer) -> void:
	GameManager.state = GameManager.State.INTRO
	player.control_enabled = false
	player.get_node("Visual").rotation = -PI / 2.0
	hud.fade.color.a = 1.0
	EventBus.audio_requested.emit("rain")
	await get_tree().create_timer(0.7, false).timeout
	EventBus.audio_requested.emit("drip")
	await get_tree().create_timer(0.9, false).timeout
	EventBus.audio_requested.emit("drip")
	EventBus.audio_requested.emit("breathing")
	var tween := create_tween()
	tween.tween_property(hud.fade, "color:a", 0.0, 2.0)
	await tween.finished
	EventBus.subtitle_requested.emit("ELS", "...Where am I?", 2.5)
	EventBus.audio_requested.emit("building_creak")
	await get_tree().create_timer(2.5, false).timeout
	var rise := create_tween()
	rise.tween_property(player.get_node("Visual"), "rotation", 0.0, 0.7)
	await rise.finished
	player.control_enabled = true
	GameManager.state = GameManager.State.PLAYING
