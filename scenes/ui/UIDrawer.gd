extends Control
class_name UIDrawer

var starting_position := Vector2(0,0)

signal opening
signal closing

var opened := false
@onready var tween : Tween


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func open():
	opening.emit()
	print("Opening")
	visible = true
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(self, "position", Vector2(0,position.y - get_parent().size.y + 50), .1)
	opened = true
	pass

func close():
	closing.emit()
	print("Closing")
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(self, "position", starting_position, .1)
	tween.tween_callback(func(): visible = false)
	opened = false
	pass
