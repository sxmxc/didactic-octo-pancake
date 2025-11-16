@tool
extends ActionLeaf

func tick(actor, blackboard: Blackboard):
	if !actor.is_sleeping:
		#actor.creature_anim.play("sleeping")
		actor.show_emotion("sleepy")
		actor.is_sleeping = true
		return RUNNING
	else:
		if actor.stats.current_energy >= 200:
			actor.stats.current_energy = 200
			blackboard.set_value(actor.name + "_current_energy", actor.stats.current_energy)
			return SUCCESS
		return RUNNING
