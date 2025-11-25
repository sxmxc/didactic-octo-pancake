@tool
extends ConditionLeaf

@export_range(0.2, 0.95, 0.01, "suffix:%") var max_hunger_ratio: float = 0.7
@export_range(0.0, 0.8, 0.01, "suffix:%") var min_energy_ratio: float = 0.35
@export_range(0.1, 1.0, 0.01, "suffix:%") var max_fatigue_ratio: float = 0.75
@export_range(0.0, 1.0, 0.01, "suffix:%") var rest_grace_ratio: float = 0.2

func tick(actor, _blackboard: Blackboard) -> int:
	if actor == null:
		return FAILURE
	if actor.current_life_stage == "egg":
		return FAILURE
	if actor.is_training_active():
		return SUCCESS
	var stats: CreatureStats = actor.stats
	if stats == null:
		return FAILURE
	if !_has_available_station(actor):
		return FAILURE
	if stats.max_hunger > 0:
		var hunger_ratio: float = float(stats.current_hunger) / float(stats.max_hunger)
		if hunger_ratio >= max_hunger_ratio:
			return FAILURE
	if stats.max_energy > 0:
		var energy_ratio: float = float(stats.current_energy) / float(stats.max_energy)
		if energy_ratio <= min_energy_ratio:
			return FAILURE
	var fatigue_ratio: float = stats.training_fatigue / max(Creature.TRAINING_MAX_FATIGUE, 0.01)
	if fatigue_ratio >= max_fatigue_ratio:
		return FAILURE
	var grace_seconds: float = Creature.TRAINING_DECAY_GRACE_HOURS * Creature.SECONDS_PER_HOUR
	if grace_seconds > 0.0:
		var rest_ratio: float = stats.training_rest_seconds / grace_seconds
		if rest_ratio < rest_grace_ratio:
			return FAILURE
	return SUCCESS

func _has_available_station(actor: Creature) -> bool:
	for node in actor.get_tree().get_nodes_in_group("TrainingStation"):
		if node is TrainingStation:
			var station: TrainingStation = node
			if station.is_available_for(actor):
				return true
	return false
