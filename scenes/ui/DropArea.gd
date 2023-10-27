extends Control

var world_map : TileMap = null
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _can_drop_data(at_position, data):
	if world_map != null:
		return true

func _drop_data(at_position, data):
	if get_parent().buildable_library.has(data.buildable_key):
		var new_item = get_parent().buildable_library[data.buildable_key].instantiate()
		new_item.global_position = world_map.map_to_local(world_map.local_to_map(get_global_mouse_position()))
		get_parent().add_child(new_item)
