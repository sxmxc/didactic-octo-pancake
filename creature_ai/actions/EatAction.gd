@tool
extends ActionLeaf

@export_range(0.5, 8.0, 0.1, "suffix:s") var chew_duration := 3.5
var _finish_timestamp_ms: int = 0
var _eating: bool = false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func tick(actor, _blackboard: Blackboard):
	if !_eating:
		_eating = true
		_finish_timestamp_ms = Time.get_ticks_msec() + int(chew_duration * 1000.0)
		actor.set_behavior_state("eat")
	if Time.get_ticks_msec() >= _finish_timestamp_ms:
		_eating = false
		return SUCCESS
	if _rng.randf() < 0.12:
		actor.show_emotion("love", 0.6)
	return RUNNING
