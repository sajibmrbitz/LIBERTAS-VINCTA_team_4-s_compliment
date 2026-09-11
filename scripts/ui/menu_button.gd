extends Button
## Text selection with identical pointer and keyboard feedback.
@export var caption: String = "BACK"
@export var sound_cue: String = "ui_confirm"
var motion: Tween
var highlighted: bool = false
@onready var visual: Control = $Visual
@onready var label: Label = $Visual/Caption
@onready var accent: ColorRect = $Accent

func _ready() -> void:
	label.text = caption
	accent.color = get_theme_color("font_hover_color", "Button")
	accent.modulate.a = 0.0
	label.modulate = get_theme_color("font_color", "Button")
	mouse_entered.connect(update_highlight)
	mouse_exited.connect(update_highlight)
	focus_entered.connect(update_highlight)
	focus_exited.connect(update_highlight)
	button_down.connect(press_feedback)
	button_up.connect(update_highlight)
	pressed.connect(func(): EventBus.audio_requested.emit(sound_cue))

func update_highlight() -> void:
	var active := has_focus() or is_hovered()
	if active and not highlighted:
		EventBus.audio_requested.emit("ui_hover")
	highlighted = active
	if motion:
		motion.kill()
	motion = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	motion.tween_property(visual, "position:x", 8.0 if active else 0.0, 0.15)
	motion.tween_property(visual, "scale", Vector2.ONE * (1.02 if active else 1.0), 0.15)
	motion.tween_property(accent, "modulate:a", 1.0 if active else 0.0, 0.15)
	motion.tween_property(label, "modulate", get_theme_color("font_hover_color" if active else "font_color", "Button"), 0.15)

func press_feedback() -> void:
	if motion:
		motion.kill()
	motion = create_tween()
	motion.tween_property(visual, "scale", Vector2.ONE * 0.985, 0.06)
