class_name Creature 
extends CharacterBody2D

const SECONDS_PER_HOUR: float = 3600.0
const HUNGER_INTERACTIONS_PER_HOUR: float = 6.0
const ENERGY_DRAIN_CYCLES_PER_HOUR: float = 2.0
const SLEEP_RECOVERY_CYCLES_PER_HOUR: float = 4.0
const GROOMING_CYCLES_PER_HOUR: float = 1.5
const NEST_DECAY_CYCLES_PER_HOUR: float = 0.5

const CARE_MISTAKE_DECAY_HOURS: float = 1.0
const CARE_MISTAKE_RULES: Dictionary = {
	"starvation": {
		"stat": "hunger",
		"direction": "high",
		"trigger_ratio": 0.95,
		"recovery_ratio": 0.7,
		"ticks_required": 3,
		"display_label": "Starving",
	},
	"exhaustion": {
		"stat": "energy",
		"direction": "low",
		"trigger_ratio": 0.1,
		"recovery_ratio": 0.25,
		"ticks_required": 3,
		"display_label": "Exhausted",
	},
	"grimy": {
		"stat": "grooming",
		"direction": "high",
		"trigger_ratio": 0.9,
		"recovery_ratio": 0.5,
		"ticks_required": 4,
		"display_label": "Grimy",
	},
	"nest_neglect": {
		"stat": "nest",
		"direction": "low",
		"trigger_ratio": 0.2,
		"recovery_ratio": 0.4,
		"ticks_required": 5,
		"display_label": "Nest Neglect",
	},
}

const DEFAULT_STAGE_CARE_PROFILE: Dictionary = {
	"hunger": 1.0,
	"energy": 1.0,
	"sleep_energy": 1.0,
	"sleep_hunger_fraction": 0.5,
}

const LIFE_STAGE_CARE_PROFILE: Dictionary = {
	"egg": {
		"hunger": 0.0,
		"energy": 0.0,
		"sleep_energy": 0.0,
		"sleep_hunger_fraction": 0.0,
	},
	"baby": {
		"hunger": 1.2,
		"energy": 1.1,
		"sleep_energy": 0.9,
		"sleep_hunger_fraction": 0.35,
	},
	"teen": {
		"hunger": 1.0,
		"energy": 1.0,
		"sleep_energy": 1.0,
		"sleep_hunger_fraction": 0.45,
	},
	"adult": {
		"hunger": 0.8,
		"energy": 0.9,
		"sleep_energy": 1.1,
		"sleep_hunger_fraction": 0.6,
	},
}

const TRAINING_STAT_KEYS: Array[StringName] = [
	&"strength",
	&"intelligence",
	&"happiness",
]
const TRAINING_GAIN_PER_MINUTE: Dictionary = {
	"strength": 4.0,
	"intelligence": 3.5,
	"happiness": 2.5,
}
const TRAINING_XP_PER_POINT: Dictionary = {
	"strength": 6.0,
	"intelligence": 5.0,
	"happiness": 4.0,
}
const TRAINING_DECAY_PER_HOUR: Dictionary = {
	"strength": 1.25,
	"intelligence": 1.0,
	"happiness": 0.75,
}
const TRAINING_DECAY_GRACE_HOURS: float = 0.5
const TRAINING_HUNGER_COST_PER_MINUTE: Dictionary = {
	"strength": 3.0,
	"intelligence": 2.0,
	"happiness": 1.5,
}
const TRAINING_ENERGY_COST_PER_MINUTE: Dictionary = {
	"strength": 6.0,
	"intelligence": 4.0,
	"happiness": 3.0,
}
const TRAINING_FATIGUE_PER_MINUTE: float = 12.0
const TRAINING_FATIGUE_RECOVERY_PER_HOUR: float = 18.0
const TRAINING_MAX_FATIGUE: float = 100.0
const TRAINING_MIN_INTENSITY: float = 0.4
const TRAINING_MAX_INTENSITY: float = 2.2

const DEFAULT_THOUGHTS := [
	"Wonders if ghosts snore.",
	"Mentally rearranging the buildables.",
	"Debating if naps count as training.",
	"Imagining a world made of jelly.",
	"Practicing their best victory pose.",
	"Trying to remember where they hid the snacks.",
	"Wondering if humans hatch from eggs.",
	"Planning surprise conga lines.",
]

const ACTION_METADATA: Dictionary = {
	"idle": {
		"label": "Daydreaming",
		"thoughts": [
			"Blink... blink... oh hi.",
			"I swear that cloud winked at me.",
			"Is it nap time again already?"
		],
		"emotion": "idle",
	},
	"wander": {
		"label": "Exploring",
		"thoughts": [
			"Perimeter looks secure. Probably.",
			"New pebble acquired! Treasure?",
			"If I walk in circles I'll make crop art."
		],
		"emotion": "happy",
	},
	"seek_food": {
		"label": "Hunting snacks",
		"thoughts": [
			"If it's crunchy I'm in.",
			"My nose says the buffet is *that* way.",
			"Please let this be pizza."
		],
		"emotion": "hungry",
	},
	"eat": {
		"label": "Eating",
		"thoughts": [
			"Chomp city, population: me.",
			"Compliments to the chef (it's me).",
			"Culinary excellence unlocked."
		],
		"emotion": "love",
	},
	"heading_home": {
		"label": "Heading to bed",
		"thoughts": [
			"Calling dibs on the cozy corner.",
			"Bedtime pilgrimage commencing.",
			"Hope the sheets are still toasty."
		],
		"emotion": "idle",
	},
	"sleep": {
		"label": "Sleeping",
		"thoughts": [
			"Dreaming of endless buffets.",
			"Whale songs + white noise = perfection.",
			"zzz... (do not disturb)."
		],
		"emotion": "sleepy",
	},
	"groom": {
		"label": "Self-care",
		"thoughts": [
			"Can't go on stage with messy spikes.",
			"Polish, rinse, repeat.",
			"Glow-up loading..."
		],
		"emotion": "love",
	},
	"tidy_nest": {
		"label": "Tidying nest",
		"thoughts": [
			"Crumbs begone!",
			"Interior design montage music intensifies.",
			"This place is going to sparkle."
		],
		"emotion": "happy",
	}
}

