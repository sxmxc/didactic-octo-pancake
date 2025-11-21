extends Control

var world_map : TileMapLayer = null
var world_items := {}
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _can_drop_data(_at_position, _data):
	if world_map != null:
		return true

func _drop_data(_at_position, data):
	Eventbus.buildable_drag_ended.emit()
	if Data.buildable_library.has(data.buildable_key):
		var target_position = _grid_snap_position(get_global_mouse_position()) 
		if world_items.has(target_position):
			SoundManager.play_sound(Data.sfx_library["error"])
			Eventbus.notification_requested.emit("Build location not clear")
			return
		var new_item = Data.buildable_library[data.buildable_key].instantiate()
		world_map.add_child(new_item)
		world_items[target_position] = new_item
		new_item.global_position = target_position
		SoundManager.play_sound(Data.sfx_library["click"])
		Game.queue_save("buildable_drop")

func register_buildable(buildable: Node2D):
	if world_map == null or buildable == null:
		return
	var key := _grid_snap_position(buildable.global_position)
	world_items[key] = buildable

func forget_buildable(buildable: Node2D):
	for entry_key in world_items.keys():
		if world_items[entry_key] == buildable:
			world_items.erase(entry_key)
			return

func clear_world_items():
	world_items.clear()

func _grid_snap_position(pos: Vector2) -> Vector2:
	if world_map == null:
		return pos
	var local_position := world_map.to_local(pos)
	var cell := world_map.local_to_map(local_position)
	return world_map.map_to_local(cell)
		
