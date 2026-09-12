extends Node
## Persistent game-state authority for both parts of LIBERTAS VINCTA.

const SENSES := ["hearing", "sight", "memory"]
const MAX_FLASHLIGHT_SECONDS := 90.0
const BASE_MAX_HP := 100.0

var keys_collected: Array[String] = []
var letter_ids: Array[String] = []
var flags: Dictionary = {}
var inventory: Dictionary = {}
var hiding_usage: Dictionary = {}
var detections: int = 0
var loop_counter: int = 0
var ending_type: String = ""
var part2_seed: Dictionary = {}
var current_part: int = 1
var entity_stage: int = 0
var flashlight_seconds: float = MAX_FLASHLIGHT_SECONDS
var max_hp: float = BASE_MAX_HP
var hp: float = BASE_MAX_HP
var mechanic_uses: int = 0
var anchors_cleansed: Array[String] = []

var hearing_restored: bool:
	get: return "hearing" in keys_collected
var sight_restored: bool:
	get: return "sight" in keys_collected
var memory_restored: bool:
	get: return "memory" in keys_collected
var letters_found: int:
	get: return letter_ids.size()
var current_stage: int:
	get: return entity_stage

func reset() -> void:
	keys_collected.clear()
	letter_ids.clear()
	flags.clear()
	inventory = {"battery": 0, "bottle": 0, "clock": 0, "lockpick": 0}
	hiding_usage.clear()
	detections = 0
	loop_counter = 0
	ending_type = ""
	part2_seed.clear()
	current_part = 1
	entity_stage = 0
	flashlight_seconds = MAX_FLASHLIGHT_SECONDS
	max_hp = BASE_MAX_HP
	hp = max_hp
	mechanic_uses = 0
	anchors_cleansed.clear()
	_emit_status()

func reset_for_loop() -> void:
	loop_counter += 1
	keys_collected.clear()
	letter_ids.clear()
	flags.clear()
	flags["intro_complete"] = true
	flags["flashlight"] = true
	flags["loop_wake"] = true
	if loop_counter >= 2:
		flags["vantree_memory_fragment_A"] = true
	inventory = {"battery": 0, "bottle": 0, "clock": 0, "lockpick": 0}
	hiding_usage.clear()
	detections = 0
	ending_type = ""
	part2_seed.clear()
	current_part = 1
	entity_stage = 0
	flashlight_seconds = MAX_FLASHLIGHT_SECONDS
	max_hp = BASE_MAX_HP
	hp = max_hp
	mechanic_uses = 0
	anchors_cleansed.clear()
	_emit_status()

func restore_sense(sense: String) -> bool:
	if entity_stage >= SENSES.size() or sense != SENSES[entity_stage]:
		return false
	keys_collected.append(sense)
	entity_stage = keys_collected.size()
	EventBus.sense_restored.emit(sense)
	return true

func collect_letter(id: String) -> bool:
	if id in letter_ids:
		return false
	letter_ids.append(id)
	if id == "vantree_04":
		flags["lore_jailer_hint"] = true
	EventBus.letter_collected.emit(id)
	return true

func collect_item(id: String, amount: int = 1) -> void:
	inventory[id] = int(inventory.get(id, 0)) + amount
	EventBus.inventory_changed.emit(id, int(inventory[id]))

func consume_item(id: String, amount: int = 1) -> bool:
	if int(inventory.get(id, 0)) < amount:
		return false
	inventory[id] = int(inventory[id]) - amount
	EventBus.inventory_changed.emit(id, int(inventory[id]))
	return true

func record_detection() -> void:
	detections += 1
	EventBus.detection_recorded.emit(detections)

func record_hiding_use(id: String) -> void:
	hiding_usage[id] = int(hiding_usage.get(id, 0)) + 1

func set_flashlight_seconds(value: float) -> void:
	flashlight_seconds = clampf(value, 0.0, MAX_FLASHLIGHT_SECONDS)
	EventBus.battery_changed.emit(flashlight_seconds, MAX_FLASHLIGHT_SECONDS)

func damage(amount: float) -> bool:
	hp = maxf(0.0, hp - amount)
	EventBus.health_changed.emit(hp, max_hp)
	EventBus.player_hurt.emit(amount)
	return hp <= 0.0

func eligible(candidate: String) -> bool:
	match candidate:
		"untouched": return current_part == 1 and entity_stage == 0 and detections == 0
		"vantree": return current_part == 1 and entity_stage == 1 and letters_found >= 4
		"partial_mercy": return current_part == 1 and entity_stage == 2
		"loop": return current_part == 1 and entity_stage == 3
		"severance", "custodian_rest", "vessel":
			return current_part == 2 and anchors_cleansed.size() >= 1
	return false

