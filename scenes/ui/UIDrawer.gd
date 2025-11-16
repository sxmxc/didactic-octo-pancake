extends Control
class_name UIDrawer

var starting_position := Vector2(0,0)
var starting_size := Vector2(0,0)

signal opening
signal closing
signal opened_done
signal closed_done

var opened := false
var transitioning := false
@onready var tween : Tween


# Called when the node enters the scene tree for the first time.
func _ready():
	starting_size = size
	starting_position = position
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func open():
	transitioning = true
	opening.emit()
	print("Opening")
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "custom_minimum_size", Vector2(starting_size.x, starting_size.y + 300), .5)
	tween.tween_callback(func():
		opened_done.emit()
		transitioning = false
		opened = true
		)
	pass

func close():
	transitioning = true
	closing.emit()
	print("Closing")
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "custom_minimum_size", starting_size, .5)
	tween.tween_callback(func(): 
		closed_done.emit()
		transitioning = false
		opened = false
		)
	pass