@export var movement_speed: float = 20
@export var movement_range: int = 500

@export var age_chart : Dictionary = {
	"egg" : 30,
	"baby" : 43200,
	"teen" : 86400,
	"adult": 129600,
}
var current_life_stage = "egg"
@export var seconds_to_age : int = age_chart[current_life_stage]
@export var stats : CreatureStats
@export_range(0.5, 8.0, 0.1, "suffix:s") var emotion_linger_seconds: float = 3.0
@export_range(0, 100, 1) var grooming_relief_per_action: int = 40
@export_range(0, 100, 1) var nest_cleanliness_restore_per_action: int = 50
@export var emotion_bubbles: Dictionary = {
	"happy" : preload("res://scenes/creature/emotions/singing_bubble.tscn"), 
	"love" : preload("res://scenes/creature/emotions/love_bubble.tscn"),
	"angry": preload("res://scenes/creature/emotions/angry_bubble.tscn"), 
	"sleepy": preload("res://scenes/creature/emotions/sleeping_bubble.tscn"),
	"idle": preload("res://scenes/creature/emotions/idle_bubble.tscn"),
	"hungry": preload("res://scenes/creature/emotions/hungry_bubble.tscn")
}
@export var species : Species
@onready var navigation_agent: NavigationAgent2D = get_node("NavigationAgent2D")
@onready var bt: BeehaveTree = get_node("BeehaveTree")
@onready var egg_sprite: Sprite2D = get_node("EggSprite")
@onready var creature_sprite : Sprite2D = get_node("CreatureSprite")
#@onready var creature_anim : AnimationPlayer = get_node("AnimationPlayer")
@onready var emotion_container = get_node("EmotionContainer")
@onready var current_emotion : EmotionBubble = null
@onready var camera : PhantomCamera2D = get_node("Camera2D")
var world_map: TileMapLayer
var creature_nickname: StringName
var creature_name: StringName
var date_born
var is_sleeping = false
var _tick_interval_seconds: float = 10.0
var _pending_hunger_delta: float = 0.0
var _pending_energy_drain: float = 0.0
var _pending_sleep_energy: float = 0.0
var _pending_grooming_need: float = 0.0
var _pending_nest_decay: float = 0.0
var _pending_training_hunger: float = 0.0
var _pending_training_energy: float = 0.0
var current_action_id: StringName = &"idle"
var current_action_label: String = "Idling"
var current_thought: String = "Just hanging out."
var _last_behavior_change: float = 0.0
var _thought_rng := RandomNumberGenerator.new()
var _emotion_time_remaining: float = 0.0
var _care_mistake_state: Dictionary = {}
var _care_mistake_decay_ticks: int = 0

func _ready() -> void:
	if stats == null:
		stats = CreatureStats.new()
	else:
		stats = stats.duplicate(true) as CreatureStats
	_initialize_training_defaults()
	_thought_rng.randomize()
	if emotion_container.get_child_count() > 0:
		current_emotion = emotion_container.get_child(0)
	else:
		current_emotion = null
	navigation_agent.velocity_computed.connect(Callable(_on_navigation_agent_2d_velocity_computed))
	_apply_species_visuals()
	for mistake_id in CARE_MISTAKE_RULES.keys():
		_care_mistake_state[mistake_id] = {
			"ticks": 0,
			"active": false,
		}
	set_behavior_state("idle")

func _initialize_training_defaults() -> void:
	if stats == null:
		return
	if stats.strength_baseline <= 0:
		stats.strength_baseline = stats.strength
	if stats.intelligence_baseline <= 0:
		stats.intelligence_baseline = stats.intelligence
	if stats.happiness_baseline <= 0:
		stats.happiness_baseline = stats.happiness
	_clamp_training_values()
	if stats.active_training_seconds_remaining <= 0.0:
		stats.active_training_stat = StringName()
		stats.active_training_intensity = 0.0

func _clamp_training_values() -> void:
	if stats == null:
		return
	stats.strength = clampi(stats.strength, stats.strength_baseline, stats.strength_cap)
	stats.intelligence = clampi(stats.intelligence, stats.intelligence_baseline, stats.intelligence_cap)
	stats.happiness = clampi(stats.happiness, stats.happiness_baseline, stats.happiness_cap)
	stats.training_rest_seconds = clampf(stats.training_rest_seconds, 0.0, SECONDS_PER_HOUR * 24.0)
	stats.training_fatigue = clampf(stats.training_fatigue, 0.0, TRAINING_MAX_FATIGUE)

func set_species(spec: Species) -> void:
	species = spec
	if stats == null:
		stats = CreatureStats.new()
	if is_inside_tree():
		_apply_species_visuals()

func register_worldmap(map: TileMapLayer):
	world_map = map

func register_blackboard(bb: Blackboard):
	bt.blackboard = bb

func set_world_tick_interval(seconds: float) -> void:
	_tick_interval_seconds = clamp(seconds, 0.1, 3600.0)

func set_movement_target(movement_target: Vector2):
	navigation_agent.set_target_position(movement_target)

func _physics_process(_delta):
	if current_life_stage == "egg":
		return
		
	if navigation_agent.is_navigation_finished():
		return

	var next_path_position: Vector2 = navigation_agent.get_next_path_position()
	var current_agent_position: Vector2 = global_position
	var new_velocity: Vector2 = (next_path_position - current_agent_position).normalized() * movement_speed
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(new_velocity)
	
	if get_last_motion().x < 0:
		creature_sprite.flip_h = false
	else:
		creature_sprite.flip_h = true
		
