extends Node
class_name WorldPlacement

var world_map_layer: TileMapLayer
var drop_area: Control
var bed_match_tolerance: float = 8.0
var base_world_map_data: PackedByteArray = PackedByteArray()
var base_buildables: Array[Buildable] = []
var map_initialized: bool = false

func find_available_nest() -> Node2D:
	for node in _get_nests():
		if node is Nest and node.owned_by_creature == null:
			return node
	return null

func list_nests() -> Array[Nest]:
	return _get_nests()

func find_nest_at_position(target_position: Vector2) -> Nest:
	for node in _get_nests():
		if node is Nest and node.global_position.distance_to(target_position) <= bed_match_tolerance:
			return node
	return null

func build_bed_lookup() -> Dictionary:
	var lookup: Dictionary = {}
	for nest in _get_nests():
		if nest is Nest and nest.owned_by_creature:
			lookup[nest.owned_by_creature] = nest.global_position
	return lookup

func select_nest_for_creature(bed_position: Variant) -> Nest:
	var target: Node2D = null
	if bed_position is Vector2:
		target = find_nest_at_position(bed_position)
	if target == null:
		target = find_available_nest()
	if target == null:
		Eventbus.notification_requested.emit("No available nests.")
		return null
	return target as Nest

func cache_map_baseline() -> void:
	if world_map_layer == null:
		return
	base_world_map_data = world_map_layer.tile_map_data.duplicate()

func finalize_map_baseline() -> void:
	_capture_base_buildables()
	sync_base_buildables()
	map_initialized = true
	log_nest_context("baseline_init")

func restore_base_tiles() -> void:
	if world_map_layer == null:
		return
	if base_world_map_data.is_empty():
		world_map_layer.clear()
	else:
		world_map_layer.tile_map_data = base_world_map_data.duplicate()

func clear_dynamic_buildables() -> void:
	if world_map_layer == null:
		return
	world_map_layer.clear()
	for child in world_map_layer.get_children():
		if child is Buildable:
			var buildable: Buildable = child
			if !base_buildables.has(buildable):
				if drop_area and drop_area.has_method("forget_buildable"):
					drop_area.forget_buildable(buildable)
				buildable.queue_free()
	restore_base_tiles()
	sync_base_buildables()
	log_nest_context("clear_dynamic_buildables")

func sync_base_buildables() -> void:
	if world_map_layer == null or drop_area == null:
		return
	drop_area.clear_world_items()
	for child in world_map_layer.get_children():
		if child is Buildable:
			drop_area.register_buildable(child)

func ensure_base_nests() -> void:
	if world_map_layer == null:
		return
	var nests: Array = list_nests()
	if !nests.is_empty():
		return
	if !Data.buildable_library.has("BasicNest"):
		Tracer.warn("No BasicNest template available for fallback nest spawn")
		return
	var positions: Array[Vector2i] = [Vector2i.ZERO, Vector2i(2, 0)]
	for cell in positions:
		var instance: Buildable = Data.buildable_library["BasicNest"].instantiate()
		if instance == null:
			continue
		world_map_layer.add_child(instance)
		instance.position = world_map_layer.map_to_local(cell)
		if drop_area:
			drop_area.register_buildable(instance)
		base_buildables.append(instance)
	Tracer.warn("Spawned fallback nests at predefined cells because none were detected")
	log_nest_context("fallback_nests_spawned")

func instantiate_buildable_template(buildable_key: String) -> Buildable:
	if buildable_key == "" or !Data.buildable_library.has(buildable_key):
		return null
	return Data.buildable_library[buildable_key].instantiate()

func register_tile_buildable(cell: Vector2i) -> void:
	if world_map_layer == null or drop_area == null:
		return
	await get_tree().process_frame
	var instance := find_buildable_at_cell(cell)
	if instance != null and drop_area.has_method("register_buildable"):
		drop_area.register_buildable(instance)

func find_buildable_at_cell(cell: Vector2i) -> Buildable:
	if world_map_layer == null:
		return null
	var expected_position := world_map_layer.to_global(world_map_layer.map_to_local(cell))
	var tolerance := float(Vector2(world_map_layer.tile_set.tile_size).length()) if world_map_layer.tile_set else 64.0
	for child in world_map_layer.get_children():
		if child is Buildable:
			var buildable: Buildable = child
			if buildable.global_position.distance_to(expected_position) <= tolerance:
				return buildable
	return null

func _capture_base_buildables() -> void:
	base_buildables.clear()
	if world_map_layer == null:
		return
	for child in world_map_layer.get_children():
		if child is Buildable:
			base_buildables.append(child)

func _get_nests() -> Array[Nest]:
	var nests: Array[Nest] = []
	if world_map_layer:
		for child in world_map_layer.get_children():
			if child is Nest or child.is_in_group("nest"):
				nests.append(child)
	return nests

func log_nest_context(context: String) -> void:
	var nests: Array = list_nests()
	var info_parts: Array[String] = []
	for nest in nests:
		var owner_label: String = "none"
		if nest.has_method("owned_by_creature") and nest.owned_by_creature:
			owner_label = String(nest.owned_by_creature.name)
		info_parts.append("%s (owner=%s)" % [String(nest.name), owner_label])
	Tracer.info("%s: nests=%d [%s]" % [context, nests.size(), ", ".join(info_parts)])
