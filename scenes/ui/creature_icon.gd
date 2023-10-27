extends Control

@onready var texture_rect : TextureRect = get_node("TextureRect")
@onready var name_label : Label = get_node("Label")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func initialize(creature: Creature):
	await ready
	texture_rect.texture = creature.sprite.sprite_frames.get_frame_texture("default",0)
	name_label.text = creature.creature_nickname
