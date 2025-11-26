extends Window
class_name HatchOddsWindow

@onready var title_label: Label = %TitleLabel
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var info_list: VBoxContainer = %InfoList
@onready var close_button: Button = %CloseButton

func _ready() -> void:
	close_requested.connect(_on_close_requested)
	if close_button:
		close_button.focus_mode = Control.FOCUS_NONE
		close_button.pressed.connect(_on_close_button_pressed)
	hide()

func open_with_entries(entries: Array[Dictionary], description: String = "") -> void:
	title_label.text = "Hatch Odds"
	_set_description(description)
	_populate_entries(entries)
	popup_centered()

func _populate_entries(entries: Array[Dictionary]) -> void:
	for child in info_list.get_children():
		child.queue_free()
	if entries.is_empty():
		var placeholder := Label.new()
		placeholder.text = "No hatch odds configured."
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
			line.text = "[b]%s[/b]\n%s" % [label_text, value_text]
		else:
			line.text = value_text
		info_list.add_child(line)

func _set_description(text: String) -> void:
	var trimmed := text.strip_edges()
	description_label.visible = trimmed != ""
	description_label.text = trimmed

func _on_close_requested() -> void:
	hide()

func _on_close_button_pressed() -> void:
	hide()
