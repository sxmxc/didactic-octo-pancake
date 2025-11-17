extends MenuDrawer

@export var build_icon_scene: PackedScene = preload("res://scenes/ui/build_item_icon.tscn")
@onready var item_list: HBoxContainer = %BuildItemList

func _ready() -> void:
	super._ready()

func _on_drawer_opening() -> void:
	_populate()

func _populate() -> void:
	for child in item_list.get_children():
		child.queue_free()
	var player: Player = get_tree().get_first_node_in_group("Player")
	if player == null:
		return
	for buildable in player.get_known_buildables():
		if build_icon_scene == null:
			continue
		var item = build_icon_scene.instantiate()
		item.set_item(buildable)
		item_list.add_child(item)
