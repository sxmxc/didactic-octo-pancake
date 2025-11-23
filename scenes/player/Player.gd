extends Node2D
class_name Player

var _owned_creatures : Array[Creature] = []
var _known_buildables : Array[Buildable] = []
var _egg_inventory: EggInventory = EggInventory.new()

var _wallet : Dictionary = {
	"gold" : 0,
	"gem": 0,
	"platinum": 0
}

func _ready() -> void:
	Eventbus.player_currency_earned.connect(add_to_wallet)
	add_to_group("player")
	add_to_group("Player")

func _process(_delta: float) -> void:
	pass

func adopt_creature(creature: Creature, track_save: bool = true) -> void:
	if creature == null:
		return
	_owned_creatures.append(creature)
	if track_save:
		Game.queue_save("creature_adopted")
		Eventbus.creature_adopted.emit(creature)

func get_adopted_creatures() -> Array[Creature]:
	return _owned_creatures

func reset_owned_creatures() -> void:
	_owned_creatures.clear()

func clear_egg_inventory(track_save: bool = true) -> void:
	_egg_inventory.clear()
	_emit_inventory_changed(track_save)

func learn_buildable(buildable: Buildable, track_save: bool = true) -> void:
	_known_buildables.append(buildable)
	if track_save:
		Game.queue_save("buildable_unlocked")

func learn_buildable_by_key(key: String, track_save: bool = true) -> void:
	if Data.buildable_library.has(key):
		var buildable: Buildable = Data.buildable_library[key].instantiate()
		learn_buildable(buildable, track_save)

func clear_known_buildables() -> void:
	for buildable in _known_buildables:
		if is_instance_valid(buildable):
			buildable.queue_free()
	_known_buildables.clear()

func get_known_buildables() -> Array[Buildable]:
	return _known_buildables

func get_known_buildable_keys() -> Array:
	var keys: Array = []
	for buildable in _known_buildables:
		if buildable and buildable.buildable_key != "":
			keys.append(buildable.buildable_key)
	return keys

func add_to_wallet(type: String, amount: int) -> void:
	if _wallet.has(type):
		_wallet[type] += amount
		Eventbus.player_wallet_updated.emit(_wallet)
		Game.queue_save("wallet_change")

func spend_wallet(cost: Dictionary, reason: String = "wallet_spend") -> bool:
	if !can_afford(cost):
		return false
	for currency in cost.keys():
		var amount: int = int(cost[currency])
		if amount <= 0:
			continue
		if _wallet.has(currency):
			_wallet[currency] -= amount
	Eventbus.player_wallet_updated.emit(_wallet)
	Game.queue_save(reason)
	return true

func can_afford(cost: Dictionary) -> bool:
	for currency in cost.keys():
		if !_wallet.has(currency):
			return false
		var required: int = int(cost[currency])
		if required <= 0:
			continue
		if _wallet[currency] < required:
			return false
	return true

func set_wallet_from_save(wallet: Dictionary) -> void:
	for currency in _wallet.keys():
		if wallet.has(currency):
			_wallet[currency] = int(wallet[currency])
		else:
			_wallet[currency] = 0
	Eventbus.player_wallet_updated.emit(_wallet)

func get_wallet_snapshot() -> Dictionary:
	return _wallet.duplicate(true)

func get_egg_inventory_snapshot() -> Dictionary:
	return _egg_inventory.to_snapshot()

func set_egg_inventory_from_save(snapshot: Variant) -> void:
	_egg_inventory = EggInventory.new()
	if snapshot is Dictionary:
		_egg_inventory.from_snapshot(snapshot)
	elif snapshot is Array:
		_migrate_legacy_egg_array(snapshot)
	_emit_inventory_changed(false)

func get_egg_token_count() -> int:
	return _egg_inventory.get_total_tokens()

func get_egg_token(index: int) -> Dictionary:
	return _egg_inventory.get_token(index)

func grant_pack(pack_id: String, amount: int = 1, track_save: bool = true, notify: bool = true) -> void:
	if amount <= 0:
		return
	_egg_inventory.add_pack(pack_id, amount)
	if notify:
		_emit_inventory_changed(track_save)

func get_pack_count(pack_id: String) -> int:
	return _egg_inventory.get_pack_count(pack_id)

func get_pack_counts() -> Dictionary:
	return _egg_inventory.pack_counts.duplicate(true)

func purchase_pack(pack_id: String, cost: Dictionary, track_save: bool = true) -> Dictionary:
	if cost.is_empty():
		return {"ok": false, "message": "Missing pack cost."}
	if !can_afford(cost):
		return {"ok": false, "message": "Not enough currency."}
	if !spend_wallet(cost, "egg_pack_purchase"):
		return {"ok": false, "message": "Unable to spend currency."}
	grant_pack(pack_id, 1, track_save)
	Eventbus.egg_pack_purchased.emit(pack_id, cost.duplicate(true))
	return {"ok": true}

