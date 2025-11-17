extends VBoxContainer

@export var notification_scene : PackedScene = preload("res://scenes/ui/notification.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	Eventbus.notification_requested.connect(_on_notification_requested)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_notification_requested(new_notif : String):
	var notif : Notification = notification_scene.instantiate()
	notif.set_notification(new_notif)
	add_child(notif)
	notif.show_notification()
	pass
