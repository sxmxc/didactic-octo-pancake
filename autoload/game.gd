extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	SoundManager.set_default_music_bus("Music")
	SoundManager.set_default_sound_bus("FX")
	SoundManager.set_default_ui_sound_bus("UI")
	print("Game Ready")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
