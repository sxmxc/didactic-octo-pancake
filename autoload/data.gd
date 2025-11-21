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

@export var egg_tier_definitions : Dictionary = {
	"meadow": {
		"display_name": "Meadow Tier",
		"description": "Cozy garden dwellers with even odds between Blop and Sprit.",
	},
	"tidepool": {
		"display_name": "Tidepool Tier",
		"description": "Slimier swimmers with higher Squip weightings.",
	},
	"phantom": {
		"display_name": "Phantom Tier",
		"description": "Rare spirit sightings with a chance to pull a Ghos.",
	},
}

@export var egg_pack_definitions : Dictionary = {
	"daily_single": {
		"display_name": "Daily Meadow Drop",
		"description": "Claim a single Meadow-tier egg every 20 in-game hours.",
		"egg_rolls": [
			{"tier_id": "meadow", "count": 1},
		],
		"cooldown_hours": 20.0,
		"source": "daily",
		"cost": {"gold": 0},
	},
	"brood_bundle": {
		"display_name": "Brood Bundle",
		"description": "Three eggs with a bonus Tidepool roll for Squip hunters.",
		"egg_rolls": [
			{"tier_id": "meadow", "count": 2},
			{"tier_id": "tidepool", "count": 1},
		],
		"source": "purchase",
		"cost": {"gold": 250},
	},
	"nursery_crate": {
		"display_name": "Nursery Crate",
		"description": "Five-pack containing guaranteed Meadow, Tidepool, and Phantom rolls.",
		"egg_rolls": [
			{"tier_id": "meadow", "count": 3},
			{"tier_id": "tidepool", "count": 1},
			{"tier_id": "phantom", "count": 1},
		],
		"source": "purchase",
		"cost": {"gold": 550},
	},
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
func _process(_delta):
	pass
