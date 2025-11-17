@tool
extends ActionLeaf

const WAYPOINTS_KEY := "_wander_waypoints"
const PAUSE_KEY := "_wander_pause_until"
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func tick(actor, blackboard: Blackboard) -> int:
	if !actor.world_map:
		return FAILURE
	if actor.current_life_stage == "egg":
		return FAILURE
	var pause_key: String = str(actor.name) + PAUSE_KEY
	if blackboard.has_value(pause_key):
		var resume_time: int = int(blackboard.get_value(pause_key))
		if Time.get_ticks_msec() < resume_time:
			return RUNNING
		blackboard.erase_value(pause_key)
	var waypoint_key: String = str(actor.name) + WAYPOINTS_KEY
	var waypoints: Array[Vector2] = [] as Array[Vector2]
	if blackboard.has_value(waypoint_key):
		waypoints = blackboard.get_value(waypoint_key) as Array[Vector2]
	if waypoints.is_empty():
		waypoints = _build_waypoints(actor)
		if waypoints.is_empty():
			return FAILURE
		blackboard.set_value(waypoint_key, waypoints)
		actor.set_behavior_state("wander")
	var target: Vector2 = waypoints[0]
	if actor.navigation_agent.is_navigation_finished():
		waypoints.remove_at(0)
		if waypoints.is_empty():
			blackboard.erase_value(waypoint_key)
			if _rng.randf() < 0.35:
				blackboard.set_value(pause_key, Time.get_ticks_msec() + int(_rng.randf_range(900.0, 2200.0)))
			return SUCCESS
		blackboard.set_value(waypoint_key, waypoints)
		target = waypoints[0]
		if _rng.randf() < 0.4:
			actor.set_behavior_state("wander", {"thought": "Maybe over there?"})
	actor.set_movement_target(target)
	return RUNNING

func _build_waypoints(actor: Creature) -> Array[Vector2]:
	var used_rect: Rect2i = actor.world_map.get_used_rect()
	var steps: int = _rng.randi_range(1, 3)
	if used_rect.size == Vector2i.ZERO:
		return _build_fallback_points(actor, steps)
	var points: Array[Vector2] = [] as Array[Vector2]
	var margin := Vector2i(2, 2)
	for i in range(steps):
		var choice := _rng.randf()
		var candidate: Vector2
		if choice < 0.4:
			candidate = _point_near(actor, actor.global_position, actor.movement_range * 0.5, used_rect, margin)
		elif choice < 0.75:
			var offset := Vector2(_rng.randf_range(-actor.movement_range, actor.movement_range),
				_rng.randf_range(-actor.movement_range, actor.movement_range))
			candidate = _point_near(actor, actor.global_position + offset * 0.25, actor.movement_range * 0.35, used_rect, margin)
		else:
			var random_cell := Vector2i(
				_rng.randi_range(used_rect.position.x + margin.x, used_rect.position.x + used_rect.size.x - margin.x),
				_rng.randi_range(used_rect.position.y + margin.y, used_rect.position.y + used_rect.size.y - margin.y)
			)
			candidate = actor.world_map.map_to_local(random_cell)
		points.append(candidate)
	return points

func _build_fallback_points(actor: Creature, steps: int) -> Array[Vector2]:
	var points: Array[Vector2] = [] as Array[Vector2]
	for i in range(steps):
		var random_target := Vector2(
			_rng.randf_range(actor.global_position.x - actor.movement_range, actor.global_position.x + actor.movement_range),
			_rng.randf_range(actor.global_position.y - actor.movement_range, actor.global_position.y + actor.movement_range)
		)
		var map_coords: Vector2i = actor.world_map.local_to_map(actor.world_map.to_local(random_target))
		points.append(actor.world_map.map_to_local(map_coords))
	return points

func _point_near(actor: Creature, origin: Vector2, radius: float, used_rect: Rect2i, margin: Vector2i) -> Vector2:
	var clamped_origin_cell: Vector2i = actor.world_map.local_to_map(actor.world_map.to_local(origin))
	var random_cell := Vector2i(
		clampi(clamped_origin_cell.x + _rng.randi_range(-int(radius / 32.0), int(radius / 32.0)), used_rect.position.x + margin.x, used_rect.position.x + used_rect.size.x - margin.x),
		clampi(clamped_origin_cell.y + _rng.randi_range(-int(radius / 32.0), int(radius / 32.0)), used_rect.position.y + margin.y, used_rect.position.y + used_rect.size.y - margin.y)
	)
	return actor.world_map.map_to_local(random_cell)
