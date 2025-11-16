extends ConditionLeaf

func tick(actor, blackboard: Blackboard):
	if !blackboard.has_value(actor.name + "_current_hunger"):
		return FAILURE
	if blackboard.get_value(actor.name + "_current_hunger") <= 0:
		return SUCCESS
	else:
		return FAILURE
