extends Node
class_name TrainingController

var creature: Creature
var _pending_training_hunger: float = 0.0
var _pending_training_energy: float = 0.0

func setup(host: Creature) -> void:
	creature = host

func _ready() -> void:
	if creature == null and owner is Creature:
		creature = owner as Creature

func begin_training_session(stat_key: StringName, duration_seconds: float, intensity: float = 1.0, station_id: StringName = StringName()) -> bool:
	if creature == null or creature.stats == null or creature.current_life_stage == "egg":
		return false
	if !creature.TRAINING_STAT_KEYS.has(stat_key):
		return false
	if duration_seconds <= 0.0:
		return false
	if creature.stats.training_fatigue >= creature.TRAINING_MAX_FATIGUE:
		return false
	if is_training_active():
		return false
	creature.stats.active_training_stat = stat_key
	creature.stats.active_training_seconds_remaining = duration_seconds
	creature.stats.active_training_intensity = clampf(intensity, creature.TRAINING_MIN_INTENSITY, creature.TRAINING_MAX_INTENSITY)
	creature.stats.last_training_station_id = station_id
	creature.stats.training_rest_seconds = 0.0
	creature.stats.last_training_epoch_ms = Time.get_ticks_msec()
	Eventbus.training_session_started.emit(creature, stat_key, duration_seconds)
	return true

func cancel_training_session() -> void:
	if !is_training_active():
		return
	var stat_key: StringName = creature.stats.active_training_stat
	creature.stats.active_training_stat = StringName()
	creature.stats.active_training_seconds_remaining = 0.0
	creature.stats.active_training_intensity = 0.0
	Eventbus.training_session_cancelled.emit(creature, stat_key)

func is_training_active() -> bool:
	if creature == null or creature.stats == null:
		return false
	if creature.stats.active_training_stat == StringName():
		return false
	return creature.stats.active_training_seconds_remaining > 0.0

func get_training_bonus(stat_key: StringName) -> int:
	return max(creature._get_stat_value(stat_key) - creature._get_stat_baseline(stat_key), 0)

func get_training_snapshot() -> Dictionary:
	if creature == null or creature.stats == null:
		return {}
	var per_stat: Dictionary = {}
	for stat_key in creature.TRAINING_STAT_KEYS:
		per_stat[stat_key] = {
			"current": creature._get_stat_value(stat_key),
			"baseline": creature._get_stat_baseline(stat_key),
			"cap": creature._get_stat_cap(stat_key),
			"bonus": max(creature._get_stat_value(stat_key) - creature._get_stat_baseline(stat_key), 0),
		}
	return {
		"active_stat": creature.stats.active_training_stat,
		"seconds_remaining": creature.stats.active_training_seconds_remaining,
		"intensity": creature.stats.active_training_intensity,
		"fatigue": creature.stats.training_fatigue,
		"fatigue_max": creature.TRAINING_MAX_FATIGUE,
		"rest_seconds": creature.stats.training_rest_seconds,
		"grace_seconds": creature.TRAINING_DECAY_GRACE_HOURS * creature.SECONDS_PER_HOUR,
		"stats": per_stat,
	}

