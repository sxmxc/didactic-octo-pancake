extends ActionLeaf

func _ready():
	randomize()


func tick(actor, blackboard: Blackboard):
	if !actor.world_map:
		return FAILURE
	if actor.current_life_stage == "egg":
		return FAILURE
	var random_tile_target = actor.world_map.map_to_local(actor.world_map.local_to_map(Vector2(randi_range(actor.global_position.x - actor.movement_range, 
			actor.global_position.x + actor.movement_range), 
			randi_range(actor.global_position.y - actor.movement_range, 
			actor.global_position.y + actor.movement_range))))
	if !blackboard.has_value(actor.name + "_target"):
		blackboard.set_value(actor.name + "_target", random_tile_target)
		actor.set_movement_target(blackboard.get_value(actor.name + "_target"))
		#actor.creature_anim.play("walking")
		return RUNNING
		
	if actor.navigation_agent.is_navigation_finished():
		blackboard.erase_value(actor.name + "_target")
		return SUCCESS
	else:
		return RUNNING
