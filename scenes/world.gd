extends Node2D

signal tick

@export var tick_frequency: int = 10
@onready var world_bb: Blackboard = get_node("Blackboard")
@onready var player : Player = %Player
@onready var world_camera : Camera2D = %WorldCamera
@onready var build_camera : Camera2D = %BuildCamera
@onready var ui = get_node("UI")
@onready var drop_area = get_node("DropArea")
@onready var world_map = %WorldMap


@export var buildable_library : Dictionary = {
	"BasicNest" : preload("res://buildables/nests/nest.tscn")
}

@export var creature_library : Dictionary = {
	"Creature0" : preload("res://scenes/creature/creature.tscn")
}

@export var creature_scene : PackedScene = creature_library["Creature0"]

var world_clock : Timer
var namegen : NameGenerator = NameGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	Eventbus.focus_view_requested.connect(_on_focus_view_requested)
	Eventbus.world_view_requested.connect(_on_world_view_requested)
	Eventbus.build_view_requested.connect(_on_build_view_requested)
	Eventbus.new_creature_requested.connect(_on_new_creature_requested)
	drop_area.world_map = world_map
	world_clock = Timer.new()
	add_child(world_clock)
	world_clock.connect("timeout", _on_timer_timeout)
	world_clock.wait_time = tick_frequency
	var new_creature : Creature = creature_scene.instantiate()
	new_creature.creature_nickname = namegen.new_name()[3]
	new_creature.name = new_creature.creature_nickname
	world_clock.start()
	spawn_creature(new_creature)
	Eventbus.focus_view_requested.emit(new_creature)
	player.learn_buildable(buildable_library["BasicNest"].instantiate())
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_timer_timeout():
	tick.emit()

func spawn_creature(creature: Creature):
	for target in get_tree().get_nodes_in_group("Nest"):
		if target.owned_by_creature == null:
			print("Adding egg to available nest")
			world_map.add_child(creature)
			target.owned_by_creature = creature
			creature.set_owner(self)
			creature.position = target.position
			creature.register_worldmap(world_map)
			creature.register_blackboard(world_bb)
			creature.date_born = Time.get_unix_time_from_system()
			world_bb.set_value(creature.name + "_hunger", creature.stats.hunger)
			world_bb.set_value(creature.name + "_energy", creature.stats.energy)
			world_bb.set_value(creature.name+"_bed", target.position)
			world_clock.connect("timeout", creature._on_world_tick)
			player.adopt_creature(creature)
			return
	print("No available nests")

func _on_focus_view_requested(creature: Creature):
	print("Focus view reqeusted for " + creature.name)
	creature.camera.make_current()
	ui.focused_creature = creature
	Eventbus.energy_updated.emit()
	Eventbus.hunger_updated.emit()
	%WorldViewMenu.visible = false
	%FocusViewMenu.visible = true
	%CurrentCreatureStats.visible = true

func _on_world_view_requested():
	if !world_camera.is_current():
		%CurrentCreatureStats.visible = false
		%WorldViewMenu.visible = true
		%FocusViewMenu.visible = false
		world_camera.enabled = true
		world_camera.make_current()

func _on_build_view_requested():
	print("Build view requested")
	if !build_camera.is_current():
		build_camera.enabled = true
		build_camera.make_current()
	
func _on_new_creature_requested():
	var new_creature : Creature = creature_scene.instantiate()
	var name_array : Array = namegen.new_name()
	new_creature.creature_nickname = name_array[randi_range(0,name_array.size()-1)]
	new_creature.name = new_creature.creature_nickname
	spawn_creature(new_creature)
