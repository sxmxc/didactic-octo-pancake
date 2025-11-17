extends CanvasLayer
class_name WorldUI

var focused_creature: Creature = null
var pop_up_scene: PackedScene = preload("res://scenes/ui/pop_up_panel.tscn")
@onready var health_bar: SegmentedBar = %HealthBar
@onready var hunger_bar: SegmentedBar = %HungerBar
@onready var energy_bar: SegmentedBar = %EnergyBar
@onready var current_creature_stats: NinePatchRect = %CurrentCreatureStats
@onready var menu_bar: HUDMenuBar = %MenuBar

# Called when the node enters the scene tree for the first time.
func _ready():
	Eventbus.current_energy_updated.connect(_on_current_energy_updated)
	Eventbus.current_hunger_updated.connect(_on_current_hunger_updated)
	Eventbus.focus_view_requested.connect(_on_focus_requested)
	Eventbus.world_view_requested.connect(_on_world_view_requested)
	Eventbus.popup_requested.connect(_on_popup_requested)
	menu_bar.save_requested.connect(_on_save_requested)
	menu_bar.zoom_requested.connect(_on_zoom_requested)
	menu_bar.apply_profile(HUDMenuBar.Profile.WORLD)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_world_view_requested():
	Tracer.info("World view request recieved")
	set_focus(null)
	menu_bar.apply_profile(HUDMenuBar.Profile.WORLD)
	menu_bar.set_focus_creature(null)
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
	set_focus(creature)
	menu_bar.apply_profile(HUDMenuBar.Profile.FOCUS)
	menu_bar.set_focus_creature(creature)

func _on_popup_requested(mes : String):
	Tracer.info("Popup request received")
	show_popup(mes)

func set_focus(creature: Creature):
	focused_creature = creature
	if creature == null:
		%NameLabel.text = ""
		return
	%NameLabel.text = creature.creature_nickname

func _on_save_requested():
	var result := Game.manual_save_and_sleep()
	if result.get("ok", false):
		Eventbus.popup_requested.emit(result.get("message", "Progress saved. It is safe to close the app."))
	else:
		Eventbus.popup_requested.emit(result.get("message", "Save failed. Please try again."))

func _on_zoom_requested():
	Eventbus.world_view_requested.emit()

func show_popup(message: String):
	var popup = pop_up_scene.instantiate()
	popup.set_content(message)
	add_child(popup)
	popup.pop_up()
