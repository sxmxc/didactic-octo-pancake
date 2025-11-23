extends Node
#class_name Telemetry

const EVENT_PACK_PURCHASED := "egg_pack_purchased"
const EVENT_PACK_CLAIMED := "egg_pack_claimed"
const EVENT_PACK_OPENED := "egg_pack_opened"
const EVENT_EGG_HATCHED := "egg_hatched"
const EVENT_CREATURE_ADOPTED := "creature_adopted"
const EVENT_CURRENCY_EARNED := "currency_earned"

const STAT_PACKS_PURCHASED := "egg_packs_purchased"
const STAT_PACKS_CLAIMED := "egg_packs_claimed"
const STAT_PACKS_OPENED := "egg_packs_opened"
const STAT_EGGS_HATCHED := "eggs_hatched"
const STAT_CREATURES_ADOPTED := "creatures_adopted"

const CURRENCY_STAT_KEYS := {
	"gold": {
		"earned": "gold_earned",
		"spent": "gold_spent",
	},
	"gem": {
		"earned": "gems_earned",
		"spent": "gems_spent",
	},
	"platinum": {
		"earned": "platinum_earned",
		"spent": "platinum_spent",
	},
}

func _ready() -> void:
	Eventbus.player_currency_earned.connect(_on_currency_earned)
	Eventbus.egg_pack_purchased.connect(_on_pack_purchased)
	Eventbus.egg_pack_claimed.connect(_on_pack_claimed)
	Eventbus.egg_pack_opened.connect(_on_pack_opened)
	Eventbus.egg_hatched.connect(_on_egg_hatched)
	Eventbus.creature_adopted.connect(_on_creature_adopted)

func _on_currency_earned(currency: String, amount: int) -> void:
	if amount <= 0:
		return
	_track_telemetry_event(EVENT_CURRENCY_EARNED, {
		"currency": currency,
		"amount": amount,
	})
	_track_currency_delta(currency, amount)

func _on_pack_purchased(pack_id: String, cost: Dictionary) -> void:
	_track_telemetry_event(EVENT_PACK_PURCHASED, {
		"pack_id": pack_id,
		"cost": _describe_cost(cost),
	})
	_track_stat(STAT_PACKS_PURCHASED)
	for currency in cost.keys():
		_track_currency_delta(currency, -int(cost.get(currency, 0)))

func _on_pack_claimed(pack_id: String, source: String, claimed_at_ms: int, next_ready_ms: int) -> void:
	_track_telemetry_event(EVENT_PACK_CLAIMED, {
		"pack_id": pack_id,
		"source": source,
		"claimed_at_ms": claimed_at_ms,
		"next_ready_ms": next_ready_ms,
	})
	_track_stat(STAT_PACKS_CLAIMED)

func _on_pack_opened(pack_id: String, minted_tokens: Array) -> void:
	var minted_count := minted_tokens.size()
	_track_telemetry_event(EVENT_PACK_OPENED, {
		"pack_id": pack_id,
		"minted": minted_count,
		"tiers": _summarize_tokens(minted_tokens, "tier_id"),
		"locked_species": _summarize_tokens(minted_tokens, "locked_species_key"),
	})
	_track_stat(STAT_PACKS_OPENED)

func _on_egg_hatched(species_key: String, tier_id: StringName, token: Dictionary) -> void:
	_track_telemetry_event(EVENT_EGG_HATCHED, {
		"species": species_key,
		"tier": String(tier_id),
		"token_id": token.get("token_id", ""),
		"source_pack_id": token.get("source_pack_id", ""),
	})
	_track_stat(STAT_EGGS_HATCHED)

func _on_creature_adopted(creature: Creature) -> void:
	if creature == null or !is_instance_valid(creature):
		return
	var species_name := ""
	var species_path := ""
	if creature.species:
		species_name = creature.species.species_name
		if creature.species.resource_path != "":
			species_path = creature.species.resource_path
	_track_telemetry_event(EVENT_CREATURE_ADOPTED, {
		"species": species_name,
		"species_resource": species_path,
		"life_stage": creature.current_life_stage,
	})
	_track_stat(STAT_CREATURES_ADOPTED)

func _track_telemetry_event(event_name: String, props: Dictionary = {}) -> void:
	if !_can_submit():
		return
	var payload: Dictionary[String, String] = {}
	for key in props.keys():
		payload[str(key)] = _stringify_value(props[key])
	Talo.events.track(event_name, payload)

func _track_stat(stat_name: String, change: float = 1.0) -> void:
	if !_can_submit():
		return
	if stat_name == "":
		return
	Talo.stats.track(stat_name, change)

func _track_currency_delta(currency: String, amount: int) -> void:
	if amount == 0:
		return
	var stat_map: Dictionary = CURRENCY_STAT_KEYS.get(currency, {})
	if amount > 0:
		_track_stat(str(stat_map.get("earned", "")), amount)
	else:
		_track_stat(str(stat_map.get("spent", "")), abs(amount))

func _summarize_tokens(tokens: Array, key: String) -> String:
	var counts: Dictionary = {}
	for entry in tokens:
		if entry is Dictionary:
			var raw_value = entry.get(key, "")
			if raw_value == "":
				continue
			var safe_value := str(raw_value)
			counts[safe_value] = int(counts.get(safe_value, 0)) + 1
	if counts.is_empty():
		return ""
	var keys := counts.keys()
	keys.sort()
	var segments: Array[String] = []
	for value_key in keys:
		segments.append("%s:%s" % [value_key, counts[value_key]])
	return ", ".join(segments)

func _describe_cost(cost: Dictionary) -> String:
	if cost.is_empty():
		return "free"
	var parts: Array[String] = []
	for currency in cost.keys():
		var amount: int = int(cost.get(currency, 0))
		if amount <= 0:
			continue
		parts.append("%s %s" % [amount, str(currency)])
	if parts.is_empty():
		return "free"
	return ", ".join(parts)

func _stringify_value(value: Variant) -> String:
	if value is Dictionary or value is Array:
		return JSON.stringify(value)
	return str(value)

func _can_submit() -> bool:
	if Engine.is_editor_hint():
		return false
	return is_instance_valid(Talo) and Talo.has_identity()
