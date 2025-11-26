extends Window
class_name NotificationWindow

@onready var title_label: Label = %TitleLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var close_button: Button = %CloseButton

func _ready() -> void:
	close_requested.connect(_on_close_requested)
	if close_button:
		close_button.focus_mode = Control.FOCUS_NONE
		close_button.pressed.connect(_on_close_button_pressed)
	hide()

func open_message(message: String, arg_title: String = "Notice") -> void:
	title_label.text = arg_title
	_set_body(message)
	popup_centered()

func _set_body(message: String) -> void:
	var trimmed := message.strip_edges()
	body_label.text = trimmed

func _on_close_requested() -> void:
	hide()

func _on_close_button_pressed() -> void:
	hide()
