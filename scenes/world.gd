class_name GameWorld
extends Node2D

signal tick

const BED_MATCH_TOLERANCE: float = 8.0

@export var tick_frequency: int = 10
@export var creature_scene: PackedScene = Data.creature_library["Creature0"]

@onready var world_bb: Blackboard = get_node("Blackboard")
@onready var player: Player = %Player
@onready var world_camera: PhantomCamera2D = %WorldCamera
@onready var build_camera: PhantomCamera2D = %BuildCamera
@onready var drop: CanvasLayer = $Drop
@onready var drop_area = get_node("%DropArea")
@onready var world_map: TileMapLayer = %WorldMap
@onready var tile_map_layer: TileMapLayer = %TileMapLayer
@onready var ui: WorldUI = %UI

var world_clock: Timer
var namegen: NameGenerator = NameGenerator.new()
var _last_tick_epoch_ms: int = 0
var _is_simulation_running: bool = false

func _ready():
	randomize()
	Eventbus.buildable_drag_started.connect(drop.show)
	Eventbus.buildable_drag_ended.connect(drop.hide)
	Eventbus.focus_view_requested.connect(_on_focus_view_requested)
	Eventbus.world_view_requested.connect(_on_world_view_requested)
	Eventbus.build_view_requested.connect(_on_build_view_requested)
	Eventbus.new_creature_requested.connect(_on_new_creature_requested)
	Eventbus.feed_request.connect(_on_feed_requested)
	Eventbus.egg_hatch_requested.connect(_on_egg_hatch_requested)
	drop_area.world_map = world_map
	world_clock = Timer.new()
	world_clock.wait_time = tick_frequency
	world_clock.timeout.connect(_on_timer_timeout)
	add_child(world_clock)
	SoundManager.play_music(Data.music_library["cozy"], 1)
	SoundManager.track_finished.connect(_queue_next_track)
	Game.register_world(self)

func _process(_delta):
	pass

func start_new_session() -> void:
	Tracer.info("Bootstrapping new world session")
	_reset_world_state()
	_bootstrap_player_profile()
	Game.sync_egg_rewards(player)
	_hatch_starter_creature()
	_last_tick_epoch_ms = Time.get_ticks_msec()

func begin_simulation() -> void:
	if world_clock == null or _is_simulation_running:
		return
	world_clock.wait_time = tick_frequency
	world_clock.start()
	_is_simulation_running = true
	_last_tick_epoch_ms = Time.get_ticks_msec()

func prepare_for_save() -> void:
	_last_tick_epoch_ms = Time.get_ticks_msec()

func serialize_state() -> Dictionary:
	var payload: Dictionary = {
		"world": {
			"tick_frequency": tick_frequency,
			"last_tick_epoch_ms": _last_tick_epoch_ms,
			"player": _serialize_player(),
			"buildables": _serialize_buildables(),
			"creatures": _serialize_creatures(),
		}
	}
	return payload

func apply_saved_state(payload: Dictionary) -> bool:
	var world_data: Dictionary = payload.get("world", {})
	if world_data.is_empty():
		return false
	_reset_world_state()
	tick_frequency = int(world_data.get("tick_frequency", tick_frequency))
	if world_clock:
		world_clock.wait_time = tick_frequency
	_restore_player(world_data.get("player", {}))
	_restore_buildables(world_data.get("buildables", []))
	for creature_data in world_data.get("creatures", []):
		_restore_creature(creature_data)
	_last_tick_epoch_ms = int(world_data.get("last_tick_epoch_ms", Time.get_ticks_msec()))
	return true

func apply_idle_ticks(tick_count: int) -> void:
	if tick_count <= 0:
		return
	for _i in range(tick_count):
		for creature in _get_active_creatures():
			creature._on_world_tick()
	_last_tick_epoch_ms = Time.get_ticks_msec()

func spawn_creature(creature: Creature, track_save: bool = true) -> Creature:
	var target: Node2D = _find_available_nest()
	if target == null:
		Tracer.info("No available nests")
		Eventbus.notification_requested.emit("No available nests.")
		return null
	_attach_creature_to_nest(creature, target)
	if int(creature.date_born) == 0:
		creature.date_born = Time.get_unix_time_from_system()
	_sync_creature_blackboard(creature, target)
	player.adopt_creature(creature, track_save)
	return creature

func _on_timer_timeout() -> void:
	_last_tick_epoch_ms = Time.get_ticks_msec()
	tick.emit()

func _on_focus_view_requested(creature: Creature):
	Tracer.info("Focus view request recieved for " + creature.name)
	for cam in PhantomCameraManager.get_phantom_camera_2ds():
		cam.set_priority(0)
	creature.camera.set_priority(20)
	creature.camera.follow_target = creature
	creature.camera.follow_mode = PhantomCamera2D.FollowMode.SIMPLE
	ui.set_focus(creature)
	Eventbus.current_energy_updated.emit()
	Eventbus.current_hunger_updated.emit()
	ui.current_creature_stats.visible = true