func open_pack(pack_id: String, track_save: bool = true) -> Dictionary:
	var pack_def: Dictionary = Data.egg_pack_definitions.get(pack_id, {})
	if pack_def.is_empty():
		return {"ok": false, "message": "Unknown pack."}
	if !_egg_inventory.consume_pack(pack_id):
		return {"ok": false, "message": "No packs to open."}
	var minted_tokens: Array = []
	var rolls: Array = pack_def.get("egg_rolls", [])
	for roll in rolls:
		if roll is Dictionary:
			var tier_value = roll.get("tier_id", "meadow")
			var tier_id: StringName = StringName(str(tier_value))
			if tier_id == StringName():
				tier_id = &"meadow"
			var count: int = int(roll.get("count", 1))
			for _i in range(max(count, 0)):
				var token := _create_token_for_tier(tier_id, pack_id)
				_egg_inventory.register_token(token)
				minted_tokens.append(token)
	_emit_inventory_changed(track_save)
	var minted_snapshot: Array = []
	for entry in minted_tokens:
		if entry is Dictionary:
			minted_snapshot.append(entry.duplicate(true))
	Eventbus.egg_pack_opened.emit(pack_id, minted_snapshot)
	return {
		"ok": true,
		"pack_id": pack_id,
		"tokens": minted_tokens,
		"minted": minted_tokens.size(),
	}

func hatch_egg_at(index: int, track_save: bool = true) -> Dictionary:
	var token := _egg_inventory.get_token(index)
	if token.is_empty():
		return {"ok": false, "message": "No egg available."}
	var tier_value = token.get("tier_id", "meadow")
	var tier_id: StringName = StringName(str(tier_value))
	if tier_id == StringName():
		tier_id = &"meadow"
	var species_key: String = ""
	if token.has("locked_species_key"):
		species_key = str(token.get("locked_species_key", ""))
	if species_key == "":
		species_key = Game.roll_species_for_tier(tier_id)
	if species_key == "" or !Data.species_baby_library.has(species_key):
		return {"ok": false, "message": "Unable to resolve species."}
	var species: Species = Data.species_baby_library[species_key]
	_egg_inventory.remove_token_at(index)
	_emit_inventory_changed(track_save)
	Eventbus.egg_hatched.emit(species_key, tier_id, token.duplicate(true))
	return {
		"ok": true,
		"species_key": species_key,
		"species": species,
		"token": token,
	}

func restore_egg_token(token: Dictionary, track_save: bool = true) -> void:
	if token.is_empty():
		return
	_egg_inventory.register_token(token)
	_emit_inventory_changed(track_save)

func can_claim_pack(pack_id: String, now_ms: int = _now_ms()) -> bool:
	return _egg_inventory.can_claim_pack(pack_id, now_ms)

func try_claim_pack(pack_id: String, cooldown_hours: float, track_save: bool = true) -> Dictionary:
	var now_ms := _now_ms()
	if !can_claim_pack(pack_id, now_ms):
		return {"ok": false, "message": "Pack not ready."}
	grant_pack(pack_id, 1, false, false)
	var next_ready_ms := _apply_pack_cooldown(pack_id, cooldown_hours, now_ms, track_save)
	Eventbus.egg_pack_claimed.emit(pack_id, "manual_claim", now_ms, next_ready_ms)
	return {"ok": true, "ready_time_ms": next_ready_ms}

func mark_pack_claimed(pack_id: String, cooldown_hours: float, now_ms: int = _now_ms(), track_save: bool = true) -> int:
	return _apply_pack_cooldown(pack_id, cooldown_hours, now_ms, track_save)

func get_next_claim_ready_time(pack_id: String) -> int:
	return _egg_inventory.get_next_claim_ready(pack_id)

func _emit_inventory_changed(track_save: bool) -> void:
	Eventbus.player_egg_inventory_updated.emit(get_egg_inventory_snapshot())
	if track_save:
		Game.queue_save("egg_inventory_changed")

func _apply_pack_cooldown(pack_id: String, cooldown_hours: float, now_ms: int, track_save: bool) -> int:
	var interval_ms: int = int(max(cooldown_hours, 0.0) * 3600.0 * 1000.0)
	var next_ready_ms := now_ms + interval_ms
	_egg_inventory.set_next_claim_ready(pack_id, next_ready_ms)
	_emit_inventory_changed(track_save)
	return next_ready_ms

func _migrate_legacy_egg_array(entries: Array) -> void:
	for entry in entries:
		if entry is Dictionary and entry.has("species_key"):
			var species_key: String = str(entry["species_key"])
			if species_key == "" or !Data.species_baby_library.has(species_key):
				continue
			var species: BabySpecies = Data.species_baby_library[species_key]
			var token := _create_token_for_tier(species.egg_tier, "legacy", species_key)
			_egg_inventory.register_token(token)

func _create_token_for_tier(tier_id: StringName, source_pack_id: String = "", locked_species_key: String = "") -> Dictionary:
	var now_ms := _now_ms()
	var safe_tier: StringName = tier_id if tier_id != StringName() else &"meadow"
	var token_id := "%s_%s_%s" % [safe_tier, str(now_ms), str(randi())]
	var token := {
		"token_id": token_id,
		"tier_id": safe_tier,
		"source_pack_id": source_pack_id,
		"awarded_at_ms": now_ms,
	}
	if locked_species_key != "":
		token["locked_species_key"] = locked_species_key
	return token

func _now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)
