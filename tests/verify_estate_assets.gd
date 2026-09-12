extends Node

const EstateArt := preload("res://scripts/levels/estate_art.gd")
const MAIN := preload("res://scenes/main/main.tscn")
var failures: Array[String] = []
var checks: int = 0
var puzzle_noise: Array[float] = []
var capture: bool = false
var capture_dir := "res://build/asset-verification"

func _ready() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	if capture:
		DirAccess.make_dir_recursive_absolute(capture_dir)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	EventBus.noise_created.connect(func(_point, intensity, _surface): puzzle_noise.append(intensity))
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var art := EstateArt.new()
	for key in art.data.textures:
		var texture: AtlasTexture = art.texture_for(key)
		_check(texture != null and texture.atlas != null, "Missing texture: " + key)
		_check(Rect2(Vector2.ZERO, texture.atlas.get_size()).encloses(texture.region), "Atlas outside source: " + key)
		_check(texture.get_width() > 0 and texture.get_height() > 0, "Empty atlas: " + key)
	_check(art.texture_for("piano").region == Rect2(357, 49, 270, 287), "Piano must show only the grand piano and bench")
	for zone in ["intro", "ground", "upper", "basement"]:
		await _verify_zone(zone, art.data.zones[zone])
	print("ESTATE ASSETS: %s checks, %s failures; %s catalog textures." % [checks, failures.size(), art.data.textures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _verify_zone(zone: String, dressing: Dictionary) -> void:
	FreedomLedger.reset()
	if zone in ["upper", "basement"]:
		FreedomLedger.restore_sense("hearing")
	if zone == "basement":
		FreedomLedger.restore_sense("sight")
	GameManager.zone = zone
	GameManager.entry = "start"
	var main := MAIN.instantiate()
	add_child(main)
	var room: Node2D = main.room
	var player: CharacterBody2D = main.get_node("Entities/Player")
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.set_physics_process(false)
	if zone == "intro":
		Engine.time_scale = 15.0
		while GameManager.state == GameManager.State.INTRO:
			await get_tree().process_frame
		Engine.time_scale = 1.0
	await get_tree().physics_frame
	_check(room.get_node("Backdrop/ImportedArchitecture") != null, zone + ": architecture missing")
	_check(room.y_sort_enabled and room.props.y_sort_enabled, zone + ": missing foot Y sorting")
	for key in dressing.furniture:
		var body: Node2D = room.props.get_node(NodePath(key))
		_check(not body.get_node("PlaceholderVisual").visible and not body.get_node("RaisedFacePlaceholder").visible, zone + ": furniture placeholder still visible: " + key)
		_check(body.get_node("Visual/Sprite2D").texture != null, zone + ": furniture texture missing: " + key)
		var dimensions: Vector2 = body.get_node("CollisionShape2D").shape.size
		_check(dimensions == Vector2(dressing.furniture[key].footprint[0], dressing.furniture[key].footprint[1]), zone + ": furniture footprint mismatch: " + key)
		if str(dressing.furniture[key].asset) == "bench":
			_check(is_equal_approx(body.get_node("Visual").rotation_degrees, 4.0), zone + ": bench is not angled toward the camera: " + key)
	var bench_count := 0
	for candidate in room.props.find_children("*", "Sprite2D", true, false):
		var bench_sprite := candidate as Sprite2D
		if bench_sprite != null and bench_sprite.get_meta("estate_asset", "") == "bench":
			bench_count += 1
			_check(is_equal_approx((bench_sprite.get_parent() as Node2D).rotation_degrees, 4.0), zone + ": a decorative bench is not angled toward the camera")
	_check(bench_count > 0, zone + ": no rotated benches found")
	for id in dressing.get("interactables", {}):
		var prop: BaseInteractable = room.props.get_node(NodePath(str(id).to_pascal_case()))
		var sprite: Sprite2D = prop.get_node("Visual/Sprite2D")
		_check(sprite.texture != null and not prop.get_node("Visual/PlaceholderVisual").visible, zone + ": interaction art missing: " + id)
		_check(is_zero_approx(sprite.get_parent().position.y + sprite.position.y + (sprite.offset.y + sprite.texture.get_height() * 0.5) * sprite.scale.y), zone + ": texture foot detached from interaction: " + id)
		if dressing.interactables[id].has("sort_offset"):
			_check(prop.y_sort_enabled and sprite.get_parent().global_position.y == room.props.get_node("Furniture6").global_position.y, zone + ": tabletop item must sort with its counter")
	for spec in room.layout.props:
		var prop: BaseInteractable = room.props.get_node(NodePath(str(spec[1]).to_pascal_case()))
		_check(prop.position == Vector2(spec[2], spec[3]), zone + ": progression prop moved: " + spec[1])
		_check(prop.get_node("Visual/Sprite2D").texture != null and not prop.get_node("Visual/PlaceholderVisual").visible, zone + ": unresolved interaction placeholder: " + spec[1])
		if prop.kind in ["key", "letter", "flashlight", "tool"]:
			var marker: Node2D = prop.get_node_or_null("Visual/PickupMarker")
			_check(prop.get_node("Visual").z_index == 0 and marker != null and marker.get_index() < prop.get_node("Visual/Sprite2D").get_index(), zone + ": pickup floor sorting/marker is incorrect: " + spec[1])
			if prop.kind == "flashlight":
				var pickup_sprite: Sprite2D = prop.get_node("Visual/Sprite2D")
				_check(pickup_sprite.texture.get_width() * pickup_sprite.scale.x <= 32.1, zone + ": floor flashlight is oversized")
		elif prop.kind in ["door", "locked_door"] or (prop.kind == "exit" and prop.interaction_id != "custodian_seal"):
			_check(prop.position.y == 362 and not prop.display_name.is_empty(), zone + ": passage not aligned or identified: " + spec[1])
			var presentation: Node = prop.get_node_or_null("Visual/DoorPresentation")
			_check(presentation != null and prop.get_node_or_null("Visual/DoorVoid") != null, zone + ": passage lacks open-door presentation: " + spec[1])
			if presentation != null:
				var door_sprite: Sprite2D = prop.get_node("Visual/Sprite2D")
				var closed_scale := door_sprite.scale
				presentation.set_open_immediate(true)
				_check(door_sprite.scale.x < closed_scale.x * 0.35, zone + ": door leaf did not rotate open: " + spec[1])
				presentation.set_open_immediate(false)
				_check(door_sprite.scale.is_equal_approx(closed_scale), zone + ": door leaf did not close: " + spec[1])
			for decoration in room.get_node("Backdrop/ImportedArchitecture").get_children():
				if decoration is Sprite2D and decoration.get_meta("estate_asset", "") == "window":
					_check(absf(decoration.position.x - prop.position.x) >= 140.0, zone + ": window overlaps doorway: " + spec[1])
		var approach := _accessible_approach(room, prop)
		_check(approach.is_finite(), zone + ": no unobstructed approach to " + spec[1])
		if not approach.is_finite():
			continue
		var route: PackedVector2Array = room.find_path(Vector2(240, 600), approach)
		_check(not route.is_empty(), zone + ": no navigation route to " + spec[1])
		player.position = approach
		player.velocity = Vector2.ZERO
		await get_tree().physics_frame
		await get_tree().physics_frame
		player._find_interactable()
		_check(player.target_interactable == prop, zone + ": E cannot reach " + spec[1])
		if prop.kind == "hiding":
			prop.interact(player)
			_check(player.hidden_spot == prop, zone + ": cannot enter hiding " + spec[1])
			player.leave_hiding()
			_check(player.hidden_spot == null, zone + ": cannot leave hiding " + spec[1])
	_check(not room.find_path(Vector2(240, 600), Vector2(room.room_width - 330, 600)).is_empty(), zone + ": end-to-end route blocked")
	if zone == "ground":
		_check(room.surface_at(Vector2(2800, 470)) == "GLASS" and room.surface_at(Vector2(2800, 600)) == "CARPET", "Ground stealth surfaces changed")
		var key_position: Vector2 = room.props.get_node("HearingKey").position
		_check(key_position == Vector2(1960, 525), "Hearing key must be in the open area beside the piano")
		for blocker in room.blockers:
			_check(not blocker.intersects(Rect2(key_position - Vector2(40, 40), Vector2(80, 80))), "Furniture encroaches on hearing key")
	elif zone == "upper":
		_check(room.is_exposed(Vector2(2800, 470)) and not room.is_exposed(Vector2(2800, 600)), "Upper light/shadow route changed")
	elif zone == "basement":
		_check(room.surface_at(Vector2(2000, 470)) == "WATER" and room.surface_at(Vector2(2000, 600)) == "STONE", "Basement wet/dry route changed")
	elif zone == "intro":
		var dropped_beam: Polygon2D = room.props.get_node("Flashlight/DroppedBeamPlaceholder")
		_check(dropped_beam.z_index == -1 and dropped_beam.polygon[0].x >= 14.0, "Dropped flashlight beam is not behind the player on the floor")
		_check(dropped_beam.polygon[1].x <= 145.0 and absf(dropped_beam.polygon[1].y) <= 24.0, "Dropped flashlight beam is oversized")
	if capture:
		var views: Array = {
			"intro": [["foyer", 800], ["foyer_exit", 1660], ["foyer_exit_open", 1660, true]],
			"ground": [["ground_entry", 620], ["music_room", 1880], ["dining_hall", 3550], ["pantry", 5710], ["ground_exit", 6970], ["ground_exit_open", 6970, true]],
			"upper": [["gallery", 2050], ["bedroom", 3670], ["nursery", 5620], ["upper_exit", 6970], ["upper_exit_open", 6970, true]],
			"basement": [["basement_entry", 650], ["flooded_cellar", 1760], ["wine_cellar", 3630], ["ritual_chamber", 5710], ["basement_exit", 6950], ["basement_exit_open", 6950, true]]
		}[zone]
		for view in views:
			var open_door: BaseInteractable
			if view.size() > 2 and bool(view[2]):
				open_door = _passage_near(room, float(view[1]))
				open_door.get_node("Visual/DoorPresentation").set_open_immediate(true)
			await _capture(main, player, str(view[0]), float(view[1]))
			if open_door != null:
				open_door.get_node("Visual/DoorPresentation").set_open_immediate(false)
	await _verify_loose_pickups(room, player, main.get_node("UI"))
	if capture and zone == "intro":
		await _capture(main, player, "flashlight_carried", 850.0)
	if zone != "intro":
		await _verify_puzzle(room, player, zone)
		var snapshot := FreedomLedger.snapshot()
		FreedomLedger.reset()
		FreedomLedger.restore_snapshot(snapshot)
		_check(FreedomLedger.snapshot() == snapshot, zone + ": checkpoint ledger changed")
	var expected_blockers: Array[Rect2] = room.blockers.duplicate()
	main.queue_free()
	await get_tree().process_frame
	var packed: PackedScene = load("res://scenes/levels/" + zone + "_floor.tscn")
	var reloaded := packed.instantiate()
	reloaded.show_placeholder_environment = false
	add_child(reloaded)
	_check(reloaded.blockers == expected_blockers, zone + ": reload changed collision footprints")
	_check(reloaded.get_node("Backdrop").visible, zone + ": imported art hidden by placeholder switch")
	for node in reloaded.get_node("Backdrop").get_children():
		_check(node.visible, zone + ": surface marking hidden by placeholder switch")
	for prop in reloaded.props.get_children():
		if prop is BaseInteractable and prop.kind == "puzzle":
			_check(not prop.available() and prop.visible, zone + ": solved furniture should remain visible after reload")
	reloaded.queue_free()
	await get_tree().process_frame
	var greybox := packed.instantiate()
	greybox.use_imported_assets = false
	add_child(greybox)
	_check(greybox.get_node_or_null("Backdrop/ImportedArchitecture") == null, zone + ": greybox override ignored")
	for rect in greybox.blockers.slice(0, 4):
		_check(rect in expected_blockers, zone + ": room boundary changed")
	greybox.queue_free()
	await get_tree().process_frame
	print("Verified " + zone + ": art, E reachability, routes, hiding and reload.")

func _verify_loose_pickups(room: Node2D, player: CharacterBody2D, hud: CanvasLayer) -> void:
	for prop in room.props.get_children():
		if prop is BaseInteractable and prop.kind in ["letter", "flashlight", "tool"]:
			prop.interact(player)
			if prop.kind == "tool":
				_check(player.animation_state == "interact", "Tool pouch incorrectly uses the key pickup animation")
			if prop.kind == "letter":
				_check(GameManager.state == GameManager.State.READING, "Letter must open its reading view")
				hud.close_modal()
			elif prop.kind == "flashlight":
				player.animation_hold = 0.0
				player.play_animation("idle")
				player._update_flashlight_presentation()
				var held: Sprite2D = player.get_node("Visual/HeldFlashlight")
				var beam: Polygon2D = player.get_node("FlashlightFloor/BeamPlaceholder")
				_check(held.visible and held.texture.get_width() * held.scale.x <= 14.1, "Collected flashlight is not carried at hand scale")
				_check(player.get_node("FlashlightFloor").z_index == -1 and not player.get_node("FlashlightFloor/PointLight2D").visible, "Flashlight illumination is not restricted behind the player")
				_check(beam.polygon[0].x >= 18.0 and beam.polygon[2].x <= 148.0, "Flashlight floor beam is oversized or overlaps Els")
			_check(not prop.visible and not prop.available(), "Collected pickup still visible: " + prop.interaction_id)

func _accessible_approach(room: Node2D, prop: BaseInteractable) -> Vector2:
	var center: Vector2i = room.nearest_cell(prop.position)
	var candidates: Array[Vector2] = []
	for x in range(maxi(0, center.x - 2), mini(room.grid.region.size.x, center.x + 3)):
		for y in 7:
			var cell := Vector2i(x, y)
			if not room.grid.is_point_solid(cell):
				candidates.append(room.grid.get_point_position(cell))
	candidates.sort_custom(func(a, b): return a.distance_squared_to(prop.position) < b.distance_squared_to(prop.position))
	for point in candidates:
		if point.distance_to(prop.position) >= 70.0:
			continue
		var feet := Rect2(point - Vector2(12, 14), Vector2(24, 14))
		var occupied := false
		for rect in room.blockers:
			if rect.intersects(feet):
				occupied = true
		if occupied:
			continue
		var route: PackedVector2Array = room.find_path(Vector2(240, 600), point)
		if route.is_empty() or not route[-1].is_equal_approx(point):
			continue
		var ray := PhysicsRayQueryParameters2D.create(point, prop.global_position, 1)
		if room.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			return point
	return Vector2.INF

func _passage_near(room: Node2D, x: float) -> BaseInteractable:
	var nearest: BaseInteractable
	var distance := INF
	for child in room.props.get_children():
		if child is BaseInteractable and child.get_node_or_null("Visual/DoorPresentation") != null:
			var candidate: float = absf(child.position.x - x)
			if candidate < distance:
				nearest = child
				distance = candidate
	return nearest

func _verify_puzzle(room: Node2D, player: CharacterBody2D, zone: String) -> void:
	var ids: Array = {"ground": ["PianoSeal", "HearingKey"], "upper": ["VanitySeal", "SightKey"], "basement": ["RitualSeal", "MemoryKey"]}[zone]
	var puzzle: BaseInteractable = room.props.get_node(NodePath(ids[0]))
	var key: BaseInteractable = room.props.get_node(NodePath(ids[1]))
	var stage := FreedomLedger.current_stage
	key.interact(player)
	_check(FreedomLedger.current_stage == stage, zone + ": key bypassed its puzzle")
	puzzle.action_seconds = 0.01
	puzzle_noise.clear()
	for step in puzzle.puzzle_steps:
		await puzzle.interact(player)
		_check(puzzle.progress == step + 1, zone + ": puzzle step failed")
	_check(puzzle_noise.size() == 3, zone + ": puzzle must still emit three noises")
	for intensity in puzzle_noise:
		_check(is_equal_approx(intensity, 0.55), zone + ": puzzle noise balance changed")
	_check(puzzle.visible and not puzzle.available(), zone + ": completed seal artwork disappeared")
	key.interact(player)
	_check(FreedomLedger.current_stage == stage + 1 and not key.visible, zone + ": key collection failed")

func _capture(main: Node2D, player: CharacterBody2D, label: String, x: float) -> void:
	player.position = Vector2(x, 500)
	player.velocity = Vector2.ZERO
	player.facing = Vector2.LEFT
	player.play_animation("idle")
	var camera: Camera2D = player.get_node("Camera2D")
	camera.zoom = Vector2.ONE
	camera.snap_to_player()
	main.get_node("UI").subtitle_queue.clear()
	main.get_node("UI").subtitle_time = 0.0
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var picture := get_viewport().get_texture().get_image()
	_check(not picture.is_empty(), "Empty rendered frame: " + label)
	var first := picture.get_pixel(picture.get_width() / 2, picture.get_height() / 2)
	var different: int = 0
	for row in range(0, picture.get_height(), 24):
		for column in range(0, picture.get_width(), 24):
			if picture.get_pixel(column, row) != first:
				different += 1
	_check(different > 100, "Blank rendered viewport: " + label)
	var err := picture.save_png(capture_dir + "/" + label + "_" + str(picture.get_width()) + "x" + str(picture.get_height()) + ".png")
	_check(err == OK, "Could not save screenshot: " + label)
