extends UIDrawer

var focused_creature : Creature = null

# Called when the node enters the scene tree for the first time.
func _ready():
	opening.connect(_on_open)
	closing.connect(_on_close)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update()
	pass


func _on_creature_info_button_pressed():
	if !opened:
		open()
	else:
		close()
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
	%HappinessEntry.get_node("Value").text = "%s" % focused_creature.stats.happiness
	%MistakesEntry.get_node("Value").text = "%s" % focused_creature.stats.care_mistakes
	%StrengthEntry.get_node("Value").text = "%s" % focused_creature.stats.strength
	%IntelligenceEntry.get_node("Value").text = "%s" % focused_creature.stats.intelligence
	if focused_creature.current_life_stage == "egg":
		%DeadEntry.get_node("Value").text = "%s" % "???"
	else:
		%DeadEntry.get_node("Value").text = "%s" % focused_creature.stats.is_dead
	
