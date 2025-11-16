extends Node
class_name LoadScreen

@export var with_load_button: bool = true
@export var use_sub_threads: bool = true

@onready var _progress_bar: ProgressBar = $ColorRect/ProgressBar
@onready var _button: Button = $ColorRect/Button
@onready var _label: Label = $ColorRect/Label
@onready var _timer: Timer = $Timer

var _text_index = 0
const _label_texts: Array[String] = [
	"Loading     ",
	"Loading🦓    ",
	"Loading🦓 🐒  ",
	"Loading🦓 🐒 🦍",
]

func _ready() -> void:
	_timer.connect("timeout", _on_timeout)
	assert(SceneManager.connect("progress_changed", _on_progress_changed) == OK)
	_label.text = _label_texts[_text_index]
	_label.show()
	_button.hide()
	assert(_button.connect("pressed", _on_button_pressed) == OK)
	assert(SceneManager.connect("load_done", _on_load_done) == OK)
	SceneManager.change_scene_immediately = not with_load_button
	SceneManager.use_sub_threads = use_sub_threads
	SceneManager.start_load()

func _on_timeout() -> void:
	_text_index = _text_index + 1
	if _text_index > _label_texts.size() - 1:
		_text_index = 0
	_label.text = _label_texts[_text_index]

func _on_progress_changed(progress) -> void:
	_progress_bar.value = progress * 100.0

func _on_load_done() -> void:
	await get_tree().create_timer(3).timeout
	_label.hide()
	if not SceneManager.change_scene_immediately:
		_button.show()

func _on_button_pressed() -> void:
	SceneManager.change_scene()
