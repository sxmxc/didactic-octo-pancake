@tool
extends ConditionLeaf

@export_range(0.0, 1.0, 0.01, "or_greater", "suffix:%") var need_percent_threshold: float = 0.6

func tick(actor, blackboard: Blackboard) -> int:
	var stats: CreatureStats = actor.stats
	if stats == null or stats.max_grooming_need <= 0:
		return FAILURE
	var need_key: String = actor.name + "_grooming_need"
	if !blackboard.has_value(need_key):
		return FAILURE
	var current_need: float = float(blackboard.get_value(need_key))
	var ratio: float = current_need / float(stats.max_grooming_need)
	if ratio >= need_percent_threshold:
		return SUCCESS
	return FAILURE
