extends Control

var _buildable_item : Buildable = null

func set_item(buildable: Buildable):
	_buildable_item = buildable
	get_node("TextureRect").texture = _buildable_item.menu_icon_texture
	get_node("Label").text = _buildable_item.buildable_name
	
func get_item() -> Buildable:
	return _buildable_item

func _get_drag_data(at_position):
	var texture = TextureRect.new()
	var control = Control.new()
	control.add_child(texture)
	texture.pivot_offset = -0.5 * texture.size
	texture.texture = _buildable_item.menu_icon_texture
	texture.scale = Vector2(3,3)
	set_drag_preview(control)
	return get_item()
