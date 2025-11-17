@tool
extends ActionLeaf

@export_range(0.5, 10.0, 0.5, "or_greater", "suffix:s") var duration_seconds: float = 3.0
@export var happiness_bonus: int = 5

func tick(actor, blackboard: Blackboard) -> int:
	var stats: CreatureStats = actor.stats
	if stats == null or stats.max_grooming_need <= 0:
		return FAILURE
	if actor.current_life_stage == "egg":
		return FAILURE
	var start_key: String = actor.name + "_grooming_started_ms"
	var now_ms: int = Time.get_ticks_msec()
	if !blackboard.has_value(start_key):
		blackboard.set_value(start_key, now_ms)
		actor.set_behavior_state("groom")
		return RUNNING
	var elapsed: float = float(now_ms - int(blackboard.get_value(start_key))) / 1000.0
	if elapsed < duration_seconds:
		return RUNNING
	blackboard.erase_value(start_key)
	var relief_amount: int = clampi(actor.grooming_relief_per_action, 0, stats.max_grooming_need)
	stats.current_grooming_need = clampi(stats.current_grooming_need - relief_amount, 0, stats.max_grooming_need)
	stats.happiness = clampi(stats.happiness + happiness_bonus, 0, 100)
	blackboard.set_value(actor.name + "_grooming_need", stats.current_grooming_need)
	return SUCCESS
