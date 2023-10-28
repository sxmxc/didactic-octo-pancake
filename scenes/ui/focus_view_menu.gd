extends NinePatchRect

@export var meat_scene: PackedScene = preload("res://scenes/food/meat.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_world_view_button_pressed():
	Eventbus.world_view_requested.emit()
	pass # Replace with function body.

func _on_action_button_pressed():
	for target in get_tree().get_nodes_in_group("food_container"):
		if target.get_child_count() == 0:
			print("Adding food to available container")
			var food = meat_scene.instantiate()
			target.add_child(food)
			return
	print("No available food containers")
	pass # Replace with function body.
