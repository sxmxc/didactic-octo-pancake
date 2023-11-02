extends Control

var _buildable_item : Buildable = null
var _drag_preview_scene : PackedScene = preload("res://scenes/ui/drag_preview.tscn")

func set_item(buildable: Buildable):
	_buildable_item = buildable
	get_node("TextureRect").texture = _buildable_item.menu_icon_texture
	get_node("TextureRect/Label").text = _buildable_item.buildable_name
	
func get_item() -> Buildable:
	return _buildable_item

func _get_drag_data(at_position):
	var drag_preview = _drag_preview_scene.instantiate()
	
	drag_preview.get_node("TextureRect").texture = _buildable_item.menu_icon_texture
	drag_preview.scale = Vector2(2,2)
	set_drag_preview(drag_preview)
	return get_item()
