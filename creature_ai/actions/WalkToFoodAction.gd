@tool
extends ActionLeaf

var closest_food: Food
var _is_chasing := false

func tick(actor, blackboard: Blackboard):
	if closest_food == null:
		closest_food = _find_closest_food(actor)
		if closest_food == null:
			return FAILURE
		actor.set_movement_target(closest_food.global_position)
		actor.set_behavior_state("seek_food")
		_is_chasing = true
	if actor.navigation_agent.is_navigation_finished():
		blackboard.set_value(actor.name + "_current_hunger", actor.stats.current_hunger)
		Eventbus.current_hunger_updated.emit()
		if closest_food:
			closest_food.consume(actor)
		closest_food = null
		if _is_chasing:
			actor.set_behavior_state("eat")
		_is_chasing = false
		return SUCCESS
	return RUNNING
	

func _find_closest_food(actor):
	var current_distance = 9999999
	var current_closest_food = null
	for food in get_tree().get_nodes_in_group("Food"):
		var food_distance = actor.global_position.distance_to(food.global_position)
		if food_distance < current_distance:
			current_distance = food_distance
			current_closest_food = food
	return current_closest_food
