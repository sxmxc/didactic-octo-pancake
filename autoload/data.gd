extends Node2D

@export var buildable_library : Dictionary = {
	"BasicNest" : preload("res://buildables/nests/nest.tscn"),
	"BasicFoodBowl" : preload("res://buildables/food_containers/food_container.tscn")
}

@export var creature_library : Dictionary = {
	"Creature0" : preload("res://scenes/creature/creature.tscn")
}

@export var species_baby_library : Dictionary = {
	"devbaby" : preload("res://resources/creature/data/babies/devbaby.tres"),
	"devbabybeta": preload("res://resources/creature/data/babies/devbabybeta.tres"),
	"ghostbaby": preload("res://resources/creature/data/babies/ghostbaby.tres"),
	'lilsquid': preload("res://resources/creature/data/babies/lilsquid.tres")
}

@export var music_library : Dictionary = {
	"awesomeness": preload("res://assets/audio/music/awesomeness.wav"), 
	"harbor": preload("res://assets/audio/music/harbor.mp3"), 
	"old_city": preload("res://assets/audio/music/old city theme.ogg")
}

@export var sfx_library : Dictionary = {
	"click": preload("res://addons/kenney_ui_audio/click5.wav"),
	"happy_jingle": preload("res://addons/kenney music jingles/Pizzicato jingles/jingles_pizzi_10.ogg")
}

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Data Libraries Ready")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
