extends Control

var _buildable_item : Buildable = null
var _drag_preview_scene : PackedScene = preload("res://scenes/ui/drag_preview.tscn")
var _is_dragging: bool = false

func set_item(buildable: Buildable):
	_buildable_item = buildable
	%Icon.texture = _buildable_item.menu_icon_texture
	%Name.text = _buildable_item.buildable_name
	%Price.text = "%s %s" % [_buildable_item.buildable_cost, _buildable_item.build_cost_type.left(2)]
	
func get_item() -> Buildable:
	return _buildable_item

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		accept_event()
		_start_drag()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and !event.is_pressed():
		_is_dragging = false

func _input(event: InputEvent) -> void:
	if _is_dragging:
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if get_global_rect().has_point(event.position):
			_start_drag()

func _get_drag_data(_at_position):
	if _buildable_item == null:
		return null
	# Fallback if Godot's default drag triggers instead of force_drag.
	var drag_preview = _drag_preview_scene.instantiate()
	drag_preview.get_node("TextureRect").texture = _buildable_item.menu_icon_texture
	drag_preview.scale = Vector2(2,2)
	set_drag_preview(drag_preview)
	Eventbus.buildable_drag_started.emit()
	return get_item()

func _start_drag() -> void:
	if _buildable_item == null:
		return
	if _is_dragging:
		return
	var drag_preview: Control = _drag_preview_scene.instantiate()
	drag_preview.get_node("TextureRect").texture = _buildable_item.menu_icon_texture
	drag_preview.scale = Vector2(2, 2)
	force_drag(_buildable_item, drag_preview)
	_is_dragging = true
	Eventbus.buildable_drag_started.emit()
