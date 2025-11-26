extends MenuDrawer

@export var default_food_scene: PackedScene = preload("res://scenes/food/meat.tscn")
@onready var feed_button: Button = %FeedButton
@onready var food_selector: OptionButton = %FoodSelector
@onready var details_label: RichTextLabel = %FoodDetails

var _food_entries: Array = []
var _selected_food_id: StringName = StringName()

func _ready() -> void:
	super._ready()
	_populate_food_selector()
	if food_selector:
		food_selector.item_selected.connect(_on_selector_item_selected)
	feed_button.pressed.connect(_on_feed_pressed)
	opened.connect(_on_drawer_opened)

func _populate_food_selector() -> void:
	_food_entries.clear()
	if food_selector:
		food_selector.clear()
	var definitions: Dictionary = Data.food_definitions
	if definitions.is_empty():
		feed_button.disabled = true
		if details_label:
			details_label.text = "No food definitions registered inside autoload/data.gd."
		return
	for key in definitions.keys():
		var entry_id: StringName = _to_string_name(key)
		var definition: Dictionary = definitions[key]
		var disp_name: String = str(definition.get("display_name", key))
		_food_entries.append({
			"id": entry_id,
			"name": disp_name,
			"definition": definition,
		})
	_food_entries.sort_custom(Callable(self, "_sort_food_entries"))
	if food_selector:
		for entry in _food_entries:
			food_selector.add_item(entry.get("name", "Food"))
	if !_food_entries.is_empty():
		_selected_food_id = _food_entries[0].get("id", StringName())
		if food_selector:
			food_selector.select(0)
	feed_button.disabled = _food_entries.is_empty()
	_update_food_details()

func _sort_food_entries(a: Dictionary, b: Dictionary) -> bool:
	return str(a.get("name", "")).naturalnocasecmp_to(str(b.get("name", ""))) < 0

func _on_selector_item_selected(index: int) -> void:
	if index < 0 or index >= _food_entries.size():
		return
	var entry: Dictionary = _food_entries[index]
	_selected_food_id = entry.get("id", StringName())
	_update_food_details()

func _update_food_details() -> void:
	if details_label == null:
		return
	var entry := _get_selected_entry()
	if entry.is_empty():
		details_label.text = "Select a food to inspect its diet, hunger relief, and stat effects."
		feed_button.disabled = true
		return
	feed_button.disabled = false
	var definition: Dictionary = entry.get("definition", {})
	var display_name: String = str(entry.get("name", "Food"))
	var diet_type: StringName = _to_string_name(definition.get("diet_type", &"omnivore"))
	var hunger_relief: int = int(definition.get("hunger_relief", 0))
	var stat_text := _format_stat_effects(definition.get("stat_effects", {}))
	var lines: Array[String] = []
	lines.append("[b]%s[/b]" % display_name)
	var description := str(definition.get("description", ""))
	if description != "":
		lines.append(description)
	lines.append("[b]Diet type:[/b] %s" % Food.to_diet_label(diet_type))
	lines.append("[b]Compatible diets:[/b] %s" % _format_compatible_diets(diet_type))
	if hunger_relief > 0:
		lines.append("[b]Hunger relief:[/b] %d pts" % hunger_relief)
	if stat_text != "":
		lines.append("[b]Stat impact:[/b] %s" % stat_text)
	var match_count := _count_matching_creatures(diet_type)
	var status_color := "14e06e" if match_count > 0 else "ff6d6d"
	lines.append("[color=%s]%d creature(s) can eat this right now.[/color]" % [status_color, match_count])
	details_label.text = "\n".join(lines)

func _format_stat_effects(effects: Variant) -> String:
	if !(effects is Dictionary):
		return ""
	var parts: Array[String] = []
	for key in effects.keys():
		var amount: int = int(effects[key])
		if amount == 0:
			continue
		var label := String(key) if key is String or key is StringName else str(key)
		var prefix := "+" if amount > 0 else "-"
		parts.append("%s%d %s" % [prefix, abs(amount), label.capitalize()])
	return ", ".join(parts)

func _format_compatible_diets(food_type: StringName) -> String:
	var diets := Food.get_compatible_diets_for(food_type)
	if diets.is_empty():
		return "None"
	var names: Array[String] = []
	for diet in diets:
		names.append(Food.to_diet_label(diet))
	return ", ".join(names)

func _count_matching_creatures(food_type: StringName) -> int:
	var diets := Food.get_compatible_diets_for(food_type)
	if diets.is_empty():
		return 0
	var match_count := 0
	var player := _get_player()
	if player == null:
		return 0
	for creature in player.get_adopted_creatures():
		if creature == null or creature.species == null:
			continue
		if diets.has(creature.species.get_diet()):
			match_count += 1
	return match_count

func _on_feed_pressed() -> void:
	var entry := _get_selected_entry()
	if entry.is_empty():
		return
	var definition: Dictionary = entry.get("definition", {})
	var food := _instantiate_food(entry.get("id", StringName()), definition)
	if food == null:
		return
	SoundManager.play_ui_sound(Data.sfx_library["click"])
	Eventbus.feed_request.emit(food)

func _instantiate_food(food_id: StringName, definition: Dictionary) -> Food:
	var packed: PackedScene = definition.get("scene", default_food_scene)
	var scene: PackedScene = packed if packed is PackedScene else default_food_scene
	if scene == null:
		return null
	var food: Food = scene.instantiate()
	food.configure_from_definition(food_id, definition)
	return food

func _get_selected_entry() -> Dictionary:
	for entry in _food_entries:
		if entry.get("id", StringName()) == _selected_food_id:
			return entry
	if !_food_entries.is_empty():
		return _food_entries[0]
	return {}

func _get_player() -> Player:
	for node in get_tree().get_nodes_in_group("Player"):
		if node is Player:
			return node
	return null

func _on_drawer_opened() -> void:
	_update_food_details()

func _to_string_name(value: Variant) -> StringName:
	if value is StringName:
		return value
	if value is String and value != "":
		return StringName(value)
	return StringName()
