extends Panel
class_name Notification

@onready var label : Label = $CenterContainer/Label
@export var duration: int = 10
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_notification(text: String):
	await ready
	label.text = text
	
func show_notification():
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(hide_notification)
	pass

func hide_notification():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 1)
	tween.tween_callback(func(): self.queue_free())
	pass
