extends PanelContainer
class_name CatalogItemPanel

signal details_requested(panel: CatalogItemPanel)

var title_label: Label
var count_label: Label
var actions_row: HBoxContainer
var status_label: Label

var _detail_text: String = ""
var _description_text: String = ""

func _ready() -> void:
	_resolve_nodes()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and !event.is_echo():
		details_requested.emit(self)

func _resolve_nodes() -> void:
	if title_label == null:
		title_label = $VBox/Header/TitleLabel
	if count_label == null:
		count_label = $VBox/Header/CountLabel
	if actions_row == null:
		actions_row = $VBox/ActionsRow
	if status_label == null:
		status_label = $VBox/StatusLabel

func set_title(text: String) -> void:
	_resolve_nodes()
	title_label.text = text

func get_title() -> String:
	_resolve_nodes()
	return title_label.text

func set_count_text(text: String) -> void:
	_resolve_nodes()
	count_label.text = text
	count_label.visible = text != ""

func set_detail_text(text: String) -> void:
	_detail_text = text
	_update_tooltip()

func get_detail_text() -> String:
	return _detail_text

func set_description(text: String) -> void:
	_description_text = text
	_update_tooltip()

func get_description_text() -> String:
	return _description_text

func get_actions_row() -> HBoxContainer:
	_resolve_nodes()
	return actions_row

func clear_actions() -> void:
	_resolve_nodes()
	for child in actions_row.get_children():
		child.queue_free()

func set_status_text(text: String) -> void:
	_resolve_nodes()
	status_label.text = text
	status_label.visible = text != ""

func get_status_text() -> String:
	_resolve_nodes()
	return status_label.text

func _update_tooltip() -> void:
	var lines: Array[String] = []
	if _detail_text != "":
		lines.append(_detail_text)
	if _description_text != "":
		lines.append(_description_text)
	if lines.is_empty():
		tooltip_text = ""
	else:
		tooltip_text = "\n\n".join(lines)
