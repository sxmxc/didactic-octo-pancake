@tool 
extends ActionLeaf


func tick(actor, blackboard: Blackboard):
	if !blackboard.has_value(actor.name + "_bed"):
		return FAILURE
	if actor.current_life_stage == "egg":
		return SUCCESS
	if blackboard.has_value(actor.name + "_bed_target"):
		if actor.navigation_agent.is_navigation_finished():
			blackboard.erase_value(actor.name + "_bed_target")
			return SUCCESS
		else:
			return RUNNING
	else:
		blackboard.set_value(actor.name + "_bed_target", blackboard.get_value(actor.name + "_bed"))
		actor.set_movement_target(blackboard.get_value(actor.name + "_bed_target"))
		actor.set_behavior_state("heading_home")
		return RUNNING
