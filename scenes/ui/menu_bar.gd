extends Control
class_name HUDMenuBar

enum Profile { WORLD, FOCUS }

@export var profile: Profile = Profile.WORLD

@onready var button_row: HBoxContainer = %ButtonRow
@onready var drawer_layer: Control = %DrawerLayer
@onready var gold_label: Label = %GoldValue
@onready var save_button: TextureButton = %SaveButton
@onready var creature_button: TextureButton = %CreatureButton
@onready var egg_button: TextureButton = %EggButton
@onready var build_button: TextureButton = %BuildButton
@onready var food_button: TextureButton = %FoodButton
@onready var zoom_button: TextureButton = %ZoomButton
@onready var details_button: TextureButton = %DetailsButton

var _toggle_group := ButtonGroup.new()
var _drawer_cache: Dictionary = {}
var _current_toggle: TextureButton = null
var _focus_creature: Creature = null
var _button_icon_offsets := {}

const DRAWER_PATHS := {
	"creatures": "res://scenes/ui/drawers/creature_list_drawer.tscn",
	"eggs": "res://scenes/ui/drawers/egg_catalog_drawer.tscn",
	"build": "res://scenes/ui/drawers/build_shop_drawer.tscn",
	"food": "res://scenes/ui/drawers/food_bag_drawer.tscn",
	"details": "res://scenes/ui/drawers/creature_details_drawer.tscn"
}

signal save_requested
signal zoom_requested

func _ready() -> void:
	_toggle_group.allow_unpress = true
	Eventbus.player_wallet_updated.connect(_on_wallet_updated)
	Eventbus.buildable_drag_started.connect(_on_buildable_drag_started)
	_setup_buttons()
	apply_profile(profile)

func apply_profile(new_profile: Profile) -> void:
	profile = new_profile
	_current_toggle = null
	for button in [creature_button, egg_button, build_button, food_button, details_button]:
		button.button_pressed = false
		button.visible = false
	save_button.visible = profile == Profile.WORLD
	zoom_button.visible = profile == Profile.FOCUS
	match profile:
		Profile.WORLD:
			_bind_toggle(creature_button, "creatures")
			_bind_toggle(egg_button, "eggs")
			_bind_toggle(build_button, "build")
			_bind_toggle(food_button, "food")
		Profile.FOCUS:
			_bind_toggle(details_button, "details")
			zoom_button.button_pressed = false
	if profile == Profile.WORLD:
		save_button.show()
	else:
		save_button.hide()
	_close_all_drawers()

func set_focus_creature(creature: Creature) -> void:
	_focus_creature = creature
	var details: Node = _drawer_cache.get("details", null)
	if details and details.has_method("set_focus"):
		details.set_focus(creature)

func _setup_buttons() -> void:
	for button in [creature_button, egg_button, build_button, food_button, details_button]:
		button.visible = false
		button.toggle_mode = true
		button.button_group = _toggle_group
		_store_icon_offset(button)
	_setup_momentary_button(save_button, func():
		save_requested.emit()
	)
	_setup_momentary_button(zoom_button, func():
		zoom_requested.emit()
	)

func _bind_toggle(button: TextureButton, drawer_id: String) -> void:
	button.visible = true
	if button.is_connected("toggled", Callable(self, "_on_toggle_button_toggled")):
		button.disconnect("toggled", Callable(self, "_on_toggle_button_toggled"))
	_store_icon_offset(button)
	button.toggled.connect(_on_toggle_button_toggled.bind(button, drawer_id))

func _on_toggle_button_toggled(button_pressed: bool, button: TextureButton, drawer_id: String) -> void:
	_animate_icon(button, button_pressed)
	if button_pressed:
		if _current_toggle and _current_toggle != button:
			_current_toggle.button_pressed = false
			_animate_icon(_current_toggle, false)
		_current_toggle = button
		_open_drawer(drawer_id)
	else:
		if _current_toggle == button:
			_current_toggle = null
		_close_drawer(drawer_id)

func _open_drawer(drawer_id: String) -> void:
	var drawer: MenuDrawer = _get_or_create_drawer(drawer_id)
	if drawer == null:
		return
	for id in _drawer_cache.keys():
		if id != drawer_id:
			var other: MenuDrawer = _drawer_cache[id]
			if other:
				other.close()
	drawer.open()
	if drawer_id == "details" and drawer.has_method("set_focus"):
		drawer.set_focus(_focus_creature)

func _close_drawer(drawer_id: String) -> void:
	var drawer: MenuDrawer = _drawer_cache.get(drawer_id, null)
	if drawer:
		drawer.close()

func _close_all_drawers() -> void:
	for drawer in _drawer_cache.values():
		if drawer:
			drawer.close()
	_animate_icon(creature_button, false)
	_animate_icon(egg_button, false)
	_animate_icon(build_button, false)
	_animate_icon(food_button, false)
	_animate_icon(details_button, false)
	if _current_toggle:
		_current_toggle.button_pressed = false
		_current_toggle = null

func _get_or_create_drawer(drawer_id: String) -> MenuDrawer:
	if _drawer_cache.has(drawer_id):
		return _drawer_cache[drawer_id]
	if !DRAWER_PATHS.has(drawer_id):
		return null
	var scene: PackedScene = load(DRAWER_PATHS[drawer_id])
	if scene == null:
		return null
	var drawer: MenuDrawer = scene.instantiate()
	drawer_layer.add_child(drawer)
	_drawer_cache[drawer_id] = drawer
	return drawer

func _on_wallet_updated(wallet: Dictionary) -> void:
	var gold = wallet.get("gold", 0)
	gold_label.text = "$%s" % gold

func _store_icon_offset(button: TextureButton) -> void:
	if button in _button_icon_offsets:
		return
	var icon := button.get_node_or_null("Icon") as Control
	if icon:
		_button_icon_offsets[button] = icon.position

func _setup_momentary_button(button: TextureButton, callback: Callable) -> void:
	if button == null:
		return
	_store_icon_offset(button)
	if button.is_connected("pressed", callback):
		button.disconnect("pressed", callback)
	button.pressed.connect(callback)
	var down_callable := Callable(self, "_on_momentary_button_down").bind(button)
	var up_callable := Callable(self, "_on_momentary_button_up").bind(button)
	if button.is_connected("button_down", down_callable):
		button.disconnect("button_down", down_callable)
	button.button_down.connect(down_callable)
	if button.is_connected("button_up", up_callable):
		button.disconnect("button_up", up_callable)
	button.button_up.connect(up_callable)

func _on_momentary_button_down(button: TextureButton) -> void:
	_animate_icon(button, true)

func _on_momentary_button_up(button: TextureButton) -> void:
	_animate_icon(button, false)

func _on_buildable_drag_started() -> void:
	call_deferred("_deferred_close_build_drawer")

func _deferred_close_build_drawer() -> void:
	if build_button.button_pressed:
		build_button.button_pressed = false
		return
	_close_drawer("build")

func _animate_icon(button: TextureButton, pressed: bool) -> void:
	var icon := button.get_node_or_null("Icon") as Control
	if icon == null:
		return
	var base_offset: Vector2 = _button_icon_offsets.get(button, icon.position)
	var target := base_offset + Vector2(0, 2) if pressed else base_offset
	var tween := create_tween()
	tween.tween_property(icon, "position", target, 0.1).set_trans(Tween.TRANS_SINE)