func apply_training_tick(tick_interval_seconds: float, trait_modifiers: Dictionary) -> void:
	if creature == null or creature.stats == null:
		return
	if !is_training_active():
		return
	var stat_key: StringName = creature.stats.active_training_stat
	if !creature.TRAINING_STAT_KEYS.has(stat_key):
		cancel_training_session()
		return
	var seconds_delta: float = max(tick_interval_seconds, 0.1)
	creature.stats.active_training_seconds_remaining = max(creature.stats.active_training_seconds_remaining - seconds_delta, 0.0)
	var minutes_delta: float = seconds_delta / 60.0
	var xp_rate: float = 0.0
	if creature.creature_config:
		xp_rate = creature.creature_config.training_gain_per_minute.get(stat_key, 0.0)
	if xp_rate > 0.0:
		var fatigue_penalty: float = lerpf(1.0, 0.35, clampf(creature.stats.training_fatigue / creature.TRAINING_MAX_FATIGUE, 0.0, 1.0))
		var trait_multiplier: float = float(trait_modifiers.get("training_gain", 1.0))
		var xp_gain: float = xp_rate * minutes_delta * clampf(creature.stats.active_training_intensity, creature.TRAINING_MIN_INTENSITY, creature.TRAINING_MAX_INTENSITY) * fatigue_penalty * trait_multiplier
		_apply_training_gain(stat_key, xp_gain)
		creature.stats.last_training_epoch_ms = Time.get_ticks_msec()
	creature.stats.training_rest_seconds = 0.0
	_apply_training_resource_costs(stat_key, minutes_delta)
	_apply_training_fatigue(minutes_delta, creature.stats.active_training_intensity, trait_modifiers)
	if should_abort_training_for_needs():
		cancel_training_session()
		return
	Eventbus.training_progress_updated.emit(creature, stat_key, _build_training_progress_payload(stat_key))
	if creature.stats.active_training_seconds_remaining <= 0.01:
		_complete_training_session(stat_key)

func apply_training_decay_tick(tick_interval_seconds: float) -> void:
	if creature == null or creature.stats == null or creature.current_life_stage == "egg":
		return
	if is_training_active():
		return
	creature.stats.training_rest_seconds = clampf(creature.stats.training_rest_seconds + tick_interval_seconds, 0.0, creature.SECONDS_PER_HOUR * 24.0)
	_recover_training_fatigue(tick_interval_seconds)
	if creature.stats.training_rest_seconds < creature.TRAINING_DECAY_GRACE_HOURS * creature.SECONDS_PER_HOUR:
		return
	for stat_key in creature.TRAINING_STAT_KEYS:
		var current_value: int = creature._get_stat_value(stat_key)
		var baseline_value: int = creature._get_stat_baseline(stat_key)
		if current_value <= baseline_value:
			continue
		var per_hour: float = 0.0
		if creature.creature_config:
			per_hour = creature.creature_config.training_decay_per_hour.get(stat_key, 0.0)
		if per_hour <= 0.0:
			continue
		var decay_points: float = per_hour * (tick_interval_seconds / creature.SECONDS_PER_HOUR)
		_apply_training_decay(stat_key, decay_points)

func should_abort_training_for_needs() -> bool:
	if creature == null or creature.stats == null:
		return false
	if creature.stats.max_hunger > 0:
		var hunger_ratio: float = float(creature.stats.current_hunger) / float(creature.stats.max_hunger)
		if hunger_ratio >= creature.TRAINING_ABORT_MAX_HUNGER_RATIO:
			return true
	if creature.stats.max_energy > 0:
		var energy_ratio: float = float(creature.stats.current_energy) / float(creature.stats.max_energy)
		if energy_ratio <= creature.TRAINING_ABORT_MIN_ENERGY_RATIO:
			return true
	var fatigue_ratio: float = creature.stats.training_fatigue / max(creature.TRAINING_MAX_FATIGUE, 0.01)
	if fatigue_ratio >= creature.TRAINING_ABORT_MAX_FATIGUE_RATIO:
		return true
	return false

