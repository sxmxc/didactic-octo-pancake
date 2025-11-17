@tool
extends ActionLeaf

@export_range(0.5, 12.0, 0.5, "or_greater", "suffix:s") var duration_seconds: float = 4.5
@export var hunger_penalty: int = 5
@export var energy_penalty: int = 10

func tick(actor, blackboard: Blackboard) -> int:
	var stats: CreatureStats = actor.stats
	if stats == null or stats.max_nest_cleanliness <= 0:
		return FAILURE
	if actor.current_life_stage == "egg":
		return FAILURE
	var start_key: String = actor.name + "_cleaning_started_ms"
	var now_ms: int = Time.get_ticks_msec()
	if !blackboard.has_value(start_key):
		blackboard.set_value(start_key, now_ms)
		actor.set_behavior_state("tidy_nest")
		return RUNNING
	var elapsed: float = float(now_ms - int(blackboard.get_value(start_key))) / 1000.0
	if elapsed < duration_seconds:
		return RUNNING
	blackboard.erase_value(start_key)
	var restore_amount: int = clampi(actor.nest_cleanliness_restore_per_action, 0, stats.max_nest_cleanliness)
	stats.nest_cleanliness = clampi(stats.nest_cleanliness + restore_amount, 0, stats.max_nest_cleanliness)
	stats.current_hunger = clampi(stats.current_hunger + hunger_penalty, 0, stats.max_hunger)
	stats.current_energy = clampi(stats.current_energy - energy_penalty, 0, stats.max_energy)
	blackboard.set_value(actor.name + "_nest_cleanliness", stats.nest_cleanliness)
	blackboard.set_value(actor.name + "_current_hunger", stats.current_hunger)
	blackboard.set_value(actor.name + "_current_energy", stats.current_energy)
	return SUCCESS
