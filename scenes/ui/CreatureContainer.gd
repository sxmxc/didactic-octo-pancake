extends NinePatchRect

var starting_position := Vector2(0,0)

var opened := false
@onready var tween : Tween
@onready var creature_list := get_node("MarginContainer/HBoxContainer")
# Called when the node enters the scene tree for the first time.
func _ready():
	starting_position = position
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func open():
	print("Opening")
	for child in creature_list.get_children():
		child.queue_free()
	for creature : Creature in get_tree().get_nodes_in_group("Creature"):
		var item = TextureRect.new()
		item.custom_minimum_size = Vector2(64,64)
		item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		item.texture = creature.sprite.sprite_frames.get_frame_texture("default",0)
		item.gui_input.connect(Callable(focus_view_request).bind(creature))
		creature_list.add_child(item)
	visible = true
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(self, "position", Vector2(0,position.y - 150), .1)
	opened = true
	pass

func close():
	print("Closing")
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(self, "position", starting_position, .1)
	tween.tween_callback(func(): visible = false)
	opened = false
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
