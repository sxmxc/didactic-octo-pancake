extends Buildable
class_name TrainingStation

@export var station_key: StringName = &"training_station"
@export var training_stat: StringName = &"strength"
@export_range(10.0, 600.0, 1.0, "or_greater", "suffix:s") var session_duration_seconds: float = 90.0
@export_range(0.4, 2.2, 0.05, "or_greater") var session_intensity: float = 1.0

@onready var entry_point: Node2D = get_node_or_null("EntryPoint")

var _active_creature: Creature = null

func _ready() -> void:
	add_to_group("TrainingStation")
	Eventbus.training_session_completed.connect(_on_training_session_finished)
	Eventbus.training_session_cancelled.connect(_on_training_session_finished)

func _exit_tree() -> void:
	if Eventbus.training_session_completed.is_connected(_on_training_session_finished):
		Eventbus.training_session_completed.disconnect(_on_training_session_finished)
	if Eventbus.training_session_cancelled.is_connected(_on_training_session_finished):
		Eventbus.training_session_cancelled.disconnect(_on_training_session_finished)

func _process(_delta: float) -> void:
	if _active_creature != null and !is_instance_valid(_active_creature):
		_active_creature = null

func get_entry_position() -> Vector2:
	if entry_point:
		return entry_point.global_position
	return global_position

func is_available_for(creature: Creature) -> bool:
	if creature == null:
		return false
	if _active_creature == null:
		return true
	if !is_instance_valid(_active_creature):
		_active_creature = null
		return true
	return _active_creature == creature

func is_training(creature: Creature) -> bool:
	return creature != null and _active_creature == creature

func begin_training(creature: Creature) -> bool:
	if creature == null:
		return false
	if !is_available_for(creature):
		return false
	if training_stat == StringName():
		return false
	if !Creature.TRAINING_STAT_KEYS.has(training_stat):
		return false
	var started := creature.begin_training_session(training_stat, session_duration_seconds, session_intensity, _station_identifier())
	if started:
		_active_creature = creature
	return started

func _station_identifier() -> StringName:
	if station_key != StringName():
		return station_key
	if buildable_key != "":
		return StringName(buildable_key)
	return StringName(name)

func _on_training_session_finished(creature: Creature, _stat: StringName) -> void:
	if creature == _active_creature:
		_active_creature = null
