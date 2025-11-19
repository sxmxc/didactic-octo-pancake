extends MenuDrawer

@onready var name_value: Label = %NameValue
@onready var species_value: Label = %SpeciesValue
@onready var life_stage_value: Label = %LifeStageValue
@onready var mistakes_value: Label = %MistakesValue
@onready var strength_value: Label = %StrengthValue
@onready var intelligence_value: Label = %IntelligenceValue
@onready var happiness_value: Label = %HappinessValue
@onready var training_status_value: Label = %TrainingStatusValue
@onready var training_fatigue_value: Label = %TrainingFatigueValue
@onready var mood_value: Label = %MoodValue
@onready var action_value: Label = %ActionValue
@onready var thought_value: Label = %ThoughtValue
@onready var traits_value: Label = %TraitsValue

var focused_creature: Creature = null
var _refresh_timer := 0.0

func _ready() -> void:
	super._ready()
	Eventbus.creature_activity_changed.connect(_on_creature_activity_changed)

func _process(delta: float) -> void:
	if !_is_open or focused_creature == null:
		return
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.5
		_refresh()

func set_focus(creature: Creature) -> void:
	focused_creature = creature
	if _is_open:
		_refresh()

func _on_drawer_opening() -> void:
	_refresh()

func _on_creature_activity_changed(creature: Creature) -> void:
	if creature == focused_creature and _is_open:
		_refresh()

func _refresh() -> void:
	if focused_creature == null:
		name_value.text = "--"
		species_value.text = "--"
		life_stage_value.text = "--"
		mistakes_value.text = "--"
		traits_value.text = "--"
		strength_value.text = "--"
		intelligence_value.text = "--"
		happiness_value.text = "--"
		training_status_value.text = "--"
		training_fatigue_value.text = "--"
		mood_value.text = "--"
		action_value.text = "--"
		thought_value.text = "--"
		return
	name_value.text = focused_creature.creature_nickname
	species_value.text = focused_creature.species.species_name if focused_creature.species else "--"
	life_stage_value.text = focused_creature.current_life_stage
	mistakes_value.text = str(focused_creature.stats.care_mistakes)
	traits_value.text = _format_traits(focused_creature.get_trait_snapshot())
	strength_value.text = _format_stat_value(focused_creature.stats.strength, focused_creature.stats.strength_baseline, focused_creature.stats.strength_cap)
	intelligence_value.text = _format_stat_value(focused_creature.stats.intelligence, focused_creature.stats.intelligence_baseline, focused_creature.stats.intelligence_cap)
	happiness_value.text = _format_stat_value(focused_creature.stats.happiness, focused_creature.stats.happiness_baseline, focused_creature.stats.happiness_cap)
	var training_snapshot: Dictionary = focused_creature.get_training_snapshot()
	training_status_value.text = _format_training_status(training_snapshot)
	training_fatigue_value.text = _format_training_fatigue(training_snapshot)
	mood_value.text = focused_creature.get_current_mood_label()
	action_value.text = focused_creature.get_current_action_label()
	thought_value.text = focused_creature.get_current_thought()

func _format_stat_value(current: int, baseline: int, cap: int) -> String:
	var bonus: int = max(current - baseline, 0)
	if bonus > 0:
		return "%d (+%d) / %d" % [current, bonus, cap]
	return "%d / %d" % [current, cap]

func _format_training_status(snapshot: Dictionary) -> String:
	var stat_name: Variant = snapshot.get("active_stat", StringName())
	var seconds_remaining: float = float(snapshot.get("seconds_remaining", 0.0))
	if stat_name != StringName() and seconds_remaining > 0.0:
		return "Training %s (%s left)" % [String(stat_name).capitalize(), _format_duration(seconds_remaining)]
	var grace_seconds: float = float(snapshot.get("grace_seconds", 0.0))
	var rest_seconds: float = float(snapshot.get("rest_seconds", grace_seconds))
	if rest_seconds < grace_seconds:
		return "Resting (%s grace)" % _format_duration(grace_seconds - rest_seconds)
	return "Idle / Decaying"

func _format_training_fatigue(snapshot: Dictionary) -> String:
	var fatigue: float = float(snapshot.get("fatigue", 0.0))
	var fatigue_max: float = max(float(snapshot.get("fatigue_max", 100.0)), 1.0)
	var fatigue_ratio: float = fatigue / fatigue_max
	var descriptor := "Fresh"
	if fatigue_ratio >= 0.8:
		descriptor = "Exhausted"
	elif fatigue_ratio >= 0.5:
		descriptor = "Tired"
	elif fatigue_ratio >= 0.25:
		descriptor = "Warmed up"
	return "%d / %d (%s)" % [int(round(fatigue)), int(round(fatigue_max)), descriptor]

func _format_duration(seconds: float) -> String:
	var remaining: int = max(int(round(seconds)), 0)
	var minutes: int = remaining / 60
	var secs: int = remaining % 60
	if minutes > 0:
		return "%dm %02ds" % [minutes, secs]
	return "%ds" % secs

func _format_traits(entries: Array) -> String:
	if entries.is_empty():
		return "None"
	var lines: Array[String] = []
	for entry in entries:
		if entry is Dictionary:
			var label: String = entry.get("label", "--")
			var alignment_value: Variant = entry.get("alignment", "neutral")
			var alignment := "Neutral"
			if alignment_value is StringName:
				var raw := String(alignment_value)
				if raw != "":
					alignment = raw.capitalize()
			elif alignment_value is String:
				var str_value := String(alignment_value)
				if str_value != "":
					alignment = str_value.capitalize()
			var description := String(entry.get("description", ""))
			var summary := "%s [%s]" % [label, alignment]
			if description != "":
				summary += " - %s" % description
			lines.append(summary)
	return "\n".join(lines)
