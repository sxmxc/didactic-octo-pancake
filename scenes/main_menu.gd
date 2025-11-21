extends Control

const LOAD_SCREEN_PATH := "res://scenes/ui/load_screen.tscn"

#@onready var _new_button: Button = %NewGameButton
@onready var _continue_button: Button = %ContinueButton
#@onready var _settings_button: Button = %SettingsButton
#@onready var _quit_button: Button = %QuitButton

var _has_save := false

func _ready():
	randomize()
	_play_random_track()
	_refresh_menu_state()

func _play_random_track() -> void:
	var music_available := Data.music_library.keys()
	if music_available:
		var index := randi_range(0, music_available.size() - 1)
		SoundManager.play_music(Data.music_library[music_available[index]])

func _refresh_menu_state() -> void:
	_has_save = SaveIO.slot_exists()
	_continue_button.disabled = !_has_save

func _start_world(new_session: bool) -> void:
	if new_session:
		SaveIO.delete_slot()
	SceneManager.load_scene("res://scenes/world.tscn", LOAD_SCREEN_PATH)

func _on_new_game_button_pressed() -> void:
	_start_world(true)

func _on_continue_button_pressed() -> void:
	if !_has_save:
		return
	_start_world(false)

func _on_settings_button_pressed() -> void:
	print("Settings menu coming soon")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
