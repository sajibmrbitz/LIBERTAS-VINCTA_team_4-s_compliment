extends Node2D
## Presentation only: the parent pickup still owns availability and collection.
var is_key := false
var elapsed := 0.0

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var backing := PackedVector2Array([Vector2(-28, -16), Vector2(0, -36), Vector2(28, -16), Vector2(0, 4)])
	draw_colored_polygon(backing, Color(0.025, 0.04, 0.035, 0.85))
	var accent := Color("#f8d476") if is_key else Color("#d3dcd1")
	accent.a = 0.65 + sin(elapsed * 2.0) * 0.15
	var outline := backing.duplicate()
	outline.append(backing[0])
	draw_polyline(outline, accent, 1.0, true)
	if is_key:
		var y := -46.0 + sin(elapsed * 2.0) * 2.0
		draw_polyline(PackedVector2Array([Vector2(-5, y - 4), Vector2(0, y), Vector2(5, y - 4)]), Color("#ffe8a0"), 2.0, true)
