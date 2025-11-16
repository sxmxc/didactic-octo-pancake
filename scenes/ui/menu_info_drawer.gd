extends UIDrawer
class_name MenuInfoDrawer

@onready var happiness_bar: SegmentedBar = %HappinessBar
@onready var strength_bar: SegmentedBar = %StrengthBar
@onready var intelligence_bar: SegmentedBar = %IntelligenceBar
@onready var main_container: MarginContainer = $MainContainer

var focused_creature : Creature = null

# Called when the node enters the scene tree for the first time.
func _ready():
	opening.connect(_on_open)
	closing.connect(_on_close)
	super._ready()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update()
	pass


func _on_creature_info_button_pressed():
	SoundManager.play_ui_sound(Data.sfx_library["click"])
	if !opened:
		main_container.show()
		open()
	else:
		close()
		main_container.hide()
	pass # Replace with function body.

func _on_open():
	
	update()
	pass

func _on_close():
	pass

func update():
	if !focused_creature:
		return
	%SpeciesEntry.get_node("Value").text = focused_creature.species.species_name
	%NameEntry.get_node("Value").text = focused_creature.creature_nickname
	%BirthEntry.get_node("Value").text = Time.get_date_string_from_unix_time(focused_creature.date_born)
	%AgeEntry.get_node("Value").text = "%s" % focused_creature.stats.age
	%LifeStageEntry.get_node("Value").text = focused_creature.current_life_stage
	%MistakesEntry.get_node("Value").text = "%s" % focused_creature.stats.care_mistakes
	
	happiness_bar.set_value(focused_creature.stats.happiness)
	strength_bar.set_value(focused_creature.stats.strength)
	intelligence_bar.set_value(focused_creature.stats.intelligence)
	
	if focused_creature.current_life_stage == "egg":
		%DeadEntry.get_node("Value").text = "%s" % "???"
	else:
		%DeadEntry.get_node("Value").text = "%s" % focused_creature.stats.is_dead
	
