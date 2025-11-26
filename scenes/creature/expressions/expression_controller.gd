extends Node
class_name ExpressionController

var _emotion_container: Node = null
var _thought_container: Node = null
var _emotion_bubble_scenes: Dictionary = {}
var _thought_bubble_scene: PackedScene = null
var _default_emotion_linger: float = 3.0

var _current_emotion: EmotionBubble = null
var _current_thought_bubble: ThoughtBubble = null
var _current_thought: String = ""
var _reveal_thought_after_emotion: bool = true
var _emotion_time_remaining: float = 0.0
var _configured: bool = false

func setup(emotion_node: Node, thought_node: Node, emotion_scenes: Dictionary, thought_scene: PackedScene, default_linger: float) -> void:
	_emotion_container = emotion_node
	_thought_container = thought_node
	_emotion_bubble_scenes = emotion_scenes.duplicate(true)
	_thought_bubble_scene = thought_scene
	_default_emotion_linger = default_linger
	_clear_emotion_instance()
	_hide_thought()
	_emotion_time_remaining = 0.0
	_configured = _emotion_container != null and _thought_container != null
	if !_configured:
		push_warning("ExpressionController missing containers; expressions disabled.")
	set_process(true)

func _process(delta: float) -> void:
	if _emotion_time_remaining <= 0.0:
		return
	_emotion_time_remaining -= delta
	if _emotion_time_remaining <= 0.0:
		_finish_emotion_sequence()

func set_current_thought(value: String, reveal_immediately: bool = false) -> void:
	_current_thought = value
	if reveal_immediately or !_has_active_emotion():
		_show_thought()

func show_thought(value: String, reveal_immediately: bool = true) -> void:
	set_current_thought(value, reveal_immediately)

func clear_thought() -> void:
	_current_thought = ""
	_hide_thought()

func show_emotion(emotion: String, custom_linger: float = -1.0, show_thought_after: bool = true) -> void:
	if !_configured:
		return
	_reveal_thought_after_emotion = show_thought_after
	if !_emotion_bubble_scenes.has(emotion):
		if show_thought_after:
			_show_thought()
		return
	_spawn_emotion_bubble(emotion)
	_emotion_time_remaining = _default_emotion_linger if custom_linger <= 0.0 else custom_linger
	if _emotion_time_remaining <= 0.0:
		_finish_emotion_sequence()

func clear_emotion() -> void:
	_clear_emotion_instance()
	_emotion_time_remaining = 0.0

func _spawn_emotion_bubble(emotion: String) -> void:
	_clear_emotion_instance()
	_hide_thought()
	var scene: PackedScene = _emotion_bubble_scenes[emotion]
	if scene == null:
		return
	var bubble: EmotionBubble = scene.instantiate() as EmotionBubble
	if bubble == null:
		return
	if is_instance_valid(_emotion_container):
		_emotion_container.add_child(bubble)
	else:
		add_child(bubble)
	bubble.play("default")
	_current_emotion = bubble

func _finish_emotion_sequence() -> void:
	_clear_emotion_instance()
	if _reveal_thought_after_emotion:
		_show_thought()

func _hide_thought() -> void:
	if _current_thought_bubble != null and is_instance_valid(_current_thought_bubble):
		_current_thought_bubble.queue_free()
	_current_thought_bubble = null

func _show_thought() -> void:
	if !_configured:
		return
	var sanitized: String = _current_thought.strip_edges()
	if sanitized == "":
		_hide_thought()
		return
	if _has_active_emotion():
		return
	if _current_thought_bubble == null or !is_instance_valid(_current_thought_bubble):
		if _thought_bubble_scene == null:
			return
		var bubble: ThoughtBubble = _thought_bubble_scene.instantiate() as ThoughtBubble
		if bubble == null:
			return
		if is_instance_valid(_thought_container):
			_thought_container.add_child(bubble)
		else:
			add_child(bubble)
		_current_thought_bubble = bubble
	_current_thought_bubble.set_text(sanitized)

func _clear_emotion_instance() -> void:
	if _current_emotion != null and is_instance_valid(_current_emotion):
		_current_emotion.queue_free()
	_current_emotion = null

func _has_active_emotion() -> bool:
	return _current_emotion != null and is_instance_valid(_current_emotion)
