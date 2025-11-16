extends UIDrawer

@onready var creature_list := %CreatureList
@export var creature_icon : PackedScene = preload("res://scenes/ui/creature_icon.tscn")
@onready var creature_container = %CreatureContainer

@onready var item_list := %ItemList
@export var build_item_icon_scene : PackedScene = preload("res://scenes/ui/build_item_icon.tscn")
@onready var build_container = %BuildContainer
# Called when the node enters the scene tree for the first time.
func _ready():
	creature_container.hide()
	build_container.hide()
	super._ready()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func focus_view_request(event, creature: Creature):
	if event is InputEventScreenTouch:
		print("Creature input event: %s" % event)
		Tracer.info("Requesting focus on %s" % creature.name)
		SoundManager.play_ui_sound(Data.sfx_library["click"])
		Eventbus.focus_view_requested.emit(creature)
		close()
		await closed_done
		creature_container.hide()
		get_viewport().set_input_as_handled()
		

func _on_creature_button_pressed():
	SoundManager.play_ui_sound(Data.sfx_library["click"])
	if transitioning:
		return
	if !opened:
		for child in creature_list.get_children():
			child.queue_free()
		for creature : Creature in get_tree().get_nodes_in_group("Creature"):
			var icon = creature_icon.instantiate()
			icon.initialize(creature)
			icon.gui_input.connect(Callable(focus_view_request).bind(creature))
			creature_list.add_child(icon)
		creature_container.show()
		open()
	else:
		Eventbus.world_view_requested.emit()
		close()
		await closed_done
		creature_container.hide()
		
	pass # Replace with function body.

func _on_build_button_pressed():
	SoundManager.play_ui_sound(Data.sfx_library["click"])
	if transitioning:
		return
	if !opened:
		Eventbus.build_view_requested.emit()
		if !get_tree().get_first_node_in_group("Player"):
			return
		for child in item_list.get_children():
			child.queue_free()
		if get_tree().get_first_node_in_group("Player"):
			for buildable : Buildable in get_tree().get_first_node_in_group("Player").get_known_buildables():
				var item = build_item_icon_scene.instantiate()
				item.set_item(buildable)
				item_list.add_child(item)
		build_container.show()
		open()
	else:
		close()
		await closed_done
		build_container.hide()
		Eventbus.world_view_requested.emit()
	pass # Replace with function body.
