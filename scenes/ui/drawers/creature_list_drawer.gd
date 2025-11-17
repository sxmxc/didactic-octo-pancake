extends MenuDrawer

@export var creature_icon_scene: PackedScene = preload("res://scenes/ui/creature_icon.tscn")
@onready var creature_list: GridContainer = %CreatureList

func _ready() -> void:
	super._ready()

func _on_drawer_opening() -> void:
	_populate()

func _populate() -> void:
	for child in creature_list.get_children():
		child.queue_free()
	for creature in get_tree().get_nodes_in_group("Creature"):
		if creature_icon_scene == null:
			continue
		var icon = creature_icon_scene.instantiate()
		icon.initialize(creature)
		icon.gui_input.connect(_on_icon_input.bind(creature))
		creature_list.add_child(icon)

func _on_icon_input(event: InputEvent, creature: Creature) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		SoundManager.play_ui_sound(Data.sfx_library["click"])
		Eventbus.focus_view_requested.emit(creature)
		close()
