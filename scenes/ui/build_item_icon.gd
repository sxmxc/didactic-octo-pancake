extends Control

var _buildable_item : Buildable = null
var _drag_preview_scene : PackedScene = preload("res://scenes/ui/drag_preview.tscn")

func set_item(buildable: Buildable):
	_buildable_item = buildable
	get_node("TextureRect").texture = _buildable_item.menu_icon_texture
	get_node("TextureRect/Name").text = _buildable_item.buildable_name
	get_node("TextureRect/Cost").text = "%s %s" % [_buildable_item.buildable_cost, _buildable_item.build_cost_type.left(2)]
	
func get_item() -> Buildable:
	return _buildable_item

func _get_drag_data(_at_position):
	var drag_preview = _drag_preview_scene.instantiate()
	
	drag_preview.get_node("TextureRect").texture = _buildable_item.menu_icon_texture
	drag_preview.scale = Vector2(2,2)
	set_drag_preview(drag_preview)
	Eventbus.buildable_drag_started.emit()
	return get_item()
