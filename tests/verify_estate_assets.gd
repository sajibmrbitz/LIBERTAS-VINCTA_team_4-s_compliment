extends Node

const EstateArt := preload("res://scripts/levels/estate_art.gd")
const ZONES := ["intro", "ground", "upper", "basement", "roots", "echoes", "nexus"]
var failures: Array[String] = []
var checks: int = 0

func _ready() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
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
	for key in ["cat_rubble", "sarcophagus", "blood_altar", "sigil_forge", "nexus_anchor", "ritual_stone"]:
		_check(art.data.textures.has(key), "Cathedral atlas slice missing: " + key)
	var seen_rooms: Array[String] = []
	var part_one_letters := 0
	var part_two_letters := 0
	var part_one_hides := 0
	for zone in ZONES:
		var stats: Dictionary = await _verify_zone(zone, art, seen_rooms)
		part_one_letters += int(stats.part_one_letters)
		part_two_letters += int(stats.part_two_letters)
		part_one_hides += int(stats.part_one_hides)
	_check(part_one_letters == 7, "Part I must contain exactly seven Vantree letters")
	_check(part_two_letters == 6, "Part II must contain letters VIII through XIII")
	_check(part_one_hides == 5, "Part I hiding table must contain exactly five specified spots")
	for id in ["GF-01", "GF-10", "UF-01", "UF-07", "BS-01", "BS-09", "CR-01", "CR-06", "CE-01", "CE-05", "LN-CENTER"]:
		_check(id in seen_rooms, "Required room ID missing: " + id)
	print("ESTATE ASSETS: %s checks, %s failures; 7 zones, %s room regions, %s catalog textures." % [checks, failures.size(), seen_rooms.size(), art.data.textures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func _verify_zone(zone: String, art: RefCounted, seen_rooms: Array[String]) -> Dictionary:
	FreedomLedger.reset()
	GameManager.zone = zone
	GameManager.state = GameManager.State.PLAYING
	var packed: PackedScene = load("res://scenes/levels/" + zone + "_floor.tscn")
	_check(packed != null, zone + ": scene missing")
	var room: Node2D = packed.instantiate()
	add_child(room)
	await get_tree().physics_frame
	_check(room.get_node_or_null("Backdrop/ImportedArchitecture") != null, zone + ": architecture missing")
	_check(room.y_sort_enabled and room.props.y_sort_enabled, zone + ": foot Y sorting missing")
	_check(room.layout.rooms.size() == room.layout.names.size(), zone + ": room names and regions disagree")
	var previous_end := 0.0
	for room_spec in room.layout.rooms:
		var id := str(room_spec.id)
		seen_rooms.append(id)
		_check(float(room_spec.start) == previous_end, zone + ": room regions have a gap before " + id)
		_check(float(room_spec.end) > float(room_spec.start), zone + ": invalid room region " + id)
		previous_end = float(room_spec.end)
	_check(is_equal_approx(previous_end, room.room_width), zone + ": room regions do not fill the floor")
	var part_one_letters := 0
	var part_two_letters := 0
	var part_one_hides := 0
	var recharge_count := 0
	var passage_count := 0
	for spec in room.layout.props:
		var id := str(spec[1])
		var prop: BaseInteractable = room.props.get_node_or_null(NodePath(id.to_pascal_case()))
		_check(prop != null, zone + ": interaction node missing: " + id)
		if prop == null:
			continue
		_check(prop.position == Vector2(spec[2], spec[3]), zone + ": interaction moved: " + id)
		var sprite: Sprite2D = prop.get_node("Visual/Sprite2D")
		_check(sprite.texture != null, zone + ": interaction art missing: " + id)
		_check(not prop.get_node("Visual/PlaceholderVisual").visible, zone + ": placeholder visible: " + id)
		if prop.kind in ["key", "letter", "flashlight", "tool", "item"]:
			_check(prop.get_node_or_null("Visual/PickupMarker") != null, zone + ": pickup marker missing: " + id)
		if prop.kind in ["door", "locked_door", "exit"]:
			passage_count += 1
			_check(prop.get_node_or_null("Visual/DoorPresentation") != null, zone + ": door animation missing: " + id)
			_check(prop.get_node_or_null("Visual/DoorVoid") != null, zone + ": open doorway void missing: " + id)
		if prop.kind == "letter":
			if zone in ["ground", "upper", "basement"]:
				part_one_letters += 1
			elif zone in ["roots", "echoes"]:
				part_two_letters += 1
		if prop.kind == "hiding" and zone in ["ground", "upper", "basement"]:
			part_one_hides += 1
			_check(prop.hiding_priority in ["low", "medium", "high"], zone + ": invalid hiding priority: " + id)
		if prop.kind == "recharge":
			recharge_count += 1
		if id == "piano_seal":
			_check(prop._action_animation() == "interact", "ground: piano uses the key-unlock animation")
			_check(prop.action_position_offset == Vector2(-78, -4), "ground: piano action position is misaligned")
			_check(prop.action_facing == Vector2.RIGHT, "ground: piano action does not face its lock")
	var bench_count := 0
	for candidate in room.props.find_children("*", "Sprite2D", true, false):
		var bench := candidate as Sprite2D
		if bench != null and bench.get_meta("estate_asset", "") == "bench":
			bench_count += 1
			_check(is_equal_approx((bench.get_parent() as Node2D).rotation_degrees, float(art.data.bench_rotation_degrees)), zone + ": bench angle changed")
	if zone in ["intro", "ground", "upper", "basement"]:
		_check(bench_count > 0, zone + ": no furniture-pack bench rendered")
	if zone in ["ground", "upper", "basement"]:
		_check(recharge_count >= 1, zone + ": floor has no recharge station")
	if zone == "nexus":
		var anchors := [room.props.get_node("LnA"), room.props.get_node("LnB"), room.props.get_node("LnC")]
		_check(anchors[2].position.x - anchors[0].position.x <= 1280.0, "Nexus anchors are not simultaneously visible")
		_check(passage_count == 0, "Nexus must lock with no retreat door")
	_check(not room.find_path(Vector2(240, 600), Vector2(room.room_width - 240, 600)).is_empty(), zone + ": end-to-end path blocked")
	room.queue_free()
	await get_tree().process_frame
	print("Verified " + zone + ": room IDs, art, collision path, props, and passages.")
	return {"part_one_letters": part_one_letters, "part_two_letters": part_two_letters, "part_one_hides": part_one_hides}
