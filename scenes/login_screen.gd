extends Control

@export var auto_login_delay: float = 1.5
@onready var status_label: Label = %StatusLabel
@onready var continue_button: Button = %ContinueButton

var _navigating := false

func _ready() -> void:
	continue_button.disabled = true
	status_label.text = "Connecting to server..."
	call_deferred("_simulate_login")

func _simulate_login() -> void:
	await get_tree().create_timer(auto_login_delay).timeout
	status_label.text = "Welcome back!"
	continue_button.disabled = false
	_go_to_main_menu()

func _on_continue_button_pressed() -> void:
	_go_to_main_menu()

func _go_to_main_menu() -> void:
	if _navigating:
		return
	_navigating = true
	status_label.text = "Loading main menu..."
	SceneManager.load_scene("res://scenes/main_menu.tscn", "", false)
