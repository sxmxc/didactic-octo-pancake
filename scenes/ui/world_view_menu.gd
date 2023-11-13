extends NinePatchRect
@export var meat_scene: PackedScene = preload("res://scenes/food/meat.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_new_creature_button_pressed():
	print("New creature requested")
	SoundManager.play_ui_sound(Data.sfx_library["click"])
	Eventbus.new_creature_requested.emit()
	pass # Replace with function body.


func _on_feed_button_pressed():
	var food = meat_scene.instantiate()
	SoundManager.play_ui_sound(Data.sfx_library["click"])
	Eventbus.feed_request.emit(food)
	pass # Replace with function body.
