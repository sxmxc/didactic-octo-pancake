@tool
extends ConditionLeaf

@export_range(0.0, 1.0, 0.01, "or_greater", "suffix:%") var hunger_percent_threshold: float = 0.3

func tick(actor, blackboard: Blackboard) -> int:
	var hunger_key: String = actor.name + "_current_hunger"
	if !blackboard.has_value(hunger_key):
		return FAILURE
	var stats: CreatureStats = actor.stats
	if stats == null or stats.max_hunger <= 0:
		return FAILURE
	var current_hunger: float = float(blackboard.get_value(hunger_key))
	var hunger_ratio: float = current_hunger / float(stats.max_hunger)
	if hunger_ratio >= hunger_percent_threshold:
		return SUCCESS
	return FAILURE
