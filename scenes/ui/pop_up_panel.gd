extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_texture_button_pressed():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, .2)
	tween.tween_callback(queue_free)
	pass # Replace with function body.

func set_content(content : String):
	%ContentLabel.text = content
	
func pop_up():
	modulate = Color.TRANSPARENT
	show()
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, .2)


func _on_accept_button_pressed():
	_on_texture_button_pressed()
	pass # Replace with function body.
