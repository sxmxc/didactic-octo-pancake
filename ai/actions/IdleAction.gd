extends ActionLeaf

var wait_time : float = 120
var wait_timer : float = wait_time
func tick(actor, _blackboard: Blackboard):
	var anim_sprite : AnimatedSprite2D = actor.sprite
	if wait_timer <= 0:
		if !anim_sprite.is_playing():
			anim_sprite.play("default")
			actor.show_emotion("happy")
		wait_timer = wait_time
		return SUCCESS
	else:
		if anim_sprite.is_playing():
			anim_sprite.pause()
			actor.show_emotion("idle")
		wait_timer -= 1
		return RUNNING

