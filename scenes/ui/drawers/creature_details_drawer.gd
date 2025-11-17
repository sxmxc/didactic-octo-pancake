extends MenuDrawer

@onready var name_value: Label = %NameValue
@onready var species_value: Label = %SpeciesValue
@onready var life_stage_value: Label = %LifeStageValue
@onready var mistakes_value: Label = %MistakesValue
@onready var strength_value: Label = %StrengthValue
@onready var intelligence_value: Label = %IntelligenceValue
@onready var happiness_value: Label = %HappinessValue

var focused_creature: Creature = null

func set_focus(creature: Creature) -> void:
	focused_creature = creature
	if _is_open:
		_refresh()

func _on_drawer_opening() -> void:
	_refresh()

func _refresh() -> void:
	if focused_creature == null:
		name_value.text = "--"
		species_value.text = "--"
		life_stage_value.text = "--"
		mistakes_value.text = "--"
		strength_value.text = "--"
		intelligence_value.text = "--"
		happiness_value.text = "--"
		return
	name_value.text = focused_creature.creature_nickname
	species_value.text = focused_creature.species.species_name
	life_stage_value.text = focused_creature.current_life_stage
	mistakes_value.text = str(focused_creature.stats.care_mistakes)
	strength_value.text = str(focused_creature.stats.strength)
	intelligence_value.text = str(focused_creature.stats.intelligence)
	happiness_value.text = str(focused_creature.stats.happiness)
