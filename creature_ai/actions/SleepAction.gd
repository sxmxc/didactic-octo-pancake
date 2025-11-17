@tool
extends ActionLeaf

func tick(actor, blackboard: Blackboard):
	if !actor.is_sleeping:
		actor.set_behavior_state("sleep")
		actor.is_sleeping = true
		return RUNNING
	else:
		if actor.stats.current_energy >= actor.stats.max_energy:
			actor.stats.current_energy = actor.stats.max_energy
			blackboard.set_value(actor.name + "_current_energy", actor.stats.current_energy)
			actor.is_sleeping = false
			actor.set_behavior_state("idle", {"emotion": "happy"})
			return SUCCESS
		actor.show_emotion("sleepy")
		return RUNNING
