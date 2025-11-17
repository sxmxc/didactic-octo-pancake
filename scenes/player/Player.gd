extends Node2D
class_name Player

var _owned_creatures : Array[Creature] = []
var _known_buildables : Array[Buildable] = []
var _egg_inventory: Array[Dictionary] = []

var _wallet : Dictionary = {
	"gold" : 0,
	"gem": 0,
	"platinum": 0
}
# Called when the node enters the scene tree for the first time.
func _ready():
	Eventbus.player_currency_earned.connect(add_to_wallet)
	add_to_group("player")
	add_to_group("Player")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func adopt_creature(creature: Creature, track_save: bool = true):
	_owned_creatures.append(creature)
	if track_save:
		Game.queue_save("creature_adopted")

func get_adopted_creatures() -> Array[Creature]:
	return _owned_creatures

func reset_owned_creatures():
	_owned_creatures.clear()

func clear_egg_inventory():
	_egg_inventory.clear()
	Eventbus.player_egg_inventory_updated.emit(get_egg_inventory_snapshot())
	
func learn_buildable(buildable: Buildable, track_save: bool = true):
	_known_buildables.append(buildable)
	if track_save:
		Game.queue_save("buildable_unlocked")

func learn_buildable_by_key(key: String, track_save: bool = true):
	if Data.buildable_library.has(key):
		var buildable: Buildable = Data.buildable_library[key].instantiate()
		learn_buildable(buildable, track_save)

func clear_known_buildables():
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

func add_to_wallet(type: String, amount: int):
	if _wallet.has(type):
		_wallet[type] += amount
		Eventbus.player_wallet_updated.emit(_wallet)
		Game.queue_save("wallet_change")

func set_wallet_from_save(wallet: Dictionary):
	for currency in _wallet.keys():
		if wallet.has(currency):
			_wallet[currency] = int(wallet[currency])
		else:
			_wallet[currency] = 0
	Eventbus.player_wallet_updated.emit(_wallet)

func get_wallet_snapshot() -> Dictionary:
	return _wallet.duplicate(true)

func get_egg_inventory_snapshot() -> Array:
	var snapshot: Array = []
	for entry in _egg_inventory:
		snapshot.append(entry.duplicate(true))
	return snapshot

func set_egg_inventory_from_save(entries: Array):
	_egg_inventory.clear()
	for entry in entries:
		if entry is Dictionary and entry.has("species_key"):
			_egg_inventory.append(entry.duplicate(true))
	Eventbus.player_egg_inventory_updated.emit(get_egg_inventory_snapshot())

func add_egg(species_key: String, track_save: bool = true, notify: bool = true) -> bool:
	if !Data.species_baby_library.has(species_key):
		return false
	var species: Species = Data.species_baby_library[species_key]
	var entry: Dictionary = {
		"species_key": species_key,
		"species_name": species.species_name,
		"species_path": species.resource_path,
	}
	if species.egg_texture:
		entry["egg_texture"] = species.egg_texture.resource_path
	_egg_inventory.append(entry)
	if notify:
		Eventbus.player_egg_inventory_updated.emit(get_egg_inventory_snapshot())
	if track_save:
		Game.queue_save("egg_inventory_changed")
	return true

func grant_debug_eggs(count: int = 3):
	if Data.species_baby_library.is_empty():
		return
	for i in range(count):
		var keys: Array = Data.species_baby_library.keys()
		var key: String = keys[i % keys.size()]
		add_egg(key, false, false)
	Eventbus.player_egg_inventory_updated.emit(get_egg_inventory_snapshot())

func get_egg_by_index(index: int) -> Dictionary:
	if index < 0 or index >= _egg_inventory.size():
		return {}
	return _egg_inventory[index].duplicate(true)

func remove_egg_at(index: int, track_save: bool = true) -> Dictionary:
	if index < 0 or index >= _egg_inventory.size():
		return {}
	var entry: Dictionary = _egg_inventory.pop_at(index)
	Eventbus.player_egg_inventory_updated.emit(get_egg_inventory_snapshot())
	if track_save:
		Game.queue_save("egg_inventory_changed")
	return entry