func _process(delta: float) -> void:
	if _emotion_time_remaining > 0.0:
		_emotion_time_remaining -= delta
		if _emotion_time_remaining <= 0.0:
			_clear_active_emotion()
		

func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()
	pass # Replace with function body.

func _on_world_tick():
	_update_life_stage_progress()
	var stage_profile: Dictionary = _get_stage_care_profile()
	_apply_hunger_tick(stage_profile)
	if current_life_stage != "egg":
		if is_sleeping:
			_recover_energy_tick(stage_profile)
		else:
			_drain_energy_tick(stage_profile)
		_apply_grooming_tick()
		_apply_nest_decay_tick()
		_apply_training_tick()
	_apply_training_decay_tick()
	var has_active_neglect: bool = _evaluate_care_mistakes()
	_update_care_mistake_decay(has_active_neglect)
	_sync_stat_blackboard()

func _update_life_stage_progress() -> void:
	var current_time: float = Time.get_unix_time_from_system()
	stats.seconds_alive = int(round(current_time - date_born))
	if stats.seconds_alive >= seconds_to_age:
		_age_up()

func _get_stage_care_profile() -> Dictionary:
	if LIFE_STAGE_CARE_PROFILE.has(current_life_stage):
		return LIFE_STAGE_CARE_PROFILE[current_life_stage]
	return DEFAULT_STAGE_CARE_PROFILE

func _ticks_per_hour() -> float:
	return SECONDS_PER_HOUR / max(_tick_interval_seconds, 0.1)

func _calculate_base_rate(max_value: int, interactions_per_hour: float) -> float:
	if interactions_per_hour <= 0.0:
		return 0.0
	var ticks_per_hour: float = _ticks_per_hour()
	if ticks_per_hour <= 0.0:
		return 0.0
	return float(max(max_value, 1)) * interactions_per_hour / ticks_per_hour

func _apply_hunger_tick(stage_profile: Dictionary) -> void:
	var base_rate: float = _calculate_base_rate(stats.max_hunger, HUNGER_INTERACTIONS_PER_HOUR)
	if base_rate <= 0.0:
		return
	var stage_multiplier: float = float(stage_profile.get("hunger", 1.0))
	var species_multiplier: float = 1.0
	if species:
		species_multiplier = species.hunger_decay_multiplier
	var hunger_delta: float = base_rate * stage_multiplier * species_multiplier
	if hunger_delta <= 0.0:
		return
	if is_sleeping:
		var sleep_fraction: float = float(stage_profile.get("sleep_hunger_fraction", 1.0))
		var sleep_multiplier: float = 1.0
		if species:
			sleep_multiplier = species.sleep_hunger_multiplier
		hunger_delta *= clampf(sleep_fraction * sleep_multiplier, 0.0, 1.5)
	_pending_hunger_delta += hunger_delta
	var hunger_steps: int = int(_pending_hunger_delta)
	if hunger_steps <= 0:
		return
	stats.current_hunger = clampi(stats.current_hunger + hunger_steps, 0, stats.max_hunger)
	_pending_hunger_delta -= hunger_steps

func _drain_energy_tick(stage_profile: Dictionary) -> void:
	var base_rate: float = _calculate_base_rate(stats.max_energy, ENERGY_DRAIN_CYCLES_PER_HOUR)
	if base_rate <= 0.0:
		return
	var stage_multiplier: float = float(stage_profile.get("energy", 1.0))
	var species_multiplier: float = 1.0
	if species:
		species_multiplier = species.energy_decay_multiplier
	var energy_delta: float = base_rate * stage_multiplier * species_multiplier
	if energy_delta <= 0.0:
		return
	_pending_energy_drain += energy_delta
	var energy_steps: int = int(_pending_energy_drain)
	if energy_steps <= 0:
		return
	stats.current_energy = clampi(stats.current_energy - energy_steps, 0, stats.max_energy)
	_pending_energy_drain -= energy_steps

func _recover_energy_tick(stage_profile: Dictionary) -> void:
	var base_rate: float = _calculate_base_rate(stats.max_energy, SLEEP_RECOVERY_CYCLES_PER_HOUR)
	if base_rate <= 0.0:
		return
	var stage_multiplier: float = float(stage_profile.get("sleep_energy", 1.0))
	var species_multiplier: float = 1.0
	if species:
		species_multiplier = species.sleep_recovery_multiplier
	var energy_delta: float = base_rate * stage_multiplier * species_multiplier
	if energy_delta <= 0.0:
		return
	_pending_sleep_energy += energy_delta
	var energy_steps: int = int(_pending_sleep_energy)
	if energy_steps <= 0:
		return
	stats.current_energy = clampi(stats.current_energy + energy_steps, 0, stats.max_energy)
	_pending_sleep_energy -= energy_steps

func _apply_grooming_tick() -> void:
	if stats == null or stats.max_grooming_need <= 0:
		return
	var base_rate: float = _calculate_base_rate(stats.max_grooming_need, GROOMING_CYCLES_PER_HOUR)
	if base_rate <= 0.0:
		return
	_pending_grooming_need += base_rate
	var need_steps: int = int(_pending_grooming_need)
	if need_steps <= 0:
		return
	stats.current_grooming_need = clampi(stats.current_grooming_need + need_steps, 0, stats.max_grooming_need)
	_pending_grooming_need -= need_steps

func _apply_nest_decay_tick() -> void:
	if stats == null or stats.max_nest_cleanliness <= 0:
		return
	var base_rate: float = _calculate_base_rate(stats.max_nest_cleanliness, NEST_DECAY_CYCLES_PER_HOUR)
	if base_rate <= 0.0:
		return
	_pending_nest_decay += base_rate
	var decay_steps: int = int(_pending_nest_decay)
	if decay_steps <= 0:
		return
	stats.nest_cleanliness = clampi(stats.nest_cleanliness - decay_steps, 0, stats.max_nest_cleanliness)
	_pending_nest_decay -= decay_steps

