extends Resource
class_name TraitState

@export var trait_id: StringName = StringName()
@export_range(0, 9, 1) var tier: int = 0
@export var alignment: StringName = &"neutral"
@export var source: String = ""
@export var acquired_at_ms: int = 0

func is_valid() -> bool:
	return trait_id != StringName()

func to_dictionary() -> Dictionary:
	return {
		"trait_id": String(trait_id),
		"tier": tier,
		"alignment": String(alignment),
		"source": source,
		"acquired_at_ms": acquired_at_ms,
	}

func apply_dictionary(data: Dictionary) -> void:
	var id_value: Variant = data.get("trait_id", trait_id)
	if id_value == null or id_value == "":
		trait_id = StringName()
	else:
		trait_id = id_value if id_value is StringName else StringName(str(id_value))
	tier = int(data.get("tier", tier))
	var alignment_value: Variant = data.get("alignment", alignment)
	if alignment_value == null or alignment_value == "":
		alignment = &"neutral"
	else:
		alignment = alignment_value if alignment_value is StringName else StringName(str(alignment_value))
	source = String(data.get("source", source))
	acquired_at_ms = int(data.get("acquired_at_ms", acquired_at_ms))
