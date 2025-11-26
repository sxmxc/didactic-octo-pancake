extends Sprite2D
class_name Food

const DIET_LABELS := {
	&"meat": "Meat",
	&"veggie": "Veggie",
	&"omnivore": "Omnivore",
}
const COMPATIBILITY_RULES := {
	&"meat": [&"meat", &"omnivore"],
	&"veggie": [&"veggie", &"omnivore"],
	&"omnivore": [&"omnivore"],
}

@export var fallback_display_name: String = "Handful"
@export_multiline var fallback_description: String = ""
@export_enum("meat", "veggie", "omnivore") var fallback_food_type: String = "omnivore"
@export_range(1, 200, 1, "suffix:pts") var fallback_hunger_relief: int = 25
@export var fallback_stat_effects: Dictionary = {}

var _definition_id: StringName = StringName()
var _display_name: String = ""
var _description: String = ""
var _diet_type: StringName = StringName()
var _hunger_relief: int = 0
var _stat_effects: Dictionary = {}
var _configured: bool = false

func _ready() -> void:
	if !_configured:
		_apply_fallbacks()

func configure_from_definition(definition_id: StringName, definition: Dictionary = {}) -> void:
	_configured = true
	_definition_id = definition_id
	var payload: Dictionary = definition if definition is Dictionary else {}
	_display_name = str(payload.get("display_name", fallback_display_name))
	_description = str(payload.get("description", fallback_description))
	_diet_type = _to_string_name(payload.get("diet_type", fallback_food_type))
	_hunger_relief = clampi(int(payload.get("hunger_relief", fallback_hunger_relief)), 1, 999)
	_stat_effects = _normalize_effects(payload.get("stat_effects", fallback_stat_effects))
	var tint_value: Variant = payload.get("tint", null)
	if tint_value is Color:
		modulate = tint_value

func get_display_name() -> String:
	return _display_name

func get_description() -> String:
	return _description

func get_diet_type() -> StringName:
	return _diet_type

func get_diet_label() -> String:
	return to_diet_label(_diet_type)

func get_hunger_relief() -> int:
	return _hunger_relief

func get_stat_effects() -> Dictionary:
	return _stat_effects.duplicate(true)

func get_definition_id() -> StringName:
	return _definition_id

func consume(creature: Creature) -> void:
	if creature == null:
		queue_free()
		return
	if creature.species and !is_compatible_with_species(creature.species):
		Eventbus.notification_requested.emit("%s refuses to eat %s food." % [creature.name, get_diet_label()])
		queue_free()
		return
	var stats: CreatureStats = creature.stats
	if stats:
		stats.current_hunger = clampi(stats.current_hunger - _hunger_relief, 0, stats.max_hunger)
	creature.apply_food_effects(_stat_effects)
	Eventbus.current_hunger_updated.emit()
	_announce_effects(creature)
	queue_free()

func is_compatible_with_species(species: Species) -> bool:
	if species == null:
		return true
	return is_compatible_with_diet(species.get_diet())

func is_compatible_with_diet(diet: StringName) -> bool:
	if diet == StringName():
		return false
	var allowed: Array = get_compatible_diets_for(_diet_type)
	if allowed.is_empty():
		return true
	return allowed.has(diet)

static func get_compatible_diets_for(food_type: StringName) -> Array[StringName]:
	var key: StringName = food_type if food_type != StringName() else &"omnivore"
	var values: Array = COMPATIBILITY_RULES.get(key, [&"omnivore"])
	var typed: Array[StringName] = []
	for entry in values:
		var diet: StringName = entry if entry is StringName else StringName(str(entry))
		if diet != StringName():
			typed.append(diet)
	return typed

static func to_diet_label(diet: StringName) -> String:
	if DIET_LABELS.has(diet):
		return String(DIET_LABELS[diet])
	return String(diet)

func _announce_effects(creature: Creature) -> void:
	var summary := _build_effect_summary()
	if summary == "":
		return
	Eventbus.notification_requested.emit("%s gained %s from %s." % [creature.name, summary, _display_name])

func _build_effect_summary() -> String:
	if _stat_effects.is_empty():
		return ""
	var parts: Array[String] = []
	for key in _stat_effects.keys():
		var amount: int = int(_stat_effects[key])
		if amount == 0:
			continue
		var label := String(key) if key is String or key is StringName else str(key)
		var prefix := "+" if amount > 0 else "-"
		parts.append("%s%d %s" % [prefix, abs(amount), label.capitalize()])
	return ", ".join(parts)

func _normalize_effects(source: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if !(source is Dictionary):
		return normalized
	for key in source.keys():
		var stat_id: StringName = _to_string_name(key)
		if stat_id == StringName():
			continue
		normalized[stat_id] = int(source[key])
	return normalized

func _apply_fallbacks() -> void:
	_display_name = fallback_display_name
	_description = fallback_description
	_diet_type = _to_string_name(fallback_food_type)
	_hunger_relief = fallback_hunger_relief
	_stat_effects = _normalize_effects(fallback_stat_effects)

func _to_string_name(value: Variant) -> StringName:
	if value is StringName:
		return value
	if value is String and value != "":
		return StringName(value)
	return StringName()
