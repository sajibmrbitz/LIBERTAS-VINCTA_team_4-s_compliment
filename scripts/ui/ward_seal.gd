extends Control
## Native ward drawing: three bound marks, no spinner or progression indicator.
@export var animate: bool = true
var elapsed: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(animate)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.32
	var brass := get_theme_color("font_color", "NarrativeAccent")
	brass.a = 0.3
	draw_arc(center, radius, 0.0, TAU, 96, brass, 1.0, true)
	draw_line(center + Vector2(-radius * 1.3, 0), center + Vector2(radius * 1.3, 0), brass, 1.0, true)
	for index in range(3):
		var x := center.x + (index - 1) * radius * 0.5
		var mark := brass
		mark.a = 0.4 + (0.10 * sin(elapsed * 0.8) if index == 1 and animate else 0.0)
		draw_line(Vector2(x, center.y - radius * 0.38), Vector2(x, center.y + radius * 0.38), mark, 2.0, true)
		draw_line(Vector2(x - 4, center.y - radius * 0.38), Vector2(x + 4, center.y - radius * 0.38), mark, 1.0, true)
