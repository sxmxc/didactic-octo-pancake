extends Node2D

var _owned_creatures : Array[Creature] = []
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
