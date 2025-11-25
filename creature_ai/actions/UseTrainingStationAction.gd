@tool
extends ActionLeaf

@export_range(4.0, 128.0, 1.0, "suffix:px") var arrival_tolerance: float = 18.0
@export var travel_behavior_id: StringName = &"seek_training"
@export var training_behavior_id: StringName = &"train"
@export_range(5.0, 40.0, 0.5, "suffix:fatigue") var fatigue_goal_delta: float = 18.0
@export_range(0.5, 5.0, 0.5, "suffix:points") var stat_gain_goal: float = 1.0

var _target_station: TrainingStation = null
var _training_started: bool = false
var _training_stat: StringName = StringName()
var _starting_fatigue: float = 0.0
var _starting_stat_value: float = 0.0

func tick(actor, _blackboard: Blackboard) -> int:
	if actor == null:
		_target_station = null
		return FAILURE
	if actor.current_life_stage == "egg":
		_target_station = null
		return FAILURE
	if _training_started and !actor.is_training_active():
		return _finish_training_success()
	if actor.is_training_active():
		if !_training_started:
			_capture_training_baselines(actor)
		if _has_met_training_goal(actor):
			actor.cancel_training_session()
			return _finish_training_success()
		if actor.should_abort_training_for_needs():
			_abort_active_training(actor)
			return FAILURE
		if _target_station and !_target_station.is_training(actor):
			_target_station = null
		return RUNNING
	if _target_station == null or !_target_station.is_available_for(actor):
		_target_station = _select_station(actor)
		if _target_station == null:
			return FAILURE
		actor.set_behavior_state(travel_behavior_id, {
			"label": "Heading to %s" % _station_label(_target_station),
			"thought": "Time to grind.",
		})
	if _target_station == null:
		return FAILURE
	var entry_position: Vector2 = _target_station.get_entry_position()
	actor.set_movement_target(entry_position)
	if actor.navigation_agent.is_navigation_finished() or actor.global_position.distance_to(entry_position) <= arrival_tolerance:
		var began := _target_station.begin_training(actor)
		if began:
			actor.set_behavior_state(training_behavior_id, {
				"label": "Training %s" % _format_stat(_target_station.training_stat),
				"thought": "Focus and breathe.",
			})
			_capture_training_baselines(actor)
			return RUNNING
		_target_station = null
		return FAILURE
	return RUNNING

func interrupt(actor, blackboard: Blackboard) -> void:
	_abort_active_training(actor)
	super(actor, blackboard)

func _select_station(actor: Creature) -> TrainingStation:
	var best_station: TrainingStation = null
	var best_score: float = -INF
	for node in actor.get_tree().get_nodes_in_group("TrainingStation"):
		if node is TrainingStation:
			var station: TrainingStation = node
			if !station.is_available_for(actor):
				continue
			var stat_key: StringName = station.training_stat
			var stat_gap: float = _stat_gap(actor, stat_key)
			if stat_gap <= 0.0:
				continue
			var distance: float = actor.global_position.distance_to(station.get_entry_position())
			var score: float = stat_gap * 1000.0 - distance
			if score > best_score:
				best_station = station
				best_score = score
	return best_station

func _stat_gap(actor: Creature, stat_key: StringName) -> float:
	var stats: CreatureStats = actor.stats
	if stats == null:
		return 0.0
	match stat_key:
		&"strength":
			return max(stats.strength_cap - stats.strength, 0)
		&"intelligence":
			return max(stats.intelligence_cap - stats.intelligence, 0)
		&"happiness":
			return max(stats.happiness_cap - stats.happiness, 0)
	return 0.0

func _station_label(station: TrainingStation) -> String:
	if station == null:
		return "station"
	if station.buildable_name != "":
		return station.buildable_name
	return String(station.station_key)

func _format_stat(stat_key: StringName) -> String:
	if stat_key == StringName():
		return "stats"
	return String(stat_key).capitalize()

func _abort_active_training(actor: Creature) -> void:
	if actor and actor.is_training_active():
		actor.cancel_training_session()
	_target_station = null
	_reset_training_trackers()

func _finish_training_success() -> int:
	_target_station = null
	_reset_training_trackers()
	return SUCCESS

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

func _reset_training_trackers() -> void:
	_training_started = false
	_training_stat = StringName()
	_starting_fatigue = 0.0
	_starting_stat_value = 0.0
