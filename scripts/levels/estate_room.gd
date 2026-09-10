extends Node2D
## Layout data supplies replaceable props; collision/navigation are independent of art.
@export_enum("intro", "ground", "upper", "basement") var zone_id: String = "ground"
@export var debug_noise: bool = false
@export var environment_art: PackedScene
@export var show_placeholder_environment: bool = true
var room_width: float = 7200.0
var layout: Dictionary
var blockers: Array[Rect2] = []
var grid := AStarGrid2D.new()
var noise_rings: Array[Dictionary] = []
var geometry: Node2D
var props: Node2D
var markers: Node2D

func _ready() -> void:
	add_to_group("room")
	y_sort_enabled = true
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/estate_layout.json"))
	layout = all[zone_id]
	room_width = float(layout.width)
	geometry = $Geometry
	props = $Props
	markers = $Markers
	_build_backdrop()
	_wall("BackWall", Rect2(0, 330, room_width, 24))
	_wall("FrontBoundary", Rect2(0, 634, room_width, 30))
	_wall("LeftBoundary", Rect2(-32, 330, 32, 334))
	_wall("RightBoundary", Rect2(room_width, 330, 32, 334))
	if zone_id == "intro":
		_furniture("BrokenTable", Vector2(670, 560), Vector2(140, 52))
	else:
		for i in range(1, 7):
			var x := float(i) * 990.0
			var y := 505.0 if i % 2 == 0 else 450.0
			_furniture("Furniture" + str(i), Vector2(x, y), Vector2(150, 56))
	for spec in layout.props:
		var prop: Node2D = load("res://scenes/interactables/" + spec[0] + ".tscn").instantiate()
		prop.name = spec[1].to_pascal_case()
		prop.interaction_id = spec[1]
		prop.position = Vector2(spec[2], spec[3])
		if spec.size() > 4:
			for key in spec[4]:
				prop.set(key, spec[4][key])
		props.add_child(prop)
		_marker(spec[1].to_pascal_case() + "Point", prop.position)
	_marker("PlayerSpawn", Vector2(240, 490))
	_marker("ReturnSpawn", Vector2(room_width - 330, 490))
	_marker("EnemySpawn", Vector2(float(layout.enemy), 560))
	_build_grid()
	$Backdrop.visible = show_placeholder_environment
	if environment_art != null:
		var art := environment_art.instantiate()
		art.name = "EnvironmentArt"
		add_child(art)
	EventBus.noise_created.connect(_noise)

func _marker(label: String, point: Vector2) -> void:
	var marker := Marker2D.new()
	marker.name = label
	marker.position = point
	markers.add_child(marker)

func _polygon(parent: Node, label: String, rect: Rect2, color: Color) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = label
	polygon.visible = show_placeholder_environment
	polygon.color = color
	polygon.polygon = PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)])
	parent.add_child(polygon)
	return polygon

func _build_backdrop() -> void:
	_polygon($Backdrop, "WallPlaceholder", Rect2(-200, -100, room_width + 400, 460), Color("#171d25"))
	_polygon($Backdrop, "FloorPlaceholder", Rect2(0, 354, room_width, 280), Color("#30353a"))
	var section_width := room_width / float(layout.names.size())
	for i in layout.names.size():
		var x := float(i) * section_width
		_polygon($Backdrop, "WallPanel" + str(i), Rect2(x + 40, 120, section_width - 80, 200), Color("#222933"))
		var label := Label.new()
		label.text = layout.names[i]
		label.position = Vector2(x + 100, 265)
		label.add_theme_font_size_override("font_size", 23)
		label.modulate = Color(0.6, 0.63, 0.66, 0.8)
		$Backdrop.add_child(label)
	for x in range(0, int(room_width), 160):
		var seam := Line2D.new()
		seam.add_point(Vector2(x, 355))
		seam.add_point(Vector2(x - 130, 634))
		seam.width = 1.0
		seam.default_color = Color(0.13, 0.16, 0.19, 0.45)
		$Backdrop.add_child(seam)
	var distant := Parallax2D.new()
	distant.name = "DistantWallParallax"
	distant.scroll_scale = Vector2(0.97, 1.0)
	$Backdrop.add_child(distant)
	for x in range(500, int(room_width), 960):
		_polygon(distant, "Window" + str(x), Rect2(x, 150, 90, 100), Color(0.25, 0.30, 0.35, 0.25))
	if zone_id == "ground":
		_polygon($Backdrop, "BrokenGlass", Rect2(2520, 355, 820, 180), Color(0.37, 0.4, 0.42, 0.7))
		_polygon($Backdrop, "CarpetBypass", Rect2(2380, 550, 1200, 74), Color("#273733"))
	elif zone_id == "upper":
		for x in [2650, 4300, 5950]:
			_polygon($Backdrop, "Moonlight" + str(x), Rect2(x, 355, 650, 180), Color(0.55, 0.60, 0.64, 0.35))
		_polygon($Backdrop, "LinenShadowLane", Rect2(2700, 550, 3600, 74), Color("#22282e"))
	elif zone_id == "basement":
		_polygon($Backdrop, "Water", Rect2(900, 355, 2500, 190), Color(0.18, 0.32, 0.38, 0.8))
	elif zone_id == "intro":
		_polygon($Backdrop, "Moonlight", Rect2(180, 355, 390, 190), Color(0.5, 0.58, 0.68, 0.22))
		_polygon($Backdrop, "DarkCorridorBeyondDoor", Rect2(1600, 355, 200, 279), Color("#161b22"))

