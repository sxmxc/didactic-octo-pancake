class_name Creature extends CharacterBody2D

@export var movement_speed: float = 20
@export var movement_range: int = 500

@export var age_chart : Dictionary = {
	"egg" : 30,
	"baby" : 43200,
	"child" : 86400,
	"teen" : 129600,
	"adult" : 172800
}
var current_life_stage = "egg"
@export var seconds_to_age : int = age_chart[current_life_stage]
@export var stats: Dictionary = {
	"strength": 0,
	"intelligence": 0,
	"happiness": 0,
	"hunger": 100,
	"energy": 200,
	"care_mistakes": 0,
	"seconds_alive": 0,
	"age": 0
}
@export var emotion_bubbles: Dictionary = {
	"happy" : preload("res://scenes/creature/emotions/singing_bubble.tscn"), 
	"love" : preload("res://scenes/creature/emotions/love_bubble.tscn"),
	"angry": preload("res://scenes/creature/emotions/angry_bubble.tscn"), 
	"sleepy": preload("res://scenes/creature/emotions/sleeping_bubble.tscn"),
	"idle": preload("res://scenes/creature/emotions/idle_bubble.tscn"),
	"hungry": preload("res://scenes/creature/emotions/hungry_bubble.tscn")
}
@onready var navigation_agent: NavigationAgent2D = get_node("NavigationAgent2D")
@onready var bt: BeehaveTree = get_node("BeehaveTree")
@onready var sprite : AnimatedSprite2D = get_node("AdultSprite2D")
@onready var emotion_container = get_node("EmotionContainer")
@onready var current_emotion : EmotionBubble = emotion_container.get_child(0)
@onready var camera : Camera2D = get_node("Camera2D")

var world_map: TileMap
var creature_nickname: StringName
var creature_name: StringName
var date_born
var is_sleeping = false

func _ready() -> void:
	navigation_agent.velocity_computed.connect(Callable(_on_navigation_agent_2d_velocity_computed))

func register_worldmap(map: TileMap):
	world_map = map

func register_blackboard(bb: Blackboard):
	bt.blackboard = bb

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
		sprite.flip_h = true
	else:
		sprite.flip_h = false
		

func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()
	pass # Replace with function body.

func _on_world_tick():
	var current_time = Time.get_unix_time_from_system()
	stats.seconds_alive = int(round(current_time - date_born))
	if stats.seconds_alive >= seconds_to_age:
		_age_up()
	stats.hunger -= 1
	bt.blackboard.set_value(name + "_hunger", stats.hunger)
	Eventbus.hunger_updated.emit()
	if current_life_stage == "egg":
		return
	if !is_sleeping:
		stats.energy -= 1
		bt.blackboard.set_value(name + "_energy", stats.energy)
		Eventbus.energy_updated.emit()
	else:
		stats.energy += 10
		bt.blackboard.set_value(name + "_energy", stats.energy)
		Eventbus.energy_updated.emit()

func _age_up():
	stats.age += 1
	current_life_stage = age_chart.keys()[stats.age]
	seconds_to_age = age_chart[current_life_stage]
	match  current_life_stage:
		"egg":
			get_node("EggSprite2D").visible = true
			get_node("AdultSprite2D").visible = false
		"baby":
			get_node("EggSprite2D").visible = false
			get_node("AdultSprite2D").visible = true
		"teen":
			pass
		"adult":
			pass
	print("Happy Birthday %s!" % name)
	
func show_emotion(emotion: String):
	if emotion_bubbles.has(emotion):
		current_emotion = emotion_bubbles[emotion].instantiate()
		for child in emotion_container.get_children():
			child.queue_free()
		emotion_container.add_child(current_emotion)
		current_emotion.play("default")

func get_save_data() -> Dictionary:
	var data = {
		"creature_name": creature_name,
		"creature_nickname": creature_nickname,
		"date_born" : date_born,
		"stats": stats,
		"current_life_stage": current_life_stage
	}
	return data


func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				Eventbus.focus_view_requested.emit(self)
	pass # Replace with function body.
