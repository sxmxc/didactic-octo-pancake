extends Node2D

@export var buildable_library : Dictionary = {
	"BasicNest" : preload("res://buildables/nests/nest.tscn"),
	"BasicFoodBowl" : preload("res://buildables/food_containers/food_container.tscn")
}

@export var creature_library : Dictionary = {
	"Creature0" : preload("res://scenes/creature/creature.tscn")
}

@export var species_baby_library : Dictionary = {
	"blop": preload("res://resources/creature/data/babies/blop.tres"),
	"ghos": preload("res://resources/creature/data/babies/ghos.tres"),
	"sprit": preload("res://resources/creature/data/babies/sprit.tres"),
	"squip": preload("res://resources/creature/data/babies/squip.tres")
}

@export var music_library : Dictionary = {
	"awesomeness": preload("uid://5q722kjnkccy"), 
	"harbor": preload("uid://bm6ddxpp2d085"), 
	"old_city": preload("uid://xrtkos44v4vs"),
	"cozy": preload("uid://bvdb2f3a8gqhn")
}

@export var sfx_library : Dictionary = {
	"click": preload("res://addons/kenney_ui_audio/click5.wav"),
	"happy_jingle": preload("res://addons/kenney music jingles/Pizzicato jingles/jingles_pizzi_10.ogg"),
	"error": preload("res://addons/kenney_ui_audio/click5.wav"),
}

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Data Libraries Ready")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