func begin_training_session(stat_key: StringName, duration_seconds: float, intensity: float = 1.0, station_id: StringName = StringName()) -> bool:
	if stats == null or current_life_stage == "egg":
		return false
	if !TRAINING_STAT_KEYS.has(stat_key):
		return false
	if duration_seconds <= 0.0:
		return false
	if stats.training_fatigue >= TRAINING_MAX_FATIGUE:
		return false
	if _is_training_active():
		return false
	stats.active_training_stat = stat_key
	stats.active_training_seconds_remaining = duration_seconds
	stats.active_training_intensity = clampf(intensity, TRAINING_MIN_INTENSITY, TRAINING_MAX_INTENSITY)
	stats.last_training_station_id = station_id
	stats.training_rest_seconds = 0.0
	stats.last_training_epoch_ms = Time.get_ticks_msec()
	Eventbus.training_session_started.emit(self, stat_key, duration_seconds)
	return true

func cancel_training_session() -> void:
	if !_is_training_active():
		return
	var stat_key: StringName = stats.active_training_stat
	stats.active_training_stat = StringName()
	stats.active_training_seconds_remaining = 0.0
	stats.active_training_intensity = 0.0
	Eventbus.training_session_cancelled.emit(self, stat_key)

func is_training_active() -> bool:
	return _is_training_active()

func get_training_bonus(stat_key: StringName) -> int:
	return max(_get_stat_value(stat_key) - _get_stat_baseline(stat_key), 0)

func get_training_snapshot() -> Dictionary:
	if stats == null:
		return {}
	var per_stat: Dictionary = {}
	for stat_key in TRAINING_STAT_KEYS:
		per_stat[stat_key] = {
			"current": _get_stat_value(stat_key),
			"baseline": _get_stat_baseline(stat_key),
			"cap": _get_stat_cap(stat_key),
			"bonus": max(_get_stat_value(stat_key) - _get_stat_baseline(stat_key), 0),
		}
	return {
		"active_stat": stats.active_training_stat,
		"seconds_remaining": stats.active_training_seconds_remaining,
		"intensity": stats.active_training_intensity,
		"fatigue": stats.training_fatigue,
		"fatigue_max": TRAINING_MAX_FATIGUE,
		"rest_seconds": stats.training_rest_seconds,
		"grace_seconds": TRAINING_DECAY_GRACE_HOURS * SECONDS_PER_HOUR,
		"stats": per_stat,
	}

func _apply_training_tick() -> void:
	if !_is_training_active():
		return
	if stats == null:
		return
	var stat_key: StringName = stats.active_training_stat
	if !TRAINING_STAT_KEYS.has(stat_key):
		cancel_training_session()
		return
	var seconds_delta: float = max(_tick_interval_seconds, 0.1)
	stats.active_training_seconds_remaining = max(stats.active_training_seconds_remaining - seconds_delta, 0.0)
	var minutes_delta: float = seconds_delta / 60.0
	var xp_rate: float = TRAINING_GAIN_PER_MINUTE.get(stat_key, 0.0)
	if xp_rate > 0.0:
		var fatigue_penalty: float = lerpf(1.0, 0.35, clampf(stats.training_fatigue / TRAINING_MAX_FATIGUE, 0.0, 1.0))
		var xp_gain: float = xp_rate * minutes_delta * clampf(stats.active_training_intensity, TRAINING_MIN_INTENSITY, TRAINING_MAX_INTENSITY) * fatigue_penalty
		_apply_training_gain(stat_key, xp_gain)
		stats.last_training_epoch_ms = Time.get_ticks_msec()
	stats.training_rest_seconds = 0.0
	_apply_training_resource_costs(stat_key, minutes_delta)
	_apply_training_fatigue(minutes_delta, stats.active_training_intensity)
	Eventbus.training_progress_updated.emit(self, stat_key, _build_training_progress_payload(stat_key))
	if stats.active_training_seconds_remaining <= 0.01:
		_complete_training_session(stat_key)

func _apply_training_resource_costs(stat_key: StringName, minutes_delta: float) -> void:
	var hunger_rate: float = TRAINING_HUNGER_COST_PER_MINUTE.get(stat_key, 0.0)
	if hunger_rate > 0.0:
		_pending_training_hunger += hunger_rate * minutes_delta * clampf(stats.active_training_intensity, TRAINING_MIN_INTENSITY, TRAINING_MAX_INTENSITY)
		var hunger_steps: int = int(_pending_training_hunger)
		if hunger_steps > 0:
			stats.current_hunger = clampi(stats.current_hunger + hunger_steps, 0, stats.max_hunger)
			_pending_training_hunger -= hunger_steps
	var energy_rate: float = TRAINING_ENERGY_COST_PER_MINUTE.get(stat_key, 0.0)
	if energy_rate > 0.0:
		_pending_training_energy += energy_rate * minutes_delta * clampf(stats.active_training_intensity, TRAINING_MIN_INTENSITY, TRAINING_MAX_INTENSITY)
		var energy_steps: int = int(_pending_training_energy)
		if energy_steps > 0:
			stats.current_energy = clampi(stats.current_energy - energy_steps, 0, stats.max_energy)
			_pending_training_energy -= energy_steps

func _apply_training_fatigue(minutes_delta: float, intensity: float) -> void:
	var fatigue_gain: float = TRAINING_FATIGUE_PER_MINUTE * minutes_delta * clampf(intensity, TRAINING_MIN_INTENSITY, TRAINING_MAX_INTENSITY)
	if fatigue_gain <= 0.0:
		return
	stats.training_fatigue = clampf(stats.training_fatigue + fatigue_gain, 0.0, TRAINING_MAX_FATIGUE)

