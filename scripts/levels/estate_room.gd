extends Node2D
## Layout data supplies replaceable props; collision/navigation are independent of art.
const EstateArt := preload("res://scripts/levels/estate_art.gd")
@export_enum("intro", "ground", "upper", "basement", "roots", "echoes", "nexus") var zone_id: String = "ground"
@export var debug_noise: bool = false
@export var environment_art: PackedScene
@export var show_placeholder_environment: bool = true
@export var use_imported_assets: bool = true
var room_width: float = 7200.0
var layout: Dictionary
var blockers: Array[Rect2] = []
var grid := AStarGrid2D.new()
var noise_rings: Array[Dictionary] = []
var geometry: Node2D
var props: Node2D
var markers: Node2D
var estate_art: RefCounted
var current_room_id: String = ""
var ambient_false_noise_clock: float = 14.0

func _ready() -> void:
	add_to_group("room")
	y_sort_enabled = true
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/estate_layout.json"))
	layout = all[zone_id]
	room_width = float(layout.width)
	geometry = $Geometry
	props = $Props
	markers = $Markers
	if _uses_imported_art():
		estate_art = EstateArt.new()
	_build_backdrop()
	_wall("BackWall", Rect2(0, 330, room_width, 24))
	_wall("FrontBoundary", Rect2(0, 634, room_width, 30))
	_wall("LeftBoundary", Rect2(-32, 330, 32, 334))
	_wall("RightBoundary", Rect2(room_width, 330, 32, 334))
	if estate_art != null:
		for label in estate_art.data.zones[zone_id].furniture:
			var spec: Dictionary = estate_art.data.zones[zone_id].furniture[label]
			_furniture(label, Vector2(spec.position[0], spec.position[1]), Vector2(spec.footprint[0], spec.footprint[1]))
	elif zone_id == "intro":
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
				var value = spec[4][key]
				if key in ["action_position_offset", "action_facing"] and value is Array and value.size() >= 2:
					value = Vector2(float(value[0]), float(value[1]))
				prop.set(key, value)
		props.add_child(prop)
		_marker(spec[1].to_pascal_case() + "Point", prop.position)
	_marker("PlayerSpawn", Vector2(240, 490))
	_marker("ReturnSpawn", Vector2(room_width - 330, 490))
	_marker("EnemySpawn", Vector2(float(layout.enemy), 560))
	if estate_art != null:
		estate_art.dress(self)
	_build_grid()
	$Backdrop.visible = show_placeholder_environment or _uses_imported_art()
	if environment_art != null:
		var art := environment_art.instantiate()
		art.name = "EnvironmentArt"
		add_child(art)
	EventBus.noise_created.connect(_noise)

func _uses_imported_art() -> bool:
	return use_imported_assets and environment_art == null

func _marker(label: String, point: Vector2) -> void:
	var marker := Marker2D.new()
	marker.name = label
	marker.position = point
	markers.add_child(marker)

func _polygon(parent: Node, label: String, rect: Rect2, color: Color) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = label
	polygon.visible = show_placeholder_environment or _uses_imported_art()
	polygon.color = color
	polygon.polygon = PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)])
	parent.add_child(polygon)
	return polygon

func _build_backdrop() -> void:
	if estate_art != null:
		estate_art.build_backdrop(self)
		_build_surface_markings()
		estate_art.dress_surfaces(self)
		return
	_polygon($Backdrop, "WallPlaceholder", Rect2(-200, -100, room_width + 400, 460), Color("#171d25"))
	_polygon($Backdrop, "FloorPlaceholder", Rect2(0, 354, room_width, 280), Color("#30353a"))
	for i in layout.rooms.size():
		var room_spec: Dictionary = layout.rooms[i]
		var x := float(room_spec.start)
		var section_width := float(room_spec.end) - x
		_polygon($Backdrop, "WallPanel" + str(i), Rect2(x + 40, 120, section_width - 80, 200), Color("#222933"))
		var label := Label.new()
		label.text = str(room_spec.id) + "  " + str(room_spec.name)
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
	_build_surface_markings()

func _build_surface_markings() -> void:
	if zone_id == "ground":
		_polygon($Backdrop, "BrokenGlass", Rect2(2520, 355, 820, 180), Color(0.37, 0.4, 0.42, 0.7))
		_polygon($Backdrop, "CarpetBypass", Rect2(2380, 550, 1200, 74), Color("#273733"))
	elif zone_id == "upper":
		for x in [2650, 4300, 5950]:
			_polygon($Backdrop, "Moonlight" + str(x), Rect2(x, 355, 650, 180), Color(0.55, 0.60, 0.64, 0.35))
		_polygon($Backdrop, "LinenShadowLane", Rect2(2700, 550, 3600, 74), Color("#22282e"))
	elif zone_id == "basement":
		_polygon($Backdrop, "Water", Rect2(900, 355, 1100, 190), Color(0.18, 0.32, 0.38, 0.8))
	elif zone_id == "roots":
		_polygon($Backdrop, "FloodedNave", Rect2(1000, 355, 1000, 190), Color(0.14, 0.30, 0.34, 0.72))
		_polygon($Backdrop, "RootShadow", Rect2(2000, 355, 1000, 279), Color(0.09, 0.12, 0.12, 0.34))
	elif zone_id == "echoes":
		_polygon($Backdrop, "ChoirDrop", Rect2(3300, 355, 1100, 150), Color(0.08, 0.14, 0.16, 0.45))
	elif zone_id == "nexus":
		_polygon($Backdrop, "NexusRing", Rect2(260, 365, 1280, 250), Color(0.12, 0.24, 0.25, 0.32))
	elif zone_id == "intro":
		_polygon($Backdrop, "Moonlight", Rect2(180, 355, 390, 190), Color(0.5, 0.58, 0.68, 0.22))
		if not _uses_imported_art():
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
	var placeholder := _polygon(body, "PlaceholderVisual", Rect2(-rect.size * 0.5, rect.size), Color("#171b21"))
	placeholder.visible = show_placeholder_environment and not _uses_imported_art()
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

