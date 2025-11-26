@tool
extends ActionLeaf

var closest_food: Food
var _is_chasing := false

func tick(actor, blackboard: Blackboard):
	if !(actor is Creature):
		return FAILURE
	var creature: Creature = actor
	if closest_food == null or !is_instance_valid(closest_food):
		closest_food = null
	if closest_food == null:
		closest_food = _find_closest_food(creature)
		if closest_food == null:
			return FAILURE
		creature.set_movement_target(closest_food.global_position)
		creature.set_behavior_state("seek_food")
		_is_chasing = true
	if creature.navigation_agent.is_navigation_finished():
		blackboard.set_value(creature.name + "_current_hunger", creature.stats.current_hunger)
		Eventbus.current_hunger_updated.emit()
		if closest_food:
			closest_food.consume(creature)
		closest_food = null
		if _is_chasing:
			creature.set_behavior_state("eat")
		_is_chasing = false
		return SUCCESS
	return RUNNING
	

func _find_closest_food(actor: Creature):
	if actor == null:
		return null
	var current_distance: float = INF
	var current_closest_food: Food = null
	for node in get_tree().get_nodes_in_group("Food"):
		if !(node is Food):
			continue
		var food: Food = node
		if !_is_food_compatible(food, actor):
			continue
		var food_distance: float = actor.global_position.distance_to(food.global_position)
		if food_distance < current_distance:
			current_distance = food_distance
			current_closest_food = food
	return current_closest_food

func _is_food_compatible(food: Food, actor: Creature) -> bool:
	if food == null or actor == null:
		return false
	if actor.species == null:
		return true
	return food.is_compatible_with_species(actor.species)