func _complete_training_session(stat_key: StringName) -> void:
	stats.active_training_stat = StringName()
	stats.active_training_seconds_remaining = 0.0
	stats.active_training_intensity = 0.0
	Eventbus.training_session_completed.emit(self, stat_key)

func _apply_training_decay_tick() -> void:
	if stats == null or current_life_stage == "egg":
		return
	if _is_training_active():
		return
	stats.training_rest_seconds = clampf(stats.training_rest_seconds + _tick_interval_seconds, 0.0, SECONDS_PER_HOUR * 24.0)
	_recover_training_fatigue()
	if stats.training_rest_seconds < TRAINING_DECAY_GRACE_HOURS * SECONDS_PER_HOUR:
		return
	for stat_key in TRAINING_STAT_KEYS:
		var current_value: int = _get_stat_value(stat_key)
		var baseline_value: int = _get_stat_baseline(stat_key)
		if current_value <= baseline_value:
			continue
		var per_hour: float = TRAINING_DECAY_PER_HOUR.get(stat_key, 0.0)
		if per_hour <= 0.0:
			continue
		var decay_points: float = per_hour * (_tick_interval_seconds / SECONDS_PER_HOUR)
		_apply_training_decay(stat_key, decay_points)

func _recover_training_fatigue() -> void:
	if stats.training_fatigue <= 0.0:
		return
	var recovery: float = TRAINING_FATIGUE_RECOVERY_PER_HOUR * (_tick_interval_seconds / SECONDS_PER_HOUR)
	if recovery <= 0.0:
		return
	stats.training_fatigue = clampf(stats.training_fatigue - recovery, 0.0, TRAINING_MAX_FATIGUE)

func _apply_training_gain(stat_key: StringName, xp_gain: float) -> void:
	if xp_gain <= 0.0 or stats == null:
		return
	var xp_per_point: float = TRAINING_XP_PER_POINT.get(stat_key, 0.0)
	if xp_per_point <= 0.0:
		return
	var point_gain: float = xp_gain / xp_per_point
	var progress: float = _get_training_progress(stat_key)
	progress += point_gain
	var whole_points: int = int(progress)
	_set_training_progress(stat_key, progress - whole_points)
	if whole_points > 0:
		_increase_stat(stat_key, whole_points)

func _apply_training_decay(stat_key: StringName, decay_points: float) -> void:
	if decay_points <= 0.0:
		return
	var progress: float = _get_decay_progress(stat_key)
	progress += decay_points
	var whole_points: int = int(progress)
	_set_decay_progress(stat_key, progress - whole_points)
	if whole_points > 0:
		_decrease_stat(stat_key, whole_points)

func _increase_stat(stat_key: StringName, amount: int) -> void:
	if amount <= 0:
		return
	match stat_key:
		&"strength":
			stats.strength = clampi(stats.strength + amount, stats.strength_baseline, stats.strength_cap)
		&"intelligence":
			stats.intelligence = clampi(stats.intelligence + amount, stats.intelligence_baseline, stats.intelligence_cap)
		&"happiness":
			stats.happiness = clampi(stats.happiness + amount, stats.happiness_baseline, stats.happiness_cap)

func _decrease_stat(stat_key: StringName, amount: int) -> void:
	if amount <= 0:
		return
	match stat_key:
		&"strength":
			stats.strength = clampi(stats.strength - amount, stats.strength_baseline, stats.strength_cap)
		&"intelligence":
			stats.intelligence = clampi(stats.intelligence - amount, stats.intelligence_baseline, stats.intelligence_cap)
		&"happiness":
			stats.happiness = clampi(stats.happiness - amount, stats.happiness_baseline, stats.happiness_cap)

func _is_training_active() -> bool:
	if stats == null:
		return false
	if stats.active_training_stat == StringName():
		return false
	return stats.active_training_seconds_remaining > 0.0

func _get_stat_value(stat_key: StringName) -> int:
	match stat_key:
		&"strength":
			return stats.strength
		&"intelligence":
			return stats.intelligence
		&"happiness":
			return stats.happiness
	return 0

func _get_stat_baseline(stat_key: StringName) -> int:
	match stat_key:
		&"strength":
			return stats.strength_baseline
		&"intelligence":
			return stats.intelligence_baseline
		&"happiness":
			return stats.happiness_baseline
	return 0

func _get_stat_cap(stat_key: StringName) -> int:
	match stat_key:
		&"strength":
			return stats.strength_cap
		&"intelligence":
			return stats.intelligence_cap
		&"happiness":
			return stats.happiness_cap
	return 0

func _get_training_progress(stat_key: StringName) -> float:
	match stat_key:
		&"strength":
			return stats.strength_training_progress
		&"intelligence":
			return stats.intelligence_training_progress
		&"happiness":
			return stats.happiness_training_progress
	return 0.0

func _set_training_progress(stat_key: StringName, value: float) -> void:
	match stat_key:
		&"strength":
			stats.strength_training_progress = value
		&"intelligence":
			stats.intelligence_training_progress = value
		&"happiness":
			stats.happiness_training_progress = value

func _get_decay_progress(stat_key: StringName) -> float:
	match stat_key:
		&"strength":
			return stats.strength_decay_progress
		&"intelligence":
			return stats.intelligence_decay_progress
		&"happiness":
			return stats.happiness_decay_progress
	return 0.0

func _set_decay_progress(stat_key: StringName, value: float) -> void:
	match stat_key:
		&"strength":
			stats.strength_decay_progress = value
		&"intelligence":
			stats.intelligence_decay_progress = value
		&"happiness":
			stats.happiness_decay_progress = value

func _build_training_progress_payload(stat_key: StringName) -> Dictionary:
	return {
		"stat": stat_key,
		"current": _get_stat_value(stat_key),
		"baseline": _get_stat_baseline(stat_key),
		"cap": _get_stat_cap(stat_key),
		"bonus": max(_get_stat_value(stat_key) - _get_stat_baseline(stat_key), 0),
		"seconds_remaining": stats.active_training_seconds_remaining,
		"fatigue": stats.training_fatigue,
		"fatigue_max": TRAINING_MAX_FATIGUE,
	}

