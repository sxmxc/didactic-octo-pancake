extends Window
class_name ItemDetailsWindow

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var info_list: VBoxContainer = %InfoList
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var actions_row: HBoxContainer = %ActionsRow

func _ready() -> void:
	close_requested.connect(_on_close_requested)
	hide()

func open_with_payload(payload: Dictionary) -> void:
	var win_title := str(payload.get("title", ""))
	var subtitle := str(payload.get("subtitle", ""))
	var description := str(payload.get("description", ""))
	var info_entries: Array = payload.get("info", [])
	var actions: Array = payload.get("actions", [])
	title_label.text = win_title
	subtitle_label.text = subtitle
	subtitle_label.visible = subtitle != ""
	_set_description(description)
	_populate_info(info_entries)
	_populate_actions(actions)
	popup_centered()

func _populate_info(entries: Array) -> void:
	for child in info_list.get_children():
		child.queue_free()
	if entries.is_empty():
		var placeholder := Label.new()
		placeholder.text = "No additional details."
		info_list.add_child(placeholder)
		return
	for entry in entries:
		if !(entry is Dictionary):
			continue
		var label_text := str(entry.get("label", ""))
		var value_text := str(entry.get("value", ""))
		var line := RichTextLabel.new()
		line.bbcode_enabled = true
		line.fit_content = true
		line.scroll_active = false
		if label_text != "":
			line.text = "[b]%s:[/b] %s" % [label_text, value_text]
		else:
			line.text = value_text
		info_list.add_child(line)

func _set_description(text: String) -> void:
	var trimmed := text.strip_edges()
	description_label.visible = trimmed != ""
	description_label.text = trimmed

func _populate_actions(actions: Array) -> void:
	for child in actions_row.get_children():
		child.queue_free()
	for action_dict in actions:
		if !(action_dict is Dictionary):
			continue
		var label := str(action_dict.get("label", ""))
		var callable_value: Variant = action_dict.get("callable", Callable())
		var button := Button.new()
		button.text = label if label != "" else "Action"
		button.focus_mode = Control.FOCUS_NONE
		if callable_value is Callable and callable_value.is_valid():
			button.pressed.connect(callable_value)
		else:
			button.disabled = true
		actions_row.add_child(button)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(hide)
	actions_row.add_child(close_button)

func _on_close_requested() -> void:
	hide()