func _on_world_view_requested():
	Tracer.info("World view request received")
	if !world_camera.priority >= 20:
		ui.current_creature_stats.visible = false
		for cam in PhantomCameraManager.get_phantom_camera_2ds():
			cam.set_priority(0)
		world_camera.set_priority(20)

func _on_build_view_requested():
	Tracer.info("Build view request recieved")
	if !build_camera.priority >= 20:
		for cam in PhantomCameraManager.get_phantom_camera_2ds():
			cam.set_priority(0)
		build_camera.set_priority(20)

func _on_new_creature_requested():
	Tracer.info("New creature request received")
	if player.get_egg_token_count() <= 0:
		Eventbus.notification_requested.emit("You need an egg token before hatching a creature.")
		return
	var hatch_result := player.hatch_egg_at(0)
	if !hatch_result.get("ok", false):
		Eventbus.notification_requested.emit(hatch_result.get("message", "Unable to hatch an egg right now."))
		return
	_finalize_hatch(hatch_result)

func _on_feed_requested(food: Food):
	Tracer.info("Food request received")
	for target in get_tree().get_nodes_in_group("food_container"):
		if target.get_child_count() == 0:
			Tracer.info("Adding food to available container")
			target.add_child(food)
			return
	Eventbus.notification_requested.emit("No available food containers.")
	Tracer.info("No available food containers")

func _on_egg_hatch_requested(egg_index: int) -> void:
	var hatch_result := player.hatch_egg_at(egg_index)
	if !hatch_result.get("ok", false):
		Eventbus.notification_requested.emit(hatch_result.get("message", "No egg available."))
		return
	_finalize_hatch(hatch_result)

func _finalize_hatch(hatch_result: Dictionary) -> void:
	var species: Species = hatch_result.get("species", null)
	var token: Dictionary = hatch_result.get("token", {})
	if species == null:
		player.restore_egg_token(token)
		Eventbus.notification_requested.emit("Egg data corrupted.")
		return
	var new_creature: Creature = _create_random_creature(species)
	if new_creature == null:
		player.restore_egg_token(token)
		return
	var spawned := spawn_creature(new_creature)
	if spawned:
		Eventbus.focus_view_requested.emit(spawned)
	else:
		player.restore_egg_token(token)
		new_creature.queue_free()

func _reset_world_state() -> void:
	if world_clock:
		world_clock.stop()
	_is_simulation_running = false
	_teardown_creatures()
	_clear_dynamic_buildables()
	drop_area.clear_world_items()
	if world_bb:
		world_bb.blackboard = {}

func _teardown_creatures() -> void:
	for nest in get_tree().get_nodes_in_group("Nest"):
		if nest.has_method("owned_by_creature"):
			nest.owned_by_creature = null
	for node in get_tree().get_nodes_in_group("Creature"):
		if node is Creature:
			node.queue_free()
	player.reset_owned_creatures()

func _clear_dynamic_buildables() -> void:
	if world_map == null:
		return
	for child in world_map.get_children():
		if child is Buildable:
			drop_area.forget_buildable(child)
			child.queue_free()

func _bootstrap_player_profile() -> void:
	player.reset_owned_creatures()
	player.clear_known_buildables()
	player.set_wallet_from_save({"gold": 500, "gem": 0, "platinum": 0})
	player.learn_buildable(Data.buildable_library["BasicNest"].instantiate(), false)
	player.learn_buildable(Data.buildable_library["BasicFoodBowl"].instantiate(), false)
	player.clear_egg_inventory(false)
	player.grant_pack("brood_bundle", 1, false, false)
	player.open_pack("brood_bundle", false)

func _hatch_starter_creature() -> void:
	if player.get_egg_token_count() <= 0:
		player.grant_pack("daily_single", 1, false, false)
		player.open_pack("daily_single", false)
	if player.get_egg_token_count() <= 0:
		var fallback: Creature = _create_random_creature()
		if fallback:
			var spawned_fallback := spawn_creature(fallback, false)
			if spawned_fallback:
				Eventbus.focus_view_requested.emit(spawned_fallback)
			else:
				fallback.queue_free()
		return
	var hatch_result := player.hatch_egg_at(0, false)
	if !hatch_result.get("ok", false):
		var backup: Creature = _create_random_creature()
		if backup:
			var spawned_backup := spawn_creature(backup, false)
			if spawned_backup:
				Eventbus.focus_view_requested.emit(spawned_backup)
			else:
				backup.queue_free()
		return
	_finalize_hatch(hatch_result)

func _create_random_creature(species_override: Species = null) -> Creature:
	if creature_scene == null:
		return null
	var new_creature: Creature = creature_scene.instantiate()
	var name_array: Array = namegen.new_name()
	if !name_array.is_empty():
		var nickname : String = name_array[randi_range(0, name_array.size() - 1)]
		new_creature.creature_nickname = nickname
		new_creature.creature_name = nickname
		new_creature.name = nickname
	var selected_species: Species = species_override
	if selected_species == null:
		var available_species: Array = Data.species_baby_library.keys()
		if !available_species.is_empty():
			var key : String = available_species[randi_range(0, available_species.size() - 1)]
			selected_species = Data.species_baby_library[key]
	if selected_species:
		new_creature.set_species(selected_species)
		if new_creature.species.species_name == "Ghos":
			new_creature.stats.is_dead = true
	new_creature.date_born = Time.get_unix_time_from_system()
	return new_creature

