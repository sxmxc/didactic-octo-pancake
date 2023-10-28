extends ActionLeaf


func tick(actor, blackboard: Blackboard):
	if !actor.is_sleeping:
		actor.creature_anim.play("sleeping")
		actor.show_emotion("sleepy")
		actor.is_sleeping = true
		return RUNNING
	else:
		if actor.stats.energy >= 200:
			actor.stats.energy = 200
			blackboard.set_value(actor.name + "_energy", actor.stats.energy)
			return SUCCESS
		return RUNNING

