@tool
extends ConditionLeaf

@export_range(0.0, 1.0, 0.01, "or_less", "suffix:%") var cleanliness_percent_threshold: float = 0.45

func tick(actor, blackboard: Blackboard) -> int:
	var stats: CreatureStats = actor.stats
	if stats == null or stats.max_nest_cleanliness <= 0:
		return FAILURE
	var cleanliness_key: String = actor.name + "_nest_cleanliness"
	if !blackboard.has_value(cleanliness_key):
		return FAILURE
	var current_cleanliness: float = float(blackboard.get_value(cleanliness_key))
	var ratio: float = current_cleanliness / float(stats.max_nest_cleanliness)
	if ratio <= cleanliness_percent_threshold:
		return SUCCESS
	return FAILURE
