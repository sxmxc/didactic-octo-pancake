@tool
extends ActionLeaf

@export var training_behavior_id: StringName = &"train"
@export_range(5.0, 40.0, 0.5, "suffix:fatigue") var fatigue_goal_delta: float = 18.0
@export_range(0.5, 5.0, 0.5, "suffix:points") var stat_gain_goal: float = 1.0

var _training_started: bool = false
var _training_stat: StringName = StringName()
var _starting_fatigue: float = 0.0
var _starting_stat_value: float = 0.0

func tick(actor, blackboard: Blackboard) -> int:
	if actor == null:
		_abort_active_training(null, blackboard)
		return FAILURE
	if actor.current_life_stage == "egg":
		_abort_active_training(actor, blackboard)
		return FAILURE
	if _training_started and !actor.is_training_active():
		return _finish_training_success()
	if !actor.is_training_active():
		_reset_training_trackers()
		return FAILURE
	if !_training_started:
		_capture_training_baselines(actor)
		var stat_key: StringName = actor.stats.active_training_stat if actor.stats else StringName()
		actor.set_behavior_state(training_behavior_id, {
			"label": "Training %s" % _format_stat(stat_key),
			"thought": "Focus and breathe.",
		})
	if _has_met_training_goal(actor):
		actor.cancel_training_session()
		return _finish_training_success()
	if actor.should_abort_training_for_needs():
		_abort_active_training(actor, blackboard)
		return FAILURE
	return RUNNING

func interrupt(actor, blackboard: Blackboard) -> void:
	_abort_active_training(actor, blackboard)
	super(actor, blackboard)

func _capture_training_baselines(actor: Creature) -> void:
	if actor == null or actor.stats == null:
		return
	_training_started = true
	_training_stat = actor.stats.active_training_stat
	_starting_fatigue = actor.stats.training_fatigue
	_starting_stat_value = _current_stat_value(actor.stats, _training_stat)

func _has_met_training_goal(actor: Creature) -> bool:
	var stats: CreatureStats = actor.stats
	if stats == null or _training_stat == StringName():
		return false
	if fatigue_goal_delta > 0.0 and stats.training_fatigue - _starting_fatigue >= fatigue_goal_delta:
		return true
	if stat_gain_goal > 0.0 and _current_stat_value(stats, _training_stat) - _starting_stat_value >= stat_gain_goal:
		return true
	return false

func _current_stat_value(stats: CreatureStats, stat_key: StringName) -> float:
	match stat_key:
		&"strength":
			return stats.strength
		&"intelligence":
			return stats.intelligence
		&"happiness":
			return stats.happiness
	return 0.0

func _format_stat(stat_key: StringName) -> String:
	if stat_key == StringName():
		return "stats"
	return String(stat_key).capitalize()

func _abort_active_training(actor: Creature, _blackboard: Blackboard) -> void:
	if actor and actor.is_training_active():
		actor.cancel_training_session()
	_reset_training_trackers()

func _finish_training_success() -> int:
	_reset_training_trackers()
	return SUCCESS

func _reset_training_trackers() -> void:
	_training_started = false
	_training_stat = StringName()
	_starting_fatigue = 0.0
	_starting_stat_value = 0.0
