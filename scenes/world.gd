extends Node2D

signal tick

@export var tick_frequency: int = 10
@onready var world_bb: Blackboard = get_node("Blackboard")
@onready var player := %Player
@onready var world_camera : Camera2D = %WorldCamera
@export var creature_scene : PackedScene = preload("res://scenes/creature/creature.tscn")
@export var meat_scene: PackedScene = preload("res://scenes/food/meat.tscn")
var world_clock : Timer
var focused_creature: Creature = null
# Called when the node enters the scene tree for the first time.
func _ready():
	Eventbus.focus_view_requested.connect(_on_focus_view_requested)
	Eventbus.energy_updated.connect(_on_energy_updated)
	Eventbus.hunger_updated.connect(_on_hunger_updated)
	world_clock = Timer.new()
	add_child(world_clock)
	world_clock.connect("timeout", _on_timer_timeout)
	world_clock.wait_time = tick_frequency
	var new_creature : Creature = creature_scene.instantiate()
	world_clock.start()
	spawn_creature(new_creature)
	focused_creature = new_creature
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_timer_timeout():
	tick.emit()

func spawn_creature(creature: Creature):
	%WorldMap.add_child(creature)
	creature.set_owner(self)
	creature.position = %EggSpawn.position
	creature.register_worldmap(get_node("%WorldMap"))
	creature.register_blackboard(world_bb)
	creature.date_born = Time.get_unix_time_from_system()
	world_bb.set_value(creature.name + "_hunger", creature.stats.hunger)
	world_bb.set_value(creature.name + "_energy", creature.stats.energy)
	world_bb.set_value(creature.name+"_bed", %EggSpawn.position)
	world_clock.connect("timeout", creature._on_world_tick)
	player.adopt_creature(creature)


func _on_home_button_pressed():
	pass # Replace with function body.


func _on_world_view_button_pressed():
	print("World view requested")
	Eventbus.world_view_requested.emit()
	focused_creature = null
	if !world_camera.is_current():
		%CurrentCreatureStats.visible = false
		%WorldViewMenu.visible = true
		%FocusViewMenu.visible = false
		world_camera.enabled = true
		world_camera.make_current()
	pass # Replace with function body.

func _on_focus_view_requested(creature: Creature):
	print("Focus view reqeusted for " + creature.name)
	creature.camera.make_current()
	focused_creature = creature
	_on_energy_updated()
	_on_hunger_updated()
	%WorldViewMenu.visible = false
	%FocusViewMenu.visible = true
	%CurrentCreatureStats.visible = true

func _on_action_button_pressed():
	for target in get_tree().get_nodes_in_group("food_container"):
		if target.get_child_count() == 0:
			print("Adding food to available container")
			var food = meat_scene.instantiate()
			target.add_child(food)
			return
	pass # Replace with function body.

func _on_energy_updated():
	if focused_creature != null:
		%EnergyBar.value = focused_creature.stats.energy
	pass

func _on_hunger_updated():
	if focused_creature != null:
		%HungerBar.value = focused_creature.stats.hunger
	pass


func _on_new_creature_button_pressed():
	print("New creature requested")
	var new_creature : Creature = creature_scene.instantiate()
	spawn_creature(new_creature)
	pass # Replace with function body.
