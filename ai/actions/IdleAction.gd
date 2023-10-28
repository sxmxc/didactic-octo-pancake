extends ActionLeaf

var wait_time : float = 120
var wait_timer : float = wait_time
func tick(actor, _blackboard: Blackboard):
	if wait_timer <= 0:
		actor.creature_anim.play("walking")
		actor.show_emotion("happy")
		wait_timer = wait_time
		return SUCCESS
	else:
		if actor.creature_anim.current_animation == "walking":
			actor.creature_anim.play("idleing")
			actor.show_emotion("idle")
		wait_timer -= 1
		return RUNNING

