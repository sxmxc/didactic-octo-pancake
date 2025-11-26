@tool
extends ActionLeaf

@export_range(4.0, 128.0, 1.0, "suffix:px") var arrival_tolerance: float = 18.0
@export var travel_behavior_id: StringName = &"seek_training"

var _target_station: TrainingStation = null

func tick(actor, _blackboard: Blackboard) -> int:
	if actor == null:
		_clear_target()
		return FAILURE
	if actor.current_life_stage == "egg":
		_clear_target()
		return FAILURE
	if actor.is_training_active():
		_clear_target()
		return SUCCESS
	if !_has_valid_target(actor):
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
		var began: bool = _target_station.begin_training(actor)
		if began:
			_clear_target()
			return SUCCESS
		_clear_target()
		return FAILURE
	return RUNNING

func interrupt(actor, blackboard: Blackboard) -> void:
	_clear_target()
	super(actor, blackboard)

func _has_valid_target(actor: Creature) -> bool:
	if _target_station == null:
		return false
	if !is_instance_valid(_target_station):
		return false
	if !_target_station.is_available_for(actor):
		return false
	return true

func _clear_target() -> void:
	_target_station = null

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
