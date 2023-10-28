extends Control

@onready var texture_rect : TextureRect = get_node("TextureRect")
@onready var name_label : Label = get_node("TextureRect/Label")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func initialize(creature: Creature):
	await ready
	texture_rect.texture = creature.get_icon_image()
	name_label.text = creature.creature_nickname