func begin_part_two(part_one_ending: String) -> void:
	ending_type = part_one_ending
	part2_seed = _build_part2_seed(part_one_ending)
	current_part = 2
	anchors_cleansed.clear()
	mechanic_uses = 0
	flags["part1_complete"] = true
	flags["part2_started"] = true
	if part_one_ending == "untouched":
		for gadget in ["battery", "bottle", "clock"]:
			inventory[gadget] = maxi(3, int(inventory.get(gadget, 0)))
	max_hp = BASE_MAX_HP * (0.8 if part_one_ending == "vantree" else 1.0)
	hp = max_hp
	_emit_status()

func _build_part2_seed(part_one_ending: String) -> Dictionary:
	var inherited_senses: Array[String] = []
	if part_one_ending == "partial_mercy":
		inherited_senses.assign(keys_collected)
	var dormant: Array[String] = []
	for sense in SENSES:
		if sense not in inherited_senses:
			dormant.append(sense)
	return {
		"part1_ending": part_one_ending,
		"senses": inherited_senses,
		"dormant_senses": dormant,
		"monster_stage": inherited_senses.size(),
		"touch_mutation": part_one_ending == "vantree",
		"blood_magic": part_one_ending == "vantree",
		"hybrid_magic": part_one_ending == "partial_mercy",
		"full_gadgets": part_one_ending == "untouched",
		"hp_softcap": 0.8 if part_one_ending == "vantree" else 1.0,
		"loop_counter": loop_counter
	}

func cleanse_anchor(id: String) -> bool:
	if id in anchors_cleansed:
		return false
	anchors_cleansed.append(id)
	EventBus.anchor_cleansed.emit(id, anchors_cleansed.size())
	return true

func has_requirement(requirement: String) -> bool:
	if requirement.is_empty():
		return true
	if requirement in SENSES:
		return requirement in keys_collected
	if requirement.begins_with("letters:"):
		return letters_found >= int(requirement.get_slice(":", 1))
	if requirement.begins_with("items:"):
		var bits := requirement.split(":")
		return int(inventory.get(bits[1], 0)) >= int(bits[2])
	if requirement == "part2_mechanic_3":
		return mechanic_uses >= 3
	if requirement == "branch_vantree":
		return bool(part2_seed.get("blood_magic", false))
	if requirement == "branch_magic":
		return bool(part2_seed.get("blood_magic", false)) or bool(part2_seed.get("hybrid_magic", false))
	return bool(flags.get(requirement, false))

func snapshot() -> Dictionary:
	return {
		"keys": keys_collected.duplicate(), "letters": letter_ids.duplicate(),
		"entity_stage": entity_stage, "ending_type": ending_type,
		"loop_counter": loop_counter, "part2_seed": part2_seed.duplicate(true),
		"flags": flags.duplicate(true), "inventory": inventory.duplicate(true),
		"hiding_usage": hiding_usage.duplicate(true), "detections": detections,
		"current_part": current_part, "flashlight_seconds": flashlight_seconds,
		"max_hp": max_hp, "hp": hp, "mechanic_uses": mechanic_uses,
		"anchors": anchors_cleansed.duplicate()
	}

func restore_snapshot(data: Dictionary) -> void:
	keys_collected.assign(data.get("keys", []))
	letter_ids.assign(data.get("letters", []))
	entity_stage = int(data.get("entity_stage", keys_collected.size()))
	ending_type = str(data.get("ending_type", ""))
	loop_counter = int(data.get("loop_counter", 0))
	part2_seed = data.get("part2_seed", {}).duplicate(true)
	flags = data.get("flags", {}).duplicate(true)
	inventory = data.get("inventory", {"battery": 0, "bottle": 0, "clock": 0, "lockpick": 0}).duplicate(true)
	hiding_usage = data.get("hiding_usage", {}).duplicate(true)
	detections = int(data.get("detections", 0))
	current_part = int(data.get("current_part", 1))
	flashlight_seconds = float(data.get("flashlight_seconds", MAX_FLASHLIGHT_SECONDS))
	max_hp = float(data.get("max_hp", BASE_MAX_HP))
	hp = float(data.get("hp", max_hp))
	mechanic_uses = int(data.get("mechanic_uses", 0))
	anchors_cleansed.assign(data.get("anchors", []))
	_emit_status()

func _emit_status() -> void:
	EventBus.battery_changed.emit(flashlight_seconds, MAX_FLASHLIGHT_SECONDS)
	EventBus.health_changed.emit(hp, max_hp)
