extends Node
## The only authority for persistent progression. Temporary actors read this ledger.
const SENSES := ["hearing", "sight", "memory"]
var keys_collected: Array[String] = []
var letter_ids: Array[String] = []
var flags: Dictionary = {}
var hearing_restored: bool:
	get: return "hearing" in keys_collected
var sight_restored: bool:
	get: return "sight" in keys_collected
var memory_restored: bool:
	get: return "memory" in keys_collected
var letters_found: int:
	get: return letter_ids.size()
var current_stage: int:
	get: return keys_collected.size()

func reset() -> void:
	keys_collected.clear()
	letter_ids.clear()
	flags.clear()

func restore_sense(sense: String) -> bool:
	if current_stage >= SENSES.size() or sense != SENSES[current_stage]:
		return false
	keys_collected.append(sense)
	EventBus.sense_restored.emit(sense)
	return true

func collect_letter(id: String) -> bool:
	if id in letter_ids:
		return false
	letter_ids.append(id)
	EventBus.letter_collected.emit(id)
	return true

func eligible(ending: String) -> bool:
	match ending:
		"full_awakening": return current_stage == 3
		"partial_mercy": return current_stage == 2
		"vantree": return current_stage <= 1 and letters_found >= 3
	return false

func snapshot() -> Dictionary:
	return {"keys": keys_collected.duplicate(), "letters": letter_ids.duplicate(), "flags": flags.duplicate(true)}

func has_requirement(requirement: String) -> bool:
	return requirement in keys_collected if requirement in SENSES else bool(flags.get(requirement, false))

func restore_snapshot(data: Dictionary) -> void:
	reset()
	keys_collected.assign(data.get("keys", []))
	letter_ids.assign(data.get("letters", []))
	flags = data.get("flags", {}).duplicate(true)