func _attach_creature_to_nest(creature: Creature, nest: Nest) -> void:
	world_map.add_child(creature)
	creature.register_worldmap(world_map)
	creature.register_blackboard(world_bb)
	if creature.has_method("set_world_tick_interval"):
		creature.set_world_tick_interval(float(tick_frequency))
	nest.owned_by_creature = creature
	creature.global_position = nest.global_position
	world_clock.timeout.connect(creature._on_world_tick)

func _sync_creature_blackboard(creature: Creature, nest: Nest) -> void:
	if world_bb == null:
		return
	world_bb.set_value(creature.name + "_current_hunger", creature.stats.current_hunger)
	world_bb.set_value(creature.name + "_current_energy", creature.stats.current_energy)
	if nest:
		world_bb.set_value(creature.name + "_bed", nest.position)
	Eventbus.current_energy_updated.emit()
	Eventbus.current_hunger_updated.emit()

func _find_available_nest() -> Node2D:
	for node in get_tree().get_nodes_in_group("Nest"):
		if node.owned_by_creature == null:
			return node
	return null

func _find_nest_at_position(target_position: Vector2) -> Node2D:
	for node in get_tree().get_nodes_in_group("Nest"):
		if !node.has_method("owned_by_creature"):
			continue
		if node.global_position.distance_to(target_position) <= BED_MATCH_TOLERANCE:
			return node
	return null

func _serialize_player() -> Dictionary:
	return {
		"wallet": player.get_wallet_snapshot(),
		"known_buildables": player.get_known_buildable_keys(),
		"egg_inventory": player.get_egg_inventory_snapshot(),
	}

func _serialize_buildables() -> Array:
	var entries: Array = []
	if world_map == null:
		return entries
	for child in world_map.get_children():
		if child is Buildable:
			var buildable: Buildable = child
			entries.append({
				"buildable_key": buildable.buildable_key,
				"position": buildable.global_position,
			})
	return entries

func _build_bed_lookup() -> Dictionary:
	var lookup: Dictionary = {}
	for nest in get_tree().get_nodes_in_group("Nest"):
		if nest.has_method("owned_by_creature") and nest.owned_by_creature:
			lookup[nest.owned_by_creature] = nest.global_position
	return lookup

func _serialize_creatures() -> Array:
	var entries: Array = []
	var bed_lookup: Dictionary = _build_bed_lookup()
	for node in get_tree().get_nodes_in_group("Creature"):
		if node is Creature:
			var creature: Creature = node
			var creature_payload: Dictionary = creature.get_save_data()
			creature_payload["bed_position"] = bed_lookup.get(creature, creature.global_position)
			entries.append(creature_payload)
	return entries

func _restore_player(data: Dictionary) -> void:
	player.reset_owned_creatures()
	player.clear_known_buildables()
	player.set_wallet_from_save(data.get("wallet", {}))
	var known_buildables: Array = data.get("known_buildables", [])
	for key in known_buildables:
		player.learn_buildable_by_key(str(key), false)
	player.set_egg_inventory_from_save(data.get("egg_inventory", {}))
	Game.sync_egg_rewards(player)

func _restore_buildables(entries: Array) -> void:
	if world_map == null:
		return
	for entry in entries:
		var buildable_key: String = entry.get("buildable_key", "")
		if buildable_key == "" or !Data.buildable_library.has(buildable_key):
			continue
		var buildable: Buildable = Data.buildable_library[buildable_key].instantiate()
		world_map.add_child(buildable)
		if entry.has("position"):
			buildable.global_position = entry["position"]
		drop_area.register_buildable(buildable)

func _restore_creature(data: Dictionary) -> void:
	if creature_scene == null:
		return
	var creature: Creature = creature_scene.instantiate()
	creature.apply_save_data(data)
	var nest: Node2D = _assign_creature_to_bed(creature, data.get("bed_position", null))
	if nest == null:
		creature.queue_free()
		return
	if data.has("global_position"):
		creature.global_position = data["global_position"]
	_sync_creature_blackboard(creature, nest)
	player.adopt_creature(creature, false)

func _assign_creature_to_bed(creature: Creature, bed_position: Variant) -> Node2D:
	var target: Node2D = null
	if bed_position is Vector2:
		target = _find_nest_at_position(bed_position)
	if target == null:
		target = _find_available_nest()
	if target == null:
		Eventbus.notification_requested.emit("No available nests.")
		return null
	_attach_creature_to_nest(creature, target)
	return target

func _get_active_creatures() -> Array[Creature]:
	var creatures: Array[Creature] = []
	for node in get_tree().get_nodes_in_group("Creature"):
		if node is Creature:
			creatures.append(node)
	return creatures

func _queue_next_track() -> void:
	var keys: Array = Data.music_library.keys()
	if keys.is_empty():
		return
	var next_key : String = keys[randi_range(0, keys.size() - 1)]
	SoundManager.play_music(Data.music_library[next_key], 1)
