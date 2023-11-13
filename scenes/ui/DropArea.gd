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
	if Data.buildable_library.has(data.buildable_key):
		var new_item = Data.buildable_library[data.buildable_key].instantiate()
		world_map.add_child(new_item)
		new_item.global_position = get_global_mouse_position()
		SoundManager.play_sound(Data.sfx_library["click"])
