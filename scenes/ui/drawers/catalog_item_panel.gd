extends PanelContainer
class_name CatalogItemPanel

var title_label: Label
var count_label: Label
var detail_label: Label
var description_label: Label
var actions_row: HBoxContainer
var status_label: Label

func _ready() -> void:
	_resolve_nodes()

func _resolve_nodes() -> void:
	if title_label == null:
		title_label = $VBox/Header/TitleLabel
	if count_label == null:
		count_label = $VBox/Header/CountLabel
	if detail_label == null:
		detail_label = $VBox/DetailLabel
	if description_label == null:
		description_label = $VBox/DescriptionLabel
	if actions_row == null:
		actions_row = $VBox/ActionsRow
	if status_label == null:
		status_label = $VBox/StatusLabel

func set_title(text: String) -> void:
	_resolve_nodes()
	title_label.text = text

func set_count_text(text: String) -> void:
	_resolve_nodes()
	count_label.text = text
	count_label.visible = text != ""

func set_detail_text(text: String) -> void:
	_resolve_nodes()
	detail_label.text = text
	detail_label.visible = text != ""

func set_description(text: String) -> void:
	_resolve_nodes()
	description_label.text = text
	description_label.visible = text != ""

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
