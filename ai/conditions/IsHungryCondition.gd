extends ConditionLeaf

func tick(actor, blackboard: Blackboard):
	if !blackboard.has_value(actor.name + "_hunger"):
		return FAILURE
	if blackboard.get_value(actor.name + "_hunger") <= 0:
		return SUCCESS
	else:
		return FAILURE

