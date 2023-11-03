extends CanvasLayer

var focused_creature: Creature = null

# Called when the node enters the scene tree for the first time.
func _ready():
	Eventbus.energy_updated.connect(_on_energy_updated)
	Eventbus.hunger_updated.connect(_on_hunger_updated)
	Eventbus.focus_view_requested.connect(_on_focus_requested)
	Eventbus.world_view_requested.connect(_on_world_view_requested)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_world_view_requested():
	print("World view requested")
	focused_creature = null
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
	%CurrentCreatureStats.get_node("TextureRect/NameLabel").text = creature.creature_nickname

func set_focus(creature: Creature):
	focused_creature = creature
	%FocusViewMenu.set_focus(creature)
