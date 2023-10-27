extends Control

var _buildable_item : Buildable = null

func set_item(buildable: Buildable):
	_buildable_item = buildable
	get_node("TextureRect").texture = _buildable_item.menu_icon_texture
	get_node("Label").text = _buildable_item.buildable_name
	
func get_item() -> Buildable:
	return _buildable_item

func _get_drag_data(at_position):
	var text = TextureRect.new()
	text.texture = _buildable_item.menu_icon_texture
	set_drag_preview(text)
	return get_item()
