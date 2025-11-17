extends MenuDrawer

@onready var egg_list: VBoxContainer = %EggList
@onready var empty_label: Label = %EmptyEggsLabel

var _inventory: Array = []

func _ready() -> void:
	super._ready()
	Eventbus.player_egg_inventory_updated.connect(_on_inventory_updated)
	_on_inventory_updated([])

func _on_inventory_updated(inventory: Array) -> void:
	_inventory.clear()
	for entry in inventory:
		if entry is Dictionary:
			_inventory.append(entry.duplicate(true))
	if _is_open:
		_render()

func _on_drawer_opening() -> void:
	_render()

func _render() -> void:
	for child in egg_list.get_children():
		child.queue_free()
	if _inventory.is_empty():
		empty_label.show()
		return
	empty_label.hide()
	for index in range(_inventory.size()):
		var entry: Dictionary = _inventory[index]
		var button := Button.new()
		button.text = entry.get("species_name", entry.get("species_key", "Egg"))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_egg_selected.bind(index))
		egg_list.add_child(button)

func _on_egg_selected(index: int) -> void:
	Eventbus.egg_hatch_requested.emit(index)
	close()
