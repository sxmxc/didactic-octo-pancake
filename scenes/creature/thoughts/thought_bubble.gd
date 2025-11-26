extends Node2D
class_name ThoughtBubble

const TAIL_OFFSET_Y: float = 12.0

@onready var bubble_panel: PanelContainer = $BubblePanel
@onready var thought_label: RichTextLabel = $BubblePanel/MarginContainer/ThoughtLabel
@onready var tail: Polygon2D = $Tail

var _layout_update_pending: bool = false

func _ready() -> void:
	_schedule_layout_update()

func set_text(value: String) -> void:
	thought_label.text = value
	_schedule_layout_update()

func _schedule_layout_update() -> void:
	if _layout_update_pending:
		return
	_layout_update_pending = true
	call_deferred("_refresh_layout")

func _refresh_layout() -> void:
	_layout_update_pending = false
	if bubble_panel == null or thought_label == null:
		return
	bubble_panel.reset_size()
	thought_label.reset_size()
	var desired_size: Vector2 = bubble_panel.get_combined_minimum_size()
	bubble_panel.size = desired_size
	bubble_panel.position = Vector2(-desired_size.x * 0.5, -desired_size.y - TAIL_OFFSET_Y)
	if tail:
		var tail_anchor_y: float = bubble_panel.position.y + desired_size.y
		tail.position = Vector2(0.0, tail_anchor_y)
