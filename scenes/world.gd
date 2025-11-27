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
@onready var drop_area: Control = get_node("%DropArea")
@onready var world_map_layer: TileMapLayer = %WorldMapLayer
@onready var terrain_map_layer: TileMapLayer = %TerrainMapLayer
@onready var ui: WorldUI = %UI

var world_clock: Timer
var namegen: NameGenerator = NameGenerator.new()
var _last_tick_epoch_ms: int = 0
var _is_simulation_running: bool = false
var _camera_service: CameraPriorityService
var _cameras: WorldCameras
var _placement: WorldPlacement
var _simulation: WorldSimulation
var _persistence: WorldPersistence

func _ready():
	randomize()
	Eventbus.buildable_drag_started.connect(drop.show)
	Eventbus.buildable_drag_ended.connect(drop.hide)
	Eventbus.new_creature_requested.connect(_on_new_creature_requested)
	Eventbus.feed_request.connect(_on_feed_requested)
	Eventbus.egg_hatch_requested.connect(_on_egg_hatch_requested)
	_camera_service = CameraPriorityService.new()
	add_child(_camera_service)
	_cameras = WorldCameras.new()
	_cameras.camera_service = _camera_service
	_cameras.world_camera = world_camera
	_cameras.build_camera = build_camera
	_cameras.ui = ui
	add_child(_cameras)
	Eventbus.focus_view_requested.connect(_cameras.on_focus_view_requested)
	Eventbus.world_view_requested.connect(_cameras.on_world_view_requested)
	Eventbus.build_view_requested.connect(_cameras.on_build_view_requested)
	_placement = WorldPlacement.new()
	_placement.world_map_layer = world_map_layer
	_placement.drop_area = drop_area
	_placement.bed_match_tolerance = BED_MATCH_TOLERANCE
	add_child(_placement)
	drop_area.world_map_layer = world_map_layer
	if world_map_layer != null:
		_placement.cache_map_baseline()
		_placement.call_deferred("finalize_map_baseline")
	_simulation = WorldSimulation.new()
	add_child(_simulation)
	world_clock = _simulation.setup_timer(self, tick_frequency)
	_persistence = WorldPersistence.new()
	_persistence.player = player
	_persistence.world_map_layer = world_map_layer
	_persistence.drop_area = drop_area
	_persistence.placement = _placement
	_persistence.creature_scene = creature_scene
	add_child(_persistence)
	SoundManager.play_music(Data.music_library["cozy"], 1)
	SoundManager.track_finished.connect(_queue_next_track)
	Game.register_world(self)

func _process(_delta):
	pass

func start_new_session() -> void:
	Tracer.info("Bootstrapping new world session")
	_reset_world_state()
	if _placement and !_placement.map_initialized:
		_placement.finalize_map_baseline()
		_placement.sync_base_buildables()
	_bootstrap_player_profile()
	Game.sync_egg_rewards(player)
	_hatch_starter_creature()
	_last_tick_epoch_ms = Time.get_ticks_msec()

func begin_simulation() -> void:
	if _simulation:
		_simulation.begin_simulation(self)

func prepare_for_save() -> void:
	if _persistence:
		_persistence.prepare_for_save(self)

func serialize_state() -> Dictionary:
	if _persistence:
		return _persistence.serialize_state(self)
	return {}

func apply_saved_state(payload: Dictionary) -> bool:
	if _persistence:
		return await _persistence.apply_saved_state(self, payload)
	return false

func apply_idle_ticks(tick_count: int) -> void:
	if _simulation:
		_simulation.apply_idle_ticks(self, tick_count)

func spawn_creature(creature: Creature, track_save: bool = true) -> Creature:
	if _placement and !_placement.map_initialized and world_map_layer:
		_placement.finalize_map_baseline()
	if _placement:
		_placement.sync_base_buildables()
	_placement.log_nest_context("spawn_creature_pre_lookup")
	var target: Node2D = _placement.find_available_nest() if _placement else null
	if target == null:
		Tracer.warn("No nests found on first pass; ensuring fallback nests")
		_placement.ensure_base_nests()
		_placement.sync_base_buildables()
		_placement.log_nest_context("spawn_creature_retry")
		target = _placement.find_available_nest() if _placement else null
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
	if food == null:
		return
	Tracer.info("Food request received")
	if !_player_can_use_food(food):
		Eventbus.notification_requested.emit("None of your creatures can eat %s foods." % food.get_display_name())
		food.queue_free()
		return
	for target in get_tree().get_nodes_in_group("food_container"):
		if target.get_child_count() == 0:
			Tracer.info("Adding food to available container")
			target.add_child(food)
			return
	Eventbus.notification_requested.emit("No available food containers.")
	Tracer.info("No available food containers")
	food.queue_free()

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
	if _simulation:
		_simulation.stop_simulation(self)
	_is_simulation_running = false
	if _placement and !_placement.map_initialized and world_map_layer:
		_placement.cache_map_baseline()
		_placement.finalize_map_baseline()
	_teardown_creatures()
	if _placement:
		_placement.clear_dynamic_buildables()
	if drop_area:
		drop_area.clear_world_items()
	if world_bb:
		world_bb.blackboard = {}
	if _placement:
		_placement.sync_base_buildables()

func _teardown_creatures() -> void:
	for nest in get_tree().get_nodes_in_group("nest"):
		if nest.has_method("owned_by_creature"):
			nest.owned_by_creature = null
	for node in get_tree().get_nodes_in_group("Creature"):
		if node is Creature:
			node.queue_free()
	player.reset_owned_creatures()

func _bootstrap_player_profile() -> void:
	player.reset_owned_creatures()
	player.clear_known_buildables()
	player.set_wallet_from_save({"gold": 500, "gem": 0, "platinum": 0})
	player.learn_buildable(Data.buildable_library["BasicNest"].instantiate(), false)
	player.learn_buildable(Data.buildable_library["BasicFoodBowl"].instantiate(), false)
	player.learn_buildable(Data.buildable_library["GymPod"].instantiate(), false)
	player.learn_buildable(Data.buildable_library["StudyDesk"].instantiate(), false)
	player.clear_egg_inventory(false)
	player.grant_pack("brood_bundle", 1, false, false)
	player.open_pack("brood_bundle", false)

func _hatch_starter_creature() -> void:
	if _placement and !_placement.map_initialized:
		Tracer.warn("Map baseline not initialized; deferring starter hatch")
		call_deferred("_hatch_starter_creature")
		return
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
	if world_map_layer:
		world_map_layer.add_child(creature)
	creature.register_tilemap(terrain_map_layer)
	creature.register_blackboard(world_bb)
	if creature.has_method("set_world_tick_interval"):
		creature.set_world_tick_interval(float(tick_frequency))
	nest.owned_by_creature = creature
	creature.global_position = nest.global_position
	if _simulation:
		_simulation.register_creature_for_ticks(self, creature)

func _sync_creature_blackboard(creature: Creature, nest: Nest) -> void:
	if world_bb == null:
		return
	world_bb.set_value(creature.name + "_current_hunger", creature.stats.current_hunger)
	world_bb.set_value(creature.name + "_current_energy", creature.stats.current_energy)
	if nest:
		world_bb.set_value(creature.name + "_bed", nest.position)
	Eventbus.current_energy_updated.emit()
	Eventbus.current_hunger_updated.emit()

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

func _player_can_use_food(food: Food) -> bool:
	if player == null:
		return false
	return player.owns_creature_for_food(food)
