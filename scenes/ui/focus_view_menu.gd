extends NinePatchRect

@export var meat_scene: PackedScene = preload("res://scenes/food/meat.tscn")
var focused_creature : Creature = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_world_view_button_pressed():
	SoundManager.play_ui_sound(Data.sfx_library["click"])
	focused_creature = null
	%InfoPanel.focused_creature = null
	Eventbus.world_view_requested.emit()
	pass # Replace with function body.

func _on_action_button_pressed():
	SoundManager.play_ui_sound(Data.sfx_library["click"])
	var food = meat_scene.instantiate()
	Eventbus.feed_request.emit(food)
	pass # Replace with function body.

func set_focus(creature: Creature):
	focused_creature = creature
	%InfoPanel.focused_creature = creature