func _evaluate_care_mistakes() -> bool:
	if stats == null or current_life_stage == "egg":
		return false
	var triggered: Array[StringName] = []
	var any_active: bool = false
	for mistake_id in CARE_MISTAKE_RULES.keys():
		var rule: Dictionary = CARE_MISTAKE_RULES[mistake_id]
		var ratio: float = _care_mistake_ratio_for(rule.get("stat", ""))
		if ratio < 0.0:
			continue
		var state: Dictionary = _care_mistake_state.get(mistake_id, {"ticks": 0, "active": false})
		var direction: String = String(rule.get("direction", "high"))
		var trigger_ratio: float = float(rule.get("trigger_ratio", 1.0))
		var recovery_ratio: float = float(rule.get("recovery_ratio", trigger_ratio))
		var ticks_required: int = max(int(rule.get("ticks_required", 3)), 1)
		var is_bad: bool = ratio <= trigger_ratio if direction == "low" else ratio >= trigger_ratio
		var recovered: bool = ratio >= recovery_ratio if direction == "low" else ratio <= recovery_ratio
		if state.get("active", false):
			if recovered:
				state["active"] = false
			else:
				any_active = true
		if !state.get("active", false):
			if is_bad:
				state["ticks"] = int(state.get("ticks", 0)) + 1
				if state["ticks"] >= ticks_required:
					state["active"] = true
					state["ticks"] = 0
					triggered.append(StringName(mistake_id))
					any_active = true
			else:
				state["ticks"] = 0
		_care_mistake_state[mistake_id] = state
		if state.get("active", false):
			any_active = true
	for mistake_id in triggered:
		_record_care_mistake(mistake_id)
	return any_active

func _care_mistake_ratio_for(stat_key: String) -> float:
	if stats == null:
		return -1.0
	match stat_key:
		"hunger":
			if stats.max_hunger <= 0:
				return -1.0
			return float(stats.current_hunger) / float(stats.max_hunger)
		"energy":
			if stats.max_energy <= 0:
				return -1.0
			return float(stats.current_energy) / float(stats.max_energy)
		"grooming":
			if stats.max_grooming_need <= 0:
				return -1.0
			return float(stats.current_grooming_need) / float(stats.max_grooming_need)
		"nest":
			if stats.max_nest_cleanliness <= 0:
				return -1.0
			return float(stats.nest_cleanliness) / float(stats.max_nest_cleanliness)
	return -1.0

func _record_care_mistake(mistake_id: StringName) -> void:
	if stats == null:
		return
	stats.care_mistakes = clampi(stats.care_mistakes + 1, 0, 999)
	_care_mistake_decay_ticks = 0
	Tracer.warn("%s recorded %s care mistake. Total=%d" % [name, mistake_id, stats.care_mistakes])
	Eventbus.care_mistake_recorded.emit(self, mistake_id, stats.care_mistakes)
	Eventbus.care_mistake_total_changed.emit(self, stats.care_mistakes)

func _update_care_mistake_decay(has_active_neglect: bool) -> void:
	if stats == null or stats.care_mistakes <= 0:
		_care_mistake_decay_ticks = 0
		return
	if has_active_neglect:
		_care_mistake_decay_ticks = 0
		return
	_care_mistake_decay_ticks += 1
	var decay_ticks_required: int = int(round(_ticks_per_hour() * CARE_MISTAKE_DECAY_HOURS))
	if decay_ticks_required <= 0:
		decay_ticks_required = 1
	if _care_mistake_decay_ticks >= decay_ticks_required:
		stats.care_mistakes = max(stats.care_mistakes - 1, 0)
		_care_mistake_decay_ticks = 0
		Eventbus.care_mistake_total_changed.emit(self, stats.care_mistakes)

func _sync_stat_blackboard() -> void:
	if bt and bt.blackboard:
		bt.blackboard.set_value(name + "_current_hunger", stats.current_hunger)
		bt.blackboard.set_value(name + "_current_energy", stats.current_energy)
		bt.blackboard.set_value(name + "_grooming_need", stats.current_grooming_need)
		bt.blackboard.set_value(name + "_nest_cleanliness", stats.nest_cleanliness)
		bt.blackboard.set_value(name + "_care_mistakes", stats.care_mistakes)
		bt.blackboard.set_value(name + "_strength", stats.strength)
		bt.blackboard.set_value(name + "_intelligence", stats.intelligence)
		bt.blackboard.set_value(name + "_happiness", stats.happiness)
	Eventbus.current_hunger_updated.emit()
	Eventbus.current_energy_updated.emit()

func _age_up():
	stats.age += 1
	if stats.age >= age_chart.keys().size() - 1:
		stats.age = age_chart.keys().size() - 1
	current_life_stage = age_chart.keys()[stats.age]
	seconds_to_age = age_chart[current_life_stage]
	_update_life_stage_visuals()
	Tracer.info("Happy Birthday %s!" % name)
	SoundManager.play_ui_sound(Data.sfx_library["happy_jingle"])
	Eventbus.player_currency_earned.emit("gold", 100)
	Tracer.debug("Requesting notification")
	Eventbus.notification_requested.emit("Happy Birthday %s!" % name)
	Tracer.debug("Requesting popup")
	Eventbus.popup_requested.emit("Happy Birthday %s!" % name)
	
func show_emotion(emotion: String, custom_linger: float = -1.0) -> void:
	if !emotion_bubbles.has(emotion):
		return
	_clear_active_emotion()
	current_emotion = emotion_bubbles[emotion].instantiate()
	emotion_container.add_child(current_emotion)
	current_emotion.play("default")
	_emotion_time_remaining = emotion_linger_seconds if custom_linger <= 0.0 else custom_linger

