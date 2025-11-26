extends Control

@export var world_map_layer: TileMapLayer = null

var world_items: Dictionary = {}
var _hover_indicator: ColorRect

func _ready() -> void:
	_create_hover_indicator()

func _process(_delta: float) -> void:
	if !_is_drop_active():
		_clear_hover_indicator()
		return
	_update_hover_indicator(_get_current_buildable(), _can_place_at_hover(_get_current_buildable()))

func _can_drop_data(_at_position, data) -> bool:
	var buildable: Buildable = _as_buildable(data)
	var can_drop: bool = world_map_layer != null and buildable != null
	_update_hover_indicator(buildable, _can_place_at_hover(buildable))
	return can_drop

func _drop_data(_at_position, data) -> void:
	Eventbus.buildable_drag_ended.emit()
	var buildable: Buildable = _as_buildable(data)
	if world_map_layer == null or buildable == null:
		return
	var cell := _get_hover_cell()
	if !_can_place(buildable, cell):
		SoundManager.play_sound(Data.sfx_library["error"])
		Eventbus.notification_requested.emit("Build location not clear")
		return
	_place_tile(buildable, cell)
	_clear_hover_indicator()
	SoundManager.play_sound(Data.sfx_library["click"])
	Game.queue_save("buildable_drop")

func register_buildable(buildable: Node2D) -> void:
	if world_map_layer == null or buildable == null:
		return
	var cell: Vector2i = world_map_layer.local_to_map(world_map_layer.to_local(buildable.global_position))
	world_items[cell] = buildable

func forget_buildable(buildable: Node2D) -> void:
	for cell_key in world_items.keys():
		if world_items[cell_key] == buildable:
			world_items.erase(cell_key)
			return

func clear_world_items() -> void:
	world_items.clear()

func _create_hover_indicator() -> void:
	_hover_indicator = ColorRect.new()
	_hover_indicator.color = Color(0, 1, 0, 0.25)
	_hover_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hover_indicator.visible = false
	add_child(_hover_indicator)

func _update_hover_indicator(buildable: Buildable, can_place: bool) -> void:
	if _hover_indicator == null or world_map_layer == null or buildable == null:
		_clear_hover_indicator()
		return
	var cell := _get_hover_cell()
	var tile_size: Vector2 = Vector2(world_map_layer.tile_set.tile_size) if world_map_layer.tile_set else Vector2(64, 64)
	var cell_center := world_map_layer.to_global(world_map_layer.map_to_local(cell))
	_hover_indicator.size = tile_size
	_hover_indicator.global_position = cell_center - (tile_size * 0.5)
	if can_place:
		_hover_indicator.color = Color(0, 1, 0, 0.25)
	else:
		_hover_indicator.color = Color(1, 0, 0, 0.35)
	_hover_indicator.visible = true

func _clear_hover_indicator() -> void:
	if _hover_indicator:
		_hover_indicator.visible = false

func _place_tile(buildable: Buildable, cell: Vector2i) -> void:
	world_map_layer.set_cell(cell, buildable.tile_source_id, buildable.tile_atlas_coords, buildable.tile_id)
	_register_cell_buildable_deferred(cell)

func _register_cell_buildable_deferred(cell: Vector2i) -> void:
	await get_tree().process_frame
	var instance: Buildable = _find_buildable_at_cell(cell)
	if instance != null:
		world_items[cell] = instance

func _find_buildable_at_cell(cell: Vector2i) -> Buildable:
	var expected_position := world_map_layer.to_global(world_map_layer.map_to_local(cell))
	var tolerance := float(Vector2(world_map_layer.tile_set.tile_size).length()) if world_map_layer.tile_set else 64.0
	for child in world_map_layer.get_children():
		if child is Buildable:
			var buildable: Buildable = child
			if buildable.global_position.distance_to(expected_position) <= tolerance:
				return buildable
	return null

func _as_buildable(data) -> Buildable:
	return data if data is Buildable else null

func _get_hover_cell() -> Vector2i:
	var local_position := world_map_layer.to_local(get_global_mouse_position())
	return world_map_layer.local_to_map(local_position)

func _is_drop_active() -> bool:
	return is_visible_in_tree()

func _get_current_buildable() -> Buildable:
	var drag_data: Variant = get_viewport().gui_get_drag_data()
	return _as_buildable(drag_data)

func _can_place(buildable: Buildable, cell: Vector2i) -> bool:
	if world_map_layer == null or buildable == null:
		return false
	return world_map_layer.get_cell_source_id(cell) == -1 and !world_items.has(cell)

func _can_place_at_hover(buildable: Buildable) -> bool:
	if world_map_layer == null or buildable == null:
		return false
	return _can_place(buildable, _get_hover_cell())
