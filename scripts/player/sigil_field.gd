extends Node2D

var radius: float = 192.0
var lifetime: float = 12.0
var tint: Color = Color(0.46, 0.11, 0.13, 0.68)
var age: float = 0.0

func _ready() -> void:
	z_index = -2
	queue_redraw()

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var alpha := clampf(1.0 - age / lifetime, 0.0, 1.0)
	var color := tint
	color.a *= alpha
	draw_circle(Vector2.ZERO, radius, Color(color, color.a * 0.10))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, color, 3.0)
	for i in 4:
		var angle := float(i) * PI * 0.5 + PI * 0.25
		draw_line(Vector2.ZERO, Vector2.from_angle(angle) * radius * 0.74, color, 2.0)
