@tool
extends ActionLeaf

@export_range(1.0, 8.0, 0.1, "suffix:s") var min_idle_duration := 2.0
@export_range(3.0, 18.0, 0.1, "suffix:s") var max_idle_duration := 6.0
var _idle_until: float = 0.0
var _started: bool = false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func tick(actor, _blackboard: Blackboard):
	if !_started:
		_started = true
		actor.set_behavior_state("idle")
		_idle_until = Time.get_ticks_msec() / 1000.0 + _rng.randf_range(min_idle_duration, max_idle_duration)
	if Time.get_ticks_msec() / 1000.0 >= _idle_until:
		_started = false
		return SUCCESS
	if _rng.randf() < 0.02:
		actor.show_emotion("idle", 0.8)
	return RUNNING
