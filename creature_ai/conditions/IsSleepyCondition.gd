@tool
extends ConditionLeaf


func tick(actor, blackboard: Blackboard):
	if actor.current_life_stage == "egg":
		return SUCCESS
	elif blackboard.get_value(actor.name + "_current_energy") <= 0:
		return SUCCESS
	else:
		actor.is_sleeping = false
		actor.show_emotion("happy")
		return FAILURE