func _clear_active_emotion() -> void:
	for child in emotion_container.get_children():
		child.queue_free()
	current_emotion = null
	_emotion_time_remaining = 0.0

func set_behavior_state(action_id: StringName, options: Dictionary = {}) -> void:
	var action_key: String = String(action_id)
	var meta: Dictionary = ACTION_METADATA.get(action_key, {})
	current_action_id = action_id
	current_action_label = options.get("label", meta.get("label", action_key.capitalize()))
	var thought_override: String = options.get("thought", "")
	var thought_pool: Array = []
	if options.has("thoughts"):
		thought_pool = options["thoughts"]
	elif meta.has("thoughts"):
		thought_pool = meta["thoughts"]
	current_thought = thought_override if thought_override != "" else _pick_random_thought(thought_pool)
	var emotion_name: String = options.get("emotion", meta.get("emotion", ""))
	if emotion_name != "":
		show_emotion(emotion_name)
	_last_behavior_change = Time.get_ticks_msec() / 1000.0
	Eventbus.creature_activity_changed.emit(self)

func get_current_action_label() -> String:
	return current_action_label

func get_current_thought() -> String:
	return current_thought

func get_current_mood_label() -> String:
	if stats == null:
		return "??"
	var hunger_ratio: float = 0.0
	if stats.max_hunger > 0:
		hunger_ratio = float(stats.current_hunger) / float(stats.max_hunger)
	var energy_ratio: float = 1.0
	if stats.max_energy > 0:
		energy_ratio = float(stats.current_energy) / float(stats.max_energy)
	var grooming_ratio: float = 0.0
	if stats.max_grooming_need > 0:
		grooming_ratio = float(stats.current_grooming_need) / float(stats.max_grooming_need)
	var nest_ratio: float = 1.0
	if stats.max_nest_cleanliness > 0:
		nest_ratio = float(stats.nest_cleanliness) / float(stats.max_nest_cleanliness)
	if hunger_ratio >= 0.9:
		return "Starving"
	if energy_ratio <= 0.1:
		return "Collapsed"
	if energy_ratio <= 0.25:
		return "Exhausted"
	if grooming_ratio >= 0.8:
		return "Feeling grungy"
	if nest_ratio <= 0.2:
		return "Needs fresh digs"
	if hunger_ratio >= 0.7:
		return "Very hungry"
	if stats.happiness >= 85:
		return "Ecstatic"
	if stats.happiness >= 65:
		return "Content"
	if stats.happiness >= 45:
		return "Wistful"
	if stats.happiness >= 25:
		return "Moody"
	return "Miserable"

func _pick_random_thought(thoughts: Array) -> String:
	var pool: Array = thoughts.duplicate()
	if pool.is_empty():
		pool = DEFAULT_THOUGHTS.duplicate()
	if pool.is_empty():
		return ""
	var idx: int = _thought_rng.randi_range(0, pool.size() - 1)
	return str(pool[idx])

func get_save_data() -> Dictionary:
	var data: Dictionary = {
		"node_name": String(name),
		"creature_name": String(creature_name),
		"creature_nickname": String(creature_nickname),
		"date_born": int(date_born),
		"current_life_stage": current_life_stage,
		"seconds_to_age": seconds_to_age,
		"stats": _stats_to_dict(),
		"species_path": species.resource_path if species else "",
		"global_position": global_position,
		"is_sleeping": is_sleeping,
	}
	return data

func apply_save_data(payload: Dictionary) -> void:
	name = StringName(payload.get("node_name", String(name)))
	creature_name = StringName(payload.get("creature_name", String(creature_name)))
	creature_nickname = StringName(payload.get("creature_nickname", String(creature_nickname)))
	date_born = int(payload.get("date_born", Time.get_unix_time_from_system()))
	current_life_stage = payload.get("current_life_stage", current_life_stage)
	var stage_seconds: int = int(payload.get("seconds_to_age", age_chart.get(current_life_stage, seconds_to_age)))
	seconds_to_age = stage_seconds
	var species_path: String = payload.get("species_path", "")
	if species_path != "":
		var loaded_species: Species = ResourceLoader.load(species_path)
		if loaded_species:
			set_species(loaded_species)
	var stats_payload: Dictionary = payload.get("stats", {})
	if !stats_payload.is_empty():
		_apply_stats_from_dict(stats_payload)
	elif stats == null:
		stats = CreatureStats.new()
	is_sleeping = bool(payload.get("is_sleeping", is_sleeping))

func _stats_to_dict() -> Dictionary:
	if stats == null:
		return {}
	return {
		"strength": stats.strength,
		"intelligence": stats.intelligence,
		"happiness": stats.happiness,
		"strength_baseline": stats.strength_baseline,
		"intelligence_baseline": stats.intelligence_baseline,
		"happiness_baseline": stats.happiness_baseline,
		"strength_cap": stats.strength_cap,
		"intelligence_cap": stats.intelligence_cap,
		"happiness_cap": stats.happiness_cap,
		"strength_training_progress": stats.strength_training_progress,
		"intelligence_training_progress": stats.intelligence_training_progress,
		"happiness_training_progress": stats.happiness_training_progress,
		"strength_decay_progress": stats.strength_decay_progress,
		"intelligence_decay_progress": stats.intelligence_decay_progress,
		"happiness_decay_progress": stats.happiness_decay_progress,
		"training_rest_seconds": stats.training_rest_seconds,
		"training_fatigue": stats.training_fatigue,
		"last_training_epoch_ms": stats.last_training_epoch_ms,
		"active_training_stat": stats.active_training_stat,
		"active_training_seconds_remaining": stats.active_training_seconds_remaining,
		"active_training_intensity": stats.active_training_intensity,
		"last_training_station_id": stats.last_training_station_id,
		"current_health": stats.current_health,
		"max_health": stats.max_health,
		"current_hunger": stats.current_hunger,
		"max_hunger": stats.max_hunger,
		"current_energy": stats.current_energy,
		"max_energy": stats.max_energy,
		"current_grooming_need": stats.current_grooming_need,
		"max_grooming_need": stats.max_grooming_need,
		"nest_cleanliness": stats.nest_cleanliness,
		"max_nest_cleanliness": stats.max_nest_cleanliness,
		"care_mistakes": stats.care_mistakes,
		"seconds_alive": stats.seconds_alive,
		"age": stats.age,
		"is_dead": stats.is_dead,
	}

