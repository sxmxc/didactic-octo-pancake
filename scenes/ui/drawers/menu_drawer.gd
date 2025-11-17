extends Control
class_name MenuDrawer

enum Edge {
	TOP,
	BOTTOM,
}

@export var edge: Edge = Edge.BOTTOM
@export_range(0.05, 2.0, 0.01, "suffix:s") var tween_duration: float = 0.35
@export_range(0.0, 128.0, 1.0, "suffix:px") var handle_exposed: float = 16.0
@export_node_path("Control") var content_root_path: NodePath

var _content_root: Control
var _frame: Control
var _drawer_visual: Control
var _open_offset := Vector2.ZERO
var _closed_offset := Vector2.ZERO
var _tween: Tween
var _is_open := false
var _initial_root_mouse_filter := Control.MOUSE_FILTER_STOP
var _initial_visual_mouse_filter := Control.MOUSE_FILTER_STOP

signal opened
signal closed

func _ready() -> void:
	if content_root_path != NodePath(""):
		_content_root = get_node(content_root_path)
	else:
		_content_root = self
	if _content_root != self:
		_frame = _content_root.get_parent() as Control
	else:
		_frame = self
	_drawer_visual = _frame if _frame else _content_root
	_initial_visual_mouse_filter = _drawer_visual.mouse_filter if _drawer_visual else Control.MOUSE_FILTER_STOP
	_initial_root_mouse_filter = mouse_filter
	_recalculate_offsets()
	_apply_offset(_closed_offset)
	_set_drawer_interactive(false)

func is_open() -> bool:
	return _is_open

func open() -> void:
	if _is_open:
		return
	_recalculate_offsets()
	_play_tween(_open_offset, true)

func close() -> void:
	if !_drawer_visual:
		return
	if !_is_open and _drawer_visual.position == _closed_offset:
		return
	_recalculate_offsets()
	_play_tween(_closed_offset, false)

func _play_tween(target: Vector2, opening: bool) -> void:
	if _drawer_visual == null:
		return
	if _tween:
		_tween.kill()
	if opening:
		_set_drawer_interactive(true)
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_BACK)
	_tween.set_ease(Tween.EASE_OUT if opening else Tween.EASE_IN)
	_tween.tween_property(_drawer_visual, "position", target, tween_duration)
	_tween.tween_callback(func():
		_is_open = opening
		if opening:
			opened.emit()
		else:
			closed.emit()
			_set_drawer_interactive(false)
		_on_drawer_state_changed(opening)
	)
	if opening:
		_on_drawer_opening()

func toggle(request_open: bool) -> void:
	if request_open:
		open()
	else:
		close()

func _recalculate_offsets() -> void:
	if _drawer_visual == null:
		return
	var travel := _drawer_visual.get_combined_minimum_size().y
	travel = max(travel, _drawer_visual.size.y)
	travel = max(travel - handle_exposed, 0.0)
	_open_offset = Vector2.ZERO
	var direction := -travel
	if edge == Edge.BOTTOM:
		direction = travel
	_closed_offset = Vector2(0, direction)

func _apply_offset(offset: Vector2) -> void:
	if _drawer_visual:
		_drawer_visual.position = offset

func _set_drawer_interactive(active: bool) -> void:
	if active:
		mouse_filter = _initial_root_mouse_filter
		if _drawer_visual:
			_drawer_visual.visible = true
			_drawer_visual.mouse_filter = _initial_visual_mouse_filter
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _drawer_visual:
			_drawer_visual.visible = false
			_drawer_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_drawer_opening() -> void:
	# Hook for subclasses
	pass

func _on_drawer_state_changed(open_state: bool) -> void:
	# Hook for subclasses
	pass
