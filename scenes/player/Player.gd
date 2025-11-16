extends Node2D
class_name Player

var _owned_creatures : Array[Creature] = []
var _known_buildables : Array[Buildable] = []

var _wallet : Dictionary = {
	"gold" : 0,
	"gem": 0,
	"platinum": 0
}
# Called when the node enters the scene tree for the first time.
func _ready():
	Eventbus.player_currency_earned.connect(add_to_wallet)
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

func add_to_wallet(type: String, amount: int):
	if _wallet.has(type):
		_wallet[type] += amount
		Eventbus.player_wallet_updated.emit(_wallet)
