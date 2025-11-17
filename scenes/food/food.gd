extends Sprite2D
class_name Food

var nutrition_value := 100


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func consume(creature:Creature):
	creature.stats.current_hunger = clampi(creature.stats.current_hunger - nutrition_value, 0, creature.stats.max_hunger)
	queue_free()