func _apply_stats_from_dict(data: Dictionary) -> void:
	if stats == null:
		stats = CreatureStats.new()
	stats.strength = int(data.get("strength", stats.strength))
	stats.intelligence = int(data.get("intelligence", stats.intelligence))
	stats.happiness = int(data.get("happiness", stats.happiness))
	var fallback_strength_baseline: int = stats.strength if stats.strength_baseline == 0 else stats.strength_baseline
	stats.strength_baseline = int(data.get("strength_baseline", fallback_strength_baseline))
	var fallback_intelligence_baseline: int = stats.intelligence if stats.intelligence_baseline == 0 else stats.intelligence_baseline
	stats.intelligence_baseline = int(data.get("intelligence_baseline", fallback_intelligence_baseline))
	var fallback_happiness_baseline: int = stats.happiness if stats.happiness_baseline == 0 else stats.happiness_baseline
	stats.happiness_baseline = int(data.get("happiness_baseline", fallback_happiness_baseline))
	stats.strength_cap = int(data.get("strength_cap", stats.strength_cap))
	stats.intelligence_cap = int(data.get("intelligence_cap", stats.intelligence_cap))
	stats.happiness_cap = int(data.get("happiness_cap", stats.happiness_cap))
	stats.strength_training_progress = float(data.get("strength_training_progress", stats.strength_training_progress))
	stats.intelligence_training_progress = float(data.get("intelligence_training_progress", stats.intelligence_training_progress))
	stats.happiness_training_progress = float(data.get("happiness_training_progress", stats.happiness_training_progress))
	stats.strength_decay_progress = float(data.get("strength_decay_progress", stats.strength_decay_progress))
	stats.intelligence_decay_progress = float(data.get("intelligence_decay_progress", stats.intelligence_decay_progress))
	stats.happiness_decay_progress = float(data.get("happiness_decay_progress", stats.happiness_decay_progress))
	stats.training_rest_seconds = float(data.get("training_rest_seconds", stats.training_rest_seconds))
	stats.training_fatigue = float(data.get("training_fatigue", stats.training_fatigue))
	stats.last_training_epoch_ms = int(data.get("last_training_epoch_ms", stats.last_training_epoch_ms))
	var active_training_stat_value: Variant = data.get("active_training_stat", stats.active_training_stat)
	if active_training_stat_value == null or active_training_stat_value == "":
		stats.active_training_stat = StringName()
	else:
		stats.active_training_stat = active_training_stat_value if active_training_stat_value is StringName else StringName(str(active_training_stat_value))
	stats.active_training_seconds_remaining = float(data.get("active_training_seconds_remaining", stats.active_training_seconds_remaining))
	stats.active_training_intensity = float(data.get("active_training_intensity", stats.active_training_intensity))
	var last_station_value: Variant = data.get("last_training_station_id", stats.last_training_station_id)
	if last_station_value == null or last_station_value == "":
		stats.last_training_station_id = StringName()
	else:
		stats.last_training_station_id = last_station_value if last_station_value is StringName else StringName(str(last_station_value))
	stats.current_health = int(data.get("current_health", stats.current_health))
	stats.max_health = int(data.get("max_health", stats.max_health))
	stats.current_hunger = int(data.get("current_hunger", stats.current_hunger))
	stats.max_hunger = int(data.get("max_hunger", stats.max_hunger))
	stats.current_energy = int(data.get("current_energy", stats.current_energy))
	stats.max_energy = int(data.get("max_energy", stats.max_energy))
	stats.current_grooming_need = int(data.get("current_grooming_need", stats.current_grooming_need))
	stats.max_grooming_need = int(data.get("max_grooming_need", stats.max_grooming_need))
	stats.nest_cleanliness = int(data.get("nest_cleanliness", stats.nest_cleanliness))
	stats.max_nest_cleanliness = int(data.get("max_nest_cleanliness", stats.max_nest_cleanliness))
	stats.care_mistakes = int(data.get("care_mistakes", stats.care_mistakes))
	stats.seconds_alive = int(data.get("seconds_alive", stats.seconds_alive))
	stats.age = int(data.get("age", stats.age))
	stats.is_dead = bool(data.get("is_dead", stats.is_dead))
	_clamp_training_values()

func get_icon_image() -> Texture2D:
	if current_life_stage == "egg":
		return egg_sprite.texture
	else:
		return creature_sprite.texture

func _apply_species_visuals() -> void:
	if !is_inside_tree():
		return
	if species != null:
		if creature_sprite == null and has_node("CreatureSprite"):
			creature_sprite = get_node("CreatureSprite")
		if egg_sprite == null and has_node("EggSprite"):
			egg_sprite = get_node("EggSprite")
		if creature_sprite:
			creature_sprite.texture = species.spritesheet
		if egg_sprite and species.egg_texture:
			egg_sprite.texture = species.egg_texture
	_update_life_stage_visuals()

func _update_life_stage_visuals() -> void:
	if egg_sprite == null or creature_sprite == null:
		return
	var show_egg: bool = current_life_stage == "egg"
	egg_sprite.visible = show_egg
	creature_sprite.visible = !show_egg

func _on_input_event(_viewport, _event, _shape_idx):
	pass # Replace with function body.


func _on_touch_screen_button_pressed():
	Tracer.info("Requesting focus view for %s " % name)
	Eventbus.focus_view_requested.emit(self)
	pass # Replace with function body.
