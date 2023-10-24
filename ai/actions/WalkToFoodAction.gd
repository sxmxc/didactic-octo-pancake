extends ActionLeaf

var closest_food: Food

func tick(actor, blackboard: Blackboard):
	if closest_food == null:
		closest_food = _find_closest_food(actor)
		if closest_food == null:
			return FAILURE
		actor.set_movement_target(closest_food.global_position)
		actor.show_emotion("hungry")
	if actor.navigation_agent.is_navigation_finished():
		actor.stats.hunger = 100
		blackboard.set_value(actor.name + "_hunger", actor.stats.hunger)
		if actor.owner.get_node("%HungerBar"):
			actor.owner.get_node("%HungerBar").value = 100
		closest_food.consume()
		closest_food = null
		actor.show_emotion("happy")
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
