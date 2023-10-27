extends Node2D
class_name Player

var _owned_creatures : Array[Creature] = []
var _known_buildables : Array[Buildable] = []
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func adopt_creature(creature: Creature):
	_owned_creatures.append(creature)

func get_adopted_creatures() -> Array[Creature]:
	return _owned_creatures
	
func learn_buildable(buildable: Buildable):
	_known_buildables.append(buildable)

func get_known_buildables() -> Array[Buildable]:
	return _known_buildables
