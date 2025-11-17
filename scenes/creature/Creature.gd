class_name Creature 
extends CharacterBody2D

const SECONDS_PER_HOUR: float = 3600.0
const HUNGER_INTERACTIONS_PER_HOUR: float = 6.0
const ENERGY_DRAIN_CYCLES_PER_HOUR: float = 2.0
const SLEEP_RECOVERY_CYCLES_PER_HOUR: float = 4.0

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
@onready var current_emotion : EmotionBubble = emotion_container.get_child(0)
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

func _ready() -> void:
	if stats == null:
		stats = CreatureStats.new()
	else:
		stats = stats.duplicate(true) as CreatureStats
	navigation_agent.velocity_computed.connect(Callable(_on_navigation_agent_2d_velocity_computed))
	_apply_species_visuals()

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

func _sync_stat_blackboard() -> void:
	if bt and bt.blackboard:
		bt.blackboard.set_value(name + "_current_hunger", stats.current_hunger)
		bt.blackboard.set_value(name + "_current_energy", stats.current_energy)
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
	
func show_emotion(emotion: String):
	if emotion_bubbles.has(emotion):
		current_emotion = emotion_bubbles[emotion].instantiate()
		for child in emotion_container.get_children():
			child.queue_free()
		emotion_container.add_child(current_emotion)
		current_emotion.play("default")

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
		"current_health": stats.current_health,
		"max_health": stats.max_health,
		"current_hunger": stats.current_hunger,
		"max_hunger": stats.max_hunger,
		"current_energy": stats.current_energy,
		"max_energy": stats.max_energy,
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
	stats.current_health = int(data.get("current_health", stats.current_health))
	stats.max_health = int(data.get("max_health", stats.max_health))
	stats.current_hunger = int(data.get("current_hunger", stats.current_hunger))
	stats.max_hunger = int(data.get("max_hunger", stats.max_hunger))
	stats.current_energy = int(data.get("current_energy", stats.current_energy))
	stats.max_energy = int(data.get("max_energy", stats.max_energy))
	stats.care_mistakes = int(data.get("care_mistakes", stats.care_mistakes))
	stats.seconds_alive = int(data.get("seconds_alive", stats.seconds_alive))
	stats.age = int(data.get("age", stats.age))
	stats.is_dead = bool(data.get("is_dead", stats.is_dead))

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