func patrol_target(stage: int, index: int) -> Vector2:
	var candidates: Array = layout.rooms.duplicate()
	if zone_id == "ground" and stage == 0:
		candidates = candidates.slice(0, 5)
	elif zone_id == "upper" and stage == 1:
		candidates = candidates.filter(func(spec): return str(spec.id) in ["UF-01", "UF-02", "UF-04", "UF-06"])
	elif zone_id == "roots" and int(FreedomLedger.part2_seed.get("monster_stage", 0)) == 0 and not FreedomLedger.part2_seed.get("touch_mutation", false):
		candidates = candidates.filter(func(spec): return str(spec.id) == "CR-03")
	if candidates.is_empty():
		return Vector2(float(layout.enemy), 500.0)
	var spec: Dictionary = candidates[index % candidates.size()]
	return clamp_point(Vector2((float(spec.start) + float(spec.end)) * 0.5, 430.0 if index % 2 == 0 else 575.0))

func vibration_transmission_at(point: Vector2) -> float:
	if surface_at(point) == "RUBBLE":
		return 160.0
	if zone_id == "echoes" and point.x >= 3300.0 and point.x < 4400.0 and point.y < 470.0:
		return 96.0
	return 480.0

func surface_at(point: Vector2) -> String:
	for region in layout.get("surface_regions", []):
		if point.x >= float(region[0]) and point.x < float(region[1]):
			return str(region[2])
	return layout.surface

func is_exposed(point: Vector2) -> bool:
	for region in layout.get("light_regions", []):
		if point.x >= float(region[0]) and point.x < float(region[1]):
			return true
	return false

func known_exit_positions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for child in props.get_children():
		if child is BaseInteractable and child.kind in ["door", "exit", "vent"]:
			result.append(child.global_position)
	return result

func _noise(point: Vector2, intensity: float, _surface: String) -> void:
	if debug_noise:
		noise_rings.append({"point": point, "radius": intensity if intensity > 10.0 else intensity * 740.0, "life": 0.6})

func _process(delta: float) -> void:
	_update_room_tracking()
	_update_ambient_hazards(delta)
	if debug_noise:
		for ring in noise_rings:
			ring.life -= delta
		noise_rings = noise_rings.filter(func(ring): return ring.life > 0)
		queue_redraw()

func _update_ambient_hazards(delta: float) -> void:
	if zone_id != "ground" or GameManager.state != GameManager.State.PLAYING or not FreedomLedger.hearing_restored:
		return
	ambient_false_noise_clock -= delta
	if ambient_false_noise_clock <= 0.0:
		ambient_false_noise_clock = randf_range(12.0, 20.0)
		EventBus.noise_created.emit(Vector2(1100.0, 300.0), 260.0, "GENERIC")

func _update_room_tracking() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	for room_spec in layout.rooms:
		if player.global_position.x >= float(room_spec.start) and player.global_position.x < float(room_spec.end):
			var next_id := str(room_spec.id)
			if next_id != current_room_id:
				current_room_id = next_id
				_enter_room(next_id)
			return

func _enter_room(id: String) -> void:
	FreedomLedger.flags["visited_" + id] = true
	EventBus.room_entered.emit(id)
	match id:
		"GF-03": EventBus.tension_changed.emit("SEARCHING")
		"GF-04":
			var player = get_tree().get_first_node_in_group("player")
			if player != null and not player.is_crouching:
				EventBus.noise_created.emit(Vector2(2520.0, 410.0), 420.0, "GENERIC")
		"UF-02": FreedomLedger.flags["vision_vfx_primed"] = true
		"BS-05": FreedomLedger.flags["ritual_chamber_seen"] = true
		"CE-01":
			if not FreedomLedger.flags.get("mechanic_intro_seen", false):
				FreedomLedger.flags["mechanic_intro_seen"] = true
				if FreedomLedger.part2_seed.get("hybrid_magic", false):
					FreedomLedger.flags["part2_ability_unlocked"] = true
				var line := "Stay above the broken floor; feel movement through the stone." if FreedomLedger.part2_seed.get("touch_mutation", false) else "The forge can turn blood into twelve seconds of silence."
				EventBus.subtitle_requested.emit("ELS", line, 4.0)
		"CE-03":
			if FreedomLedger.part2_seed.get("blood_magic", false) and not FreedomLedger.flags.get("entity_spoke", false):
				FreedomLedger.flags["entity_spoke"] = true
				EventBus.subtitle_requested.emit("THE DEPRIVED", "Els. You have brought your name home.", 4.0)
		"LN-CENTER": FreedomLedger.flags["finale_started"] = true

func _draw() -> void:
	if debug_noise:
		for ring in noise_rings:
			draw_arc(to_local(ring.point), ring.radius, 0, TAU, 40, Color(0.4, 0.65, 0.8, ring.life * 0.5), 1.0)