func _wall(label: String, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.name = label
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	body.add_child(collision)
	_polygon(body, "PlaceholderVisual", Rect2(-rect.size * 0.5, rect.size), Color("#171b21"))
	geometry.add_child(body)
	blockers.append(rect)

func _furniture(label: String, point: Vector2, size: Vector2) -> void:
	var rect := Rect2(point - Vector2(size.x / 2.0, size.y), size)
	_wall(label, rect)
	var body: StaticBody2D = geometry.get_node(label)
	body.reparent(props)
	body.position = point
	body.get_node("CollisionShape2D").position = Vector2(0, -size.y / 2.0)
	body.get_node("PlaceholderVisual").position = Vector2(0, -size.y / 2.0)
	_polygon(body, "RaisedFacePlaceholder", Rect2(-size.x / 2.0, -size.y - 50, size.x, 50), Color("#424449"))

func _build_grid() -> void:
	grid.region = Rect2i(0, 0, int(ceil(room_width / 40.0)), 7)
	grid.cell_size = Vector2(40, 40)
	grid.offset = Vector2(20, 370)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in grid.region.size.x:
		for y in grid.region.size.y:
			var cell := Vector2i(x, y)
			var point := grid.get_point_position(cell)
			for rect in blockers:
				if rect.grow(20).has_point(point):
					grid.set_point_solid(cell)
					break

func nearest_cell(point: Vector2) -> Vector2i:
	var cell := Vector2i(roundi((point.x - 20) / 40), roundi((point.y - 370) / 40))
	cell.x = clampi(cell.x, 0, grid.region.size.x - 1)
	cell.y = clampi(cell.y, 0, 6)
	if not grid.is_point_solid(cell):
		return cell
	var best := cell
	var distance := INF
	for x in range(maxi(0, cell.x - 5), mini(grid.region.size.x, cell.x + 6)):
		for y in 7:
			var test := Vector2i(x, y)
			if not grid.is_point_solid(test):
				var d := point.distance_squared_to(grid.get_point_position(test))
				if d < distance:
					best = test
					distance = d
	return best

func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	return grid.get_point_path(nearest_cell(from), nearest_cell(to))

func reachable_fallback(point: Vector2) -> Vector2:
	return grid.get_point_position(nearest_cell(point + Vector2(100, 85)))

func clamp_point(point: Vector2) -> Vector2:
	return Vector2(clampf(point.x, 50, room_width - 50), clampf(point.y, 375, 615))

func patrol_anchor() -> float:
	if zone_id == "basement" and FreedomLedger.memory_restored:
		return 4900.0
	return float(layout.enemy)

func surface_at(point: Vector2) -> String:
	if zone_id == "ground" and point.x > 2380 and point.x < 3580:
		return "CARPET" if point.y > 545 else "GLASS"
	if zone_id == "basement" and point.x > 900 and point.x < 3400 and point.y < 545:
		return "WATER"
	return layout.surface

func is_exposed(point: Vector2) -> bool:
	if zone_id == "upper":
		for x in [2650, 4300, 5950]:
			if point.x > x and point.x < x + 650 and point.y < 545:
				return true
		return false
	return zone_id == "ground" or (zone_id == "basement" and point.x > 3900)

func _noise(point: Vector2, intensity: float, _surface: String) -> void:
	if debug_noise:
		noise_rings.append({"point": point, "radius": intensity * 740.0, "life": 0.6})

func _process(delta: float) -> void:
	if not debug_noise:
		return
	for ring in noise_rings:
		ring.life -= delta
	noise_rings = noise_rings.filter(func(ring): return ring.life > 0)
	queue_redraw()

func _draw() -> void:
	if debug_noise:
		for ring in noise_rings:
			draw_arc(to_local(ring.point), ring.radius, 0, TAU, 40, Color(0.4, 0.65, 0.8, ring.life * 0.5), 1.0)
