extends UIDrawer

@onready var item_list := get_node("All/MarginContainer/HBoxContainer")
@export var build_item_icon_scene : PackedScene = preload("res://scenes/ui/build_item_icon.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	opening.connect(_on_open)
	closing.connect(_on_close)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_build_button_pressed():
	SoundManager.play_ui_sound(Data.sfx_library["click"])
	if !opened:
		open()
	else:
		close()
	pass # Replace with function body.

func _on_open():
	Eventbus.build_view_requested.emit()
	if !owner.get_parent().get_node("%Player"):
		return
	for child in item_list.get_children():
		child.queue_free()
	for buildable : Buildable in owner.get_parent().get_node("%Player").get_known_buildables():
		var item = build_item_icon_scene.instantiate()
		item.set_item(buildable)
		item_list.add_child(item)
	pass

func _on_close():
	Eventbus.world_view_requested.emit()
	pass
