extends UIDrawer

@onready var creature_list := get_node("MarginContainer/HBoxContainer")
@export var creature_icon : PackedScene = preload("res://scenes/ui/creature_icon.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	starting_position = position
	opening.connect(_on_open)
	closing.connect(_on_close)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _on_open():
	for child in creature_list.get_children():
		child.queue_free()
	for creature : Creature in get_tree().get_nodes_in_group("Creature"):
		var icon = creature_icon.instantiate()
		icon.initialize(creature)
		icon.gui_input.connect(Callable(focus_view_request).bind(creature))
		creature_list.add_child(icon)
	pass

func _on_close():
	pass

func focus_view_request(event, creature: Creature):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				Eventbus.focus_view_requested.emit(creature)
				close()

func _on_creature_button_pressed():
	if !opened:
		open()
	else:
		close()
	pass # Replace with function body.
