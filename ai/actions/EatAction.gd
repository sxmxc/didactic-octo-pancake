@tool
extends ActionLeaf

@export var eat_time : float = 120
@onready var wait_timer : float = eat_time
func tick(actor, _blackboard: Blackboard):
	if wait_timer <= 0:
		#actor.creature_anim.play("walking")
		actor.show_emotion("idle")
		wait_timer = eat_time
		return SUCCESS
	else:
		#if actor.creature_anim.current_animation == "walking":
			##actor.creature_anim.play("idleing")
		actor.show_emotion("love")
		wait_timer -= 1
		return RUNNING
