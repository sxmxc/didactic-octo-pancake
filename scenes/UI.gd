extends CanvasLayer

@export var meat_scene: PackedScene = preload("res://scenes/food/meat.tscn")
var focused_creature: Creature = null



# Called when the node enters the scene tree for the first time.
func _ready():
	Eventbus.energy_updated.connect(_on_energy_updated)
	Eventbus.hunger_updated.connect(_on_hunger_updated)
	Eventbus.focus_view_requested.connect(_on_focus_requested)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_home_button_pressed():
	pass # Replace with function body.


func _on_world_view_button_pressed():
	print("World view requested")
	Eventbus.world_view_requested.emit()
	focused_creature = null
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

func _on_energy_updated():
	if focused_creature != null:
		%EnergyBar.value = focused_creature.stats.energy
	pass

func _on_hunger_updated():
	if focused_creature != null:
		%HungerBar.value = focused_creature.stats.hunger
	pass

func _on_focus_requested(creature: Creature):
	%CurrentCreatureStats.get_node("NameLabel").text = creature.creature_nickname

func _on_new_creature_button_pressed():
	print("New creature requested")
	Eventbus.new_creature_requested.emit()
	pass # Replace with function body.
