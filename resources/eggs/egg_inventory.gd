extends Resource
class_name EggInventory

@export var egg_tokens: Array[Dictionary] = []
@export var pack_counts: Dictionary = {}
@export var next_claim_ready_ms: Dictionary = {}

func clear() -> void:
	egg_tokens.clear()
	pack_counts.clear()
	next_claim_ready_ms.clear()

func to_snapshot() -> Dictionary:
	return {
		"egg_tokens": _duplicate_tokens(),
		"pack_counts": pack_counts.duplicate(true),
		"next_claim_ready_ms": next_claim_ready_ms.duplicate(true),
	}

func from_snapshot(snapshot: Dictionary) -> void:
	clear()
	var tokens: Array = snapshot.get("egg_tokens", [])
	for entry in tokens:
		if entry is Dictionary and entry.has("token_id"):
			egg_tokens.append(entry.duplicate(true))
	var counts: Dictionary = snapshot.get("pack_counts", {})
	for pack_id in counts.keys():
		pack_counts[pack_id] = int(counts[pack_id])
	var ready_times: Dictionary = snapshot.get("next_claim_ready_ms", {})
	for pack_id in ready_times.keys():
		next_claim_ready_ms[pack_id] = int(ready_times[pack_id])

func get_pack_count(pack_id: String) -> int:
	if pack_counts.has(pack_id):
		return int(pack_counts[pack_id])
	return 0

func add_pack(pack_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	pack_counts[pack_id] = get_pack_count(pack_id) + amount

func consume_pack(pack_id: String) -> bool:
	var current := get_pack_count(pack_id)
	if current <= 0:
		return false
	pack_counts[pack_id] = current - 1
	return true

func register_token(token: Dictionary) -> void:
	if token.is_empty():
		return
	egg_tokens.append(token.duplicate(true))

func get_token(index: int) -> Dictionary:
	if index < 0 or index >= egg_tokens.size():
		return {}
	return egg_tokens[index].duplicate(true)

func remove_token_at(index: int) -> Dictionary:
	if index < 0 or index >= egg_tokens.size():
		return {}
	return egg_tokens.pop_at(index)

func get_total_tokens() -> int:
	return egg_tokens.size()

func set_next_claim_ready(pack_id: String, ready_time_ms: int) -> void:
	next_claim_ready_ms[pack_id] = int(ready_time_ms)

func get_next_claim_ready(pack_id: String) -> int:
	return int(next_claim_ready_ms.get(pack_id, 0))

func can_claim_pack(pack_id: String, now_ms: int) -> bool:
	return now_ms >= get_next_claim_ready(pack_id)

func _duplicate_tokens() -> Array:
	var snapshot: Array = []
	for token in egg_tokens:
		snapshot.append(token.duplicate(true))
	return snapshot
