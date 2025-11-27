extends Node
class_name WorldPersistence

var player: Player
var world_map_layer: TileMapLayer
var drop_area: Control
var placement: WorldPlacement
var creature_scene: PackedScene

func serialize_state(world: GameWorld) -> Dictionary:
	var buildable_count := world_map_layer.get_child_count() if world_map_layer else 0
	var creature_count := world.get_tree().get_nodes_in_group("Creature").size()
	Tracer.info("Serializing world state (tick_frequency=%d, buildables=%d, creatures=%d)" % [world.tick_frequency, buildable_count, creature_count])
	return {
		"world": {
			"tick_frequency": world.tick_frequency,
			"last_tick_epoch_ms": world._last_tick_epoch_ms,
			"player": _serialize_player(),
			"buildables": _serialize_buildables(),
			"creatures": _serialize_creatures(world),
		}
	}

func apply_saved_state(world: GameWorld, payload: Dictionary) -> bool:
	var world_data: Dictionary = payload.get("world", {})
	if world_data.is_empty():
		Tracer.warn("Apply saved state failed: missing world payload")
		return false
	Tracer.info("Applying saved world state (buildables=%d, creatures=%d)" % [world_data.get("buildables", []).size(), world_data.get("creatures", []).size()])
	world._reset_world_state()
	world.tick_frequency = int(world_data.get("tick_frequency", world.tick_frequency))
	if world.world_clock:
		world.world_clock.wait_time = world.tick_frequency
	_restore_player(world_data.get("player", {}))
	_restore_buildables(world_data.get("buildables", []))
	await get_tree().process_frame
	for creature_data in world_data.get("creatures", []):
		_restore_creature(world, creature_data)
	world._last_tick_epoch_ms = int(world_data.get("last_tick_epoch_ms", Time.get_ticks_msec()))
	Tracer.info("World state applied (tick_frequency=%d)" % world.tick_frequency)
	return true

func prepare_for_save(world: GameWorld) -> void:
	world._last_tick_epoch_ms = Time.get_ticks_msec()
	Tracer.info("Prepared world for save at %d ms" % world._last_tick_epoch_ms)

func _serialize_player() -> Dictionary:
	if player == null:
		return {}
	return {
		"wallet": player.get_wallet_snapshot(),
		"known_buildables": player.get_known_buildable_keys(),
		"egg_inventory": player.get_egg_inventory_snapshot(),
	}

func _serialize_buildables() -> Array:
	var entries: Array = []
	if world_map_layer == null:
		return entries
	for child in world_map_layer.get_children():
		if child is Buildable:
			var buildable: Buildable = child
			var cell: Vector2i = world_map_layer.local_to_map(world_map_layer.to_local(buildable.global_position))
			entries.append({
				"buildable_key": buildable.buildable_key,
				"position": buildable.global_position,
				"cell": cell,
				"tile_source_id": buildable.tile_source_id,
				"tile_id": buildable.tile_id,
				"tile_atlas_coords": buildable.tile_atlas_coords,
			})
	return entries

func _serialize_creatures(world: GameWorld) -> Array:
	var entries: Array = []
	var bed_lookup: Dictionary = placement.build_bed_lookup() if placement else {}
	for node in world.get_tree().get_nodes_in_group("Creature"):
		if node is Creature:
			var creature: Creature = node
			var creature_payload: Dictionary = creature.get_save_data()
			creature_payload["bed_position"] = bed_lookup.get(creature, creature.global_position)
			entries.append(creature_payload)
	return entries

func _restore_player(data: Dictionary) -> void:
	if player == null:
		return
	player.reset_owned_creatures()
	player.clear_known_buildables()
	player.set_wallet_from_save(data.get("wallet", {}))
	var known_buildables: Array = data.get("known_buildables", [])
	for key in known_buildables:
		player.learn_buildable_by_key(str(key), false)
	player.set_egg_inventory_from_save(data.get("egg_inventory", {}))
	Game.sync_egg_rewards(player)

func _restore_buildables(entries: Array) -> void:
	if world_map_layer == null:
		return
	world_map_layer.clear()
	for child in world_map_layer.get_children():
		if child is Buildable:
			child.queue_free()
	if placement:
		placement.restore_base_tiles()
	if drop_area:
		drop_area.clear_world_items()
	for entry in entries:
		var buildable_key: String = entry.get("buildable_key", "")
		if buildable_key == "":
			continue
		var template: Buildable = placement.instantiate_buildable_template(buildable_key) if placement else null
		var tile_source_id: int = int(entry.get("tile_source_id", template.tile_source_id if template != null else 1))
		var tile_id: int = int(entry.get("tile_id", template.tile_id if template != null else -1))
		var tile_atlas_coords: Vector2i = entry.get("tile_atlas_coords", template.tile_atlas_coords if template != null else Vector2i.ZERO)
		if tile_id < 0:
			if template != null:
				template.queue_free()
			continue
		var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
		if !(cell is Vector2i):
			if entry.has("position"):
				cell = world_map_layer.local_to_map(world_map_layer.to_local(entry["position"]))
			else:
				cell = Vector2i.ZERO
		world_map_layer.set_cell(cell, tile_source_id, tile_atlas_coords, tile_id)
		if placement:
			placement.register_tile_buildable(cell)
		if template != null:
			template.queue_free()
	if placement:
		placement.sync_base_buildables()
		placement.log_nest_context("restore_buildables_complete")

func _restore_creature(world: GameWorld, data: Dictionary) -> void:
	if creature_scene == null:
		return
	var creature: Creature = creature_scene.instantiate()
	creature.apply_save_data(data)
	var nest: Node2D = placement.select_nest_for_creature(data.get("bed_position", null)) if placement else null
	if nest == null:
		Tracer.warn("No nest found while restoring creature %s; retrying next frame" % creature.name)
		call_deferred("_retry_restore_creature_to_bed", world, creature, data)
		return
	_attach_restored_creature(world, creature, nest, data)

func _retry_restore_creature_to_bed(world: GameWorld, creature: Creature, data: Dictionary) -> void:
	if creature == null or !is_instance_valid(creature):
		return
	var nest: Node2D = placement.select_nest_for_creature(data.get("bed_position", null)) if placement else null
	if nest == null:
		Tracer.warn("Retry failed: still no nest for %s; discarding creature" % creature.name)
		creature.queue_free()
		return
	_attach_restored_creature(world, creature, nest, data)

func _attach_restored_creature(world: GameWorld, creature: Creature, nest: Node2D, data: Dictionary) -> void:
	world._attach_creature_to_nest(creature, nest)
	if data.has("global_position"):
		creature.global_position = data["global_position"]
	world._sync_creature_blackboard(creature, nest)
	if player:
		player.adopt_creature(creature, false)
