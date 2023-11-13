extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	var music_available = Data.music_library.keys()
	if music_available:
		var r = randi_range(0, music_available.size() - 1)
		SoundManager.play_music(Data.music_library[music_available[r]])
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_new_game_button_pressed():
	SceneManager.load_scene("res://scenes/world.tscn")
	pass # Replace with function body.
