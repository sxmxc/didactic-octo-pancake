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

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
