extends CanvasLayer
class_name WorldUI

var focused_creature: Creature = null
var pop_up_scene: PackedScene = preload("res://scenes/ui/pop_up_panel.tscn")
@onready var health_bar: SegmentedBar = %HealthBar
@onready var hunger_bar: SegmentedBar = %HungerBar
@onready var energy_bar: SegmentedBar = %EnergyBar
@onready var current_creature_stats: NinePatchRect = %CurrentCreatureStats
@onready var world_view_menu: NinePatchRect = %WorldViewMenu
@onready var focus_view_menu: NinePatchRect = %FocusViewMenu

# Called when the node enters the scene tree for the first time.
func _ready():
	Eventbus.current_energy_updated.connect(_on_current_energy_updated)
	Eventbus.current_hunger_updated.connect(_on_current_hunger_updated)
	Eventbus.focus_view_requested.connect(_on_focus_requested)
	Eventbus.world_view_requested.connect(_on_world_view_requested)
	Eventbus.popup_requested.connect(_on_popup_requested)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_world_view_requested():
	Tracer.info("World view request recieved")
	focused_creature = null
	pass # Replace with function body.



func _on_current_energy_updated():
	if focused_creature != null:
		var new_value := clampf(float(focused_creature.stats.current_energy) / focused_creature.stats.max_energy,0,1)
		if new_value != energy_bar.value:
			energy_bar.change_rate = 0.5
			energy_bar.slow_change(new_value, Color("571c27"), 0.8)
	pass

func _on_current_hunger_updated():
	if focused_creature != null:
		var new_value = clampf(float(focused_creature.stats.current_hunger) / focused_creature.stats.max_hunger,0,1)
		if new_value != hunger_bar.value:
			hunger_bar.change_rate = 0.5
			hunger_bar.slow_change(new_value, Color("571c27"), 0.8)
	pass

func _on_focus_requested(creature: Creature):
	Tracer.info("Focus view request recieved for %s " % creature.name)
	%NameLabel.text = creature.creature_nickname

func _on_popup_requested(mes : String):
	Tracer.info("Popup request received")
	show_popup(mes)

func set_focus(creature: Creature):
	focused_creature = creature
	%FocusViewMenu.set_focus(creature)

func show_popup(message: String):
	var popup = pop_up_scene.instantiate()
	popup.set_content(message)
	add_child(popup)
	popup.pop_up()
