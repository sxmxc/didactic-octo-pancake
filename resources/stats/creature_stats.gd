extends Resource
class_name CreatureStats

const TraitState = preload("res://resources/traits/trait_state.gd")

@export_range(0, 999, 1) var strength: int = 0
@export_range(0, 999, 1) var intelligence: int = 0
@export_range(0, 999, 1) var happiness: int = 0
@export_range(0, 999, 1) var current_health: int = 100
@export_range(0, 999, 1) var max_health: int = 100
@export_range(0, 999, 1) var current_hunger: int = 0
@export_range(0, 999, 1) var max_hunger: int = 100
@export_range(0, 999, 1) var current_energy: int = 200
@export_range(0, 999, 1) var max_energy: int = 200
@export_range(0, 999, 1) var current_grooming_need: int = 0
@export_range(0, 999, 1) var max_grooming_need: int = 100
@export_range(0, 999, 1) var nest_cleanliness: int = 100
@export_range(0, 999, 1) var max_nest_cleanliness: int = 100
@export_range(0, 999, 1) var care_mistakes: int = 0
@export_range(0, 604800, 1) var seconds_alive: int = 0
@export_range(0, 3, 1) var age: int = 0
@export var is_dead: bool = false

@export_range(0, 999, 1) var strength_baseline: int = 0
@export_range(0, 999, 1) var intelligence_baseline: int = 0
@export_range(0, 999, 1) var happiness_baseline: int = 50
@export_range(0, 999, 1) var strength_cap: int = 100
@export_range(0, 999, 1) var intelligence_cap: int = 100
@export_range(0, 999, 1) var happiness_cap: int = 100
@export var strength_training_progress: float = 0.0
@export var intelligence_training_progress: float = 0.0
@export var happiness_training_progress: float = 0.0
@export var strength_decay_progress: float = 0.0
@export var intelligence_decay_progress: float = 0.0
@export var happiness_decay_progress: float = 0.0
@export_range(0, 86400, 0.1) var training_rest_seconds: float = 0.0
@export_range(0, 100, 0.01) var training_fatigue: float = 0.0
@export var last_training_epoch_ms: int = 0
@export var active_training_stat: StringName = StringName()
@export var active_training_seconds_remaining: float = 0.0
@export var active_training_intensity: float = 0.0
@export var last_training_station_id: StringName = StringName()
@export var traits: Array[TraitState] = []

func serialize_traits() -> Array:
	var snapshot: Array = []
	for state in traits:
		if state == null:
			continue
		if !state is TraitState:
			continue
		var typed_state: TraitState = state
		if typed_state.is_valid():
			snapshot.append(typed_state.to_dictionary())
	return snapshot

func apply_trait_snapshot(entries: Array) -> void:
	traits.clear()
	for entry in entries:
		if entry is Dictionary:
			var state := TraitState.new()
			state.apply_dictionary(entry)
			if state.is_valid():
				traits.append(state)