func _apply_training_resource_costs(stat_key: StringName, minutes_delta: float) -> void:
	var hunger_rate: float = 0.0
	if creature.creature_config:
		hunger_rate = creature.creature_config.training_hunger_cost_per_minute.get(stat_key, 0.0)
	if hunger_rate > 0.0:
		_pending_training_hunger += hunger_rate * minutes_delta * clampf(creature.stats.active_training_intensity, creature.TRAINING_MIN_INTENSITY, creature.TRAINING_MAX_INTENSITY)
		var hunger_steps: int = int(_pending_training_hunger)
		if hunger_steps > 0:
			creature.stats.current_hunger = clampi(creature.stats.current_hunger + hunger_steps, 0, creature.stats.max_hunger)
			_pending_training_hunger -= hunger_steps
	var energy_rate: float = 0.0
	if creature.creature_config:
		energy_rate = creature.creature_config.training_energy_cost_per_minute.get(stat_key, 0.0)
	if energy_rate > 0.0:
		_pending_training_energy += energy_rate * minutes_delta * clampf(creature.stats.active_training_intensity, creature.TRAINING_MIN_INTENSITY, creature.TRAINING_MAX_INTENSITY)
		var energy_steps: int = int(_pending_training_energy)
		if energy_steps > 0:
			creature.stats.current_energy = clampi(creature.stats.current_energy - energy_steps, 0, creature.stats.max_energy)
			_pending_training_energy -= energy_steps

func _apply_training_fatigue(minutes_delta: float, intensity: float, trait_modifiers: Dictionary) -> void:
	var trait_multiplier: float = float(trait_modifiers.get("training_fatigue", 1.0))
	var fatigue_gain: float = creature.TRAINING_FATIGUE_PER_MINUTE * minutes_delta * clampf(intensity, creature.TRAINING_MIN_INTENSITY, creature.TRAINING_MAX_INTENSITY) * trait_multiplier
	if fatigue_gain <= 0.0:
		return
	creature.stats.training_fatigue = clampf(creature.stats.training_fatigue + fatigue_gain, 0.0, creature.TRAINING_MAX_FATIGUE)

func _recover_training_fatigue(tick_interval_seconds: float) -> void:
	if creature.stats.training_fatigue <= 0.0:
		return
	var recovery: float = creature.TRAINING_FATIGUE_RECOVERY_PER_HOUR * (tick_interval_seconds / creature.SECONDS_PER_HOUR)
	if recovery <= 0.0:
		return
	creature.stats.training_fatigue = clampf(creature.stats.training_fatigue - recovery, 0.0, creature.TRAINING_MAX_FATIGUE)

func _apply_training_gain(stat_key: StringName, xp_gain: float) -> void:
	if xp_gain <= 0.0 or creature.stats == null:
		return
	var xp_per_point: float = 0.0
	if creature.creature_config:
		xp_per_point = creature.creature_config.training_xp_per_point.get(stat_key, 0.0)
	if xp_per_point <= 0.0:
		return
	var point_gain: float = xp_gain / xp_per_point
	var progress: float = creature._get_training_progress(stat_key)
	progress += point_gain
	var whole_points: int = int(progress)
	creature._set_training_progress(stat_key, progress - whole_points)
	if whole_points > 0:
		creature._increase_stat(stat_key, whole_points)

func _apply_training_decay(stat_key: StringName, decay_points: float) -> void:
	if decay_points <= 0.0:
		return
	var progress: float = creature._get_decay_progress(stat_key)
	progress += decay_points
	var whole_points: int = int(progress)
	creature._set_decay_progress(stat_key, progress - whole_points)
	if whole_points > 0:
		creature._decrease_stat(stat_key, whole_points)

func _complete_training_session(stat_key: StringName) -> void:
	creature.stats.active_training_stat = StringName()
	creature.stats.active_training_seconds_remaining = 0.0
	creature.stats.active_training_intensity = 0.0
	Eventbus.training_session_completed.emit(creature, stat_key)

func _build_training_progress_payload(stat_key: StringName) -> Dictionary:
	return {
		"stat": stat_key,
		"current": creature._get_stat_value(stat_key),
		"baseline": creature._get_stat_baseline(stat_key),
		"cap": creature._get_stat_cap(stat_key),
		"bonus": max(creature._get_stat_value(stat_key) - creature._get_stat_baseline(stat_key), 0),
		"seconds_remaining": creature.stats.active_training_seconds_remaining,
		"fatigue": creature.stats.training_fatigue,
		"fatigue_max": creature.TRAINING_MAX_FATIGUE,
	}
