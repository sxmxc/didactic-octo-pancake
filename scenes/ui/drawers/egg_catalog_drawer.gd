extends MenuDrawer

@onready var pack_list: VBoxContainer = %PackList
@onready var egg_list: VBoxContainer = %EggList
@onready var empty_label: Label = %EmptyEggsLabel
@onready var odds_body: RichTextLabel = %OddsBody

var _player: Player = null
var _inventory_snapshot: Dictionary = {}
var _tokens: Array = []
var _pack_counts: Dictionary = {}
var _cooldowns: Dictionary = {}

const PACK_ITEM_SCENE := preload("res://scenes/ui/drawers/catalog_item_panel.tscn")

func _ready() -> void:
	super._ready()
	_player = _find_player()
	Eventbus.player_egg_inventory_updated.connect(_on_inventory_updated)
	_on_inventory_updated({})

func _find_player() -> Player:
	var node := get_tree().get_first_node_in_group("player")
	return node if node is Player else null

func _ensure_player() -> bool:
	if _player != null:
		return true
	_player = _find_player()
	return _player != null

func _on_inventory_updated(inventory: Dictionary) -> void:
	if inventory is Dictionary:
		_inventory_snapshot = inventory.duplicate(true)
		_tokens = _inventory_snapshot.get("egg_tokens", [])
		_pack_counts = _inventory_snapshot.get("pack_counts", {})
		_cooldowns = _inventory_snapshot.get("next_claim_ready_ms", {})
	else:
		_inventory_snapshot = {}
		_tokens = []
		_pack_counts = {}
		_cooldowns = {}
	if _is_open:
		_render_contents()

func _on_drawer_opening() -> void:
	_render_contents()

func _render_contents() -> void:
	_render_packs()
	_render_eggs()
	_render_odds()

func _render_packs() -> void:
	for child in pack_list.get_children():
		child.queue_free()
	var definitions: Dictionary = Data.egg_pack_definitions
	var pack_ids: Array = definitions.keys()
	pack_ids.sort()
	for pack_id in pack_ids:
		var pack_def: Dictionary = definitions[pack_id]
		var panel := PACK_ITEM_SCENE.instantiate() as CatalogItemPanel
		if panel == null:
			continue
		#panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.set_title(str(pack_def.get("display_name", pack_id.capitalize())))
		panel.set_count_text("x%s" % _get_pack_count(pack_id))
		panel.set_detail_text("Contains: %s" % _format_pack_contents(pack_def))
		panel.set_description(str(pack_def.get("description", "")))
		panel.clear_actions()
		var actions := panel.get_actions_row()
		var source := str(pack_def.get("source", "purchase"))
		if source == "daily":
			var claim_button := Button.new()
			claim_button.text = "Claim"
			claim_button.focus_mode = Control.FOCUS_NONE
			claim_button.disabled = !_is_pack_ready(pack_id)
			claim_button.pressed.connect(_on_pack_claim_pressed.bind(pack_id))
			actions.add_child(claim_button)
			panel.set_status_text(_format_claim_status(pack_id))
		else:
			panel.set_status_text("")
			var cost_button := Button.new()
			cost_button.text = _format_purchase_label(pack_def.get("cost", {}))
			cost_button.focus_mode = Control.FOCUS_NONE
			cost_button.disabled = _player == null
			cost_button.pressed.connect(_on_pack_purchase_pressed.bind(pack_id))
			actions.add_child(cost_button)
		var open_button := Button.new()
		open_button.text = "Open"
		open_button.focus_mode = Control.FOCUS_NONE
		open_button.disabled = _get_pack_count(pack_id) <= 0 or _player == null
		open_button.pressed.connect(_on_pack_open_pressed.bind(pack_id))
		actions.add_child(open_button)
		pack_list.add_child(panel)

func _render_eggs() -> void:
	for child in egg_list.get_children():
		child.queue_free()
	if _tokens.is_empty():
		empty_label.show()
		return
	empty_label.hide()
	for index in range(_tokens.size()):
		var entry: Dictionary = _tokens[index]
		var button := Button.new()
		button.text = _format_token_label(entry)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.tooltip_text = _format_token_tooltip(entry)
		button.pressed.connect(_on_egg_selected.bind(index))
		egg_list.add_child(button)

func _render_odds() -> void:
	var lines: Array[String] = []
	var tier_ids: Array = Data.egg_tier_definitions.keys()
	tier_ids.sort()
	for tier_id in tier_ids:
		var tier_key := StringName(tier_id)
		var tier_data: Dictionary = Data.egg_tier_definitions[tier_id]
		var weights := _collect_tier_weights(tier_key)
		if weights.is_empty():
			continue
		var display_name := str(tier_data.get("display_name", tier_id.capitalize()))
		lines.append("[b]%s[/b]" % display_name)
		var desc: String = tier_data.get("description", "")
		if desc != "":
			lines.append("[color=#9ea0a5]%s[/color]" % desc)
		var total_weight: int = 0
		for item in weights:
			total_weight += item.get("weight", 0)
		for item in weights:
			var species_name: String = str(item.get("name", item.get("key", "")))
			var weight: int = int(item.get("weight", 0))
			var percent := 0.0
			if total_weight > 0:
				percent = float(weight) / float(total_weight) * 100.0
			lines.append("• %s (%.1f%%)" % [species_name, percent])
		lines.append("")
	if lines.is_empty():
		odds_body.text = "No hatch odds configured."
	else:
		odds_body.text = "\n".join(lines).strip_edges()

func _format_purchase_label(cost: Dictionary) -> String:
	if cost.is_empty():
		return "Buy"
	var parts: Array[String] = []
	for currency in cost.keys():
		var amount := int(cost[currency])
		if amount <= 0:
			continue
		parts.append("%s %s" % [amount, currency.capitalize()])
	if parts.is_empty():
		return "Buy"
	return "Buy %s" % ", ".join(parts)

func _format_pack_contents(pack_def: Dictionary) -> String:
	var entries: Array[String] = []
	for roll in pack_def.get("egg_rolls", []):
		if roll is Dictionary:
			var tier_id: String = str(roll.get("tier_id", "meadow"))
			var count: int = int(roll.get("count", 1))
			var tier_data: Dictionary = Data.egg_tier_definitions.get(tier_id, {})
			var tier_name := str(tier_data.get("display_name", tier_id.capitalize()))
			entries.append("%dx %s" % [count, tier_name])
	return ", ".join(entries)

func _format_token_label(token: Dictionary) -> String:
	var tier_id: String = str(token.get("tier_id", "meadow"))
	var tier_data: Dictionary = Data.egg_tier_definitions.get(tier_id, {})
	var tier_name := str(tier_data.get("display_name", tier_id.capitalize()))
	var source_id: String = str(token.get("source_pack_id", ""))
	var source_name := _get_pack_display_name(source_id)
	if source_name == "":
		return "%s Egg" % tier_name
	return "%s Egg \n %s" % [tier_name, source_name]

func _format_token_tooltip(token: Dictionary) -> String:
	var awarded_ms: int = int(token.get("awarded_at_ms", 0))
	var source_id: String = str(token.get("source_pack_id", ""))
	var source_name := _get_pack_display_name(source_id)
	var awarded_text := ""
	if awarded_ms > 0:
		awarded_text = Time.get_datetime_string_from_unix_time(awarded_ms / 1000, true)
	var lines: Array[String] = []
	if source_name != "":
		lines.append("Source: %s" % source_name)
	if awarded_text != "":
		lines.append("Awarded: %s" % awarded_text)
	return "\n".join(lines)

func _format_claim_status(pack_id: String) -> String:
	var ready_ms: int = int(_cooldowns.get(pack_id, 0))
	var now_ms := int(Time.get_unix_time_from_system() * 1000.0)
	if ready_ms <= now_ms:
		return "Ready now"
	var remaining: int = max(ready_ms - now_ms, 0)
	var seconds: int = int(remaining / 1000)
	var hours: int = int(seconds / 3600)
	var minutes: int = int((seconds % 3600) / 60)
	return "Ready in %02dh %02dm" % [hours, minutes]

func _collect_tier_weights(tier_id: StringName) -> Array:
	var weights: Array = []
	for key in Data.species_baby_library.keys():
		var species: BabySpecies = Data.species_baby_library[key]
		var species_tier: StringName = species.egg_tier if species.egg_tier != StringName() else &"meadow"
		if species_tier == tier_id:
			weights.append({
				"key": key,
				"name": species.species_name,
				"weight": max(species.hatch_weight, 1),
			})
	return weights

func _on_pack_claim_pressed(pack_id: String) -> void:
	if !_ensure_player():
		Eventbus.notification_requested.emit("Player not ready.")
		return
	var pack_def: Dictionary = Data.egg_pack_definitions.get(pack_id, {})
	var cooldown_hours: float = float(pack_def.get("cooldown_hours", 0.0))
	var result := _player.try_claim_pack(pack_id, cooldown_hours)
	if result.get("ok", false):
		Eventbus.notification_requested.emit("Claimed %s" % _get_pack_display_name(pack_id))
	else:
		Eventbus.notification_requested.emit(result.get("message", "Pack not ready."))

func _on_pack_purchase_pressed(pack_id: String) -> void:
	if !_ensure_player():
		Eventbus.notification_requested.emit("Player not ready.")
		return
	var pack_def: Dictionary = Data.egg_pack_definitions.get(pack_id, {})
	var result := _player.purchase_pack(pack_id, pack_def.get("cost", {}))
	if result.get("ok", false):
		Eventbus.notification_requested.emit("Purchased %s" % _get_pack_display_name(pack_id))
	else:
		Eventbus.notification_requested.emit(result.get("message", "Cannot purchase."))

func _on_pack_open_pressed(pack_id: String) -> void:
	if !_ensure_player():
		Eventbus.notification_requested.emit("Player not ready.")
		return
	var pack_def: Dictionary = Data.egg_pack_definitions.get(pack_id, {})
	var result := _player.open_pack(pack_id)
	if result.get("ok", false):
		var minted: int = int(result.get("minted", 0))
		Eventbus.notification_requested.emit("Opened %s (+%s eggs)" % [_get_pack_display_name(pack_id), minted])
	else:
		Eventbus.notification_requested.emit(result.get("message", "No packs available."))

func _get_pack_count(pack_id: String) -> int:
	return int(_pack_counts.get(pack_id, 0))

func _get_pack_display_name(pack_id: String) -> String:
	if pack_id == "" or !Data.egg_pack_definitions.has(pack_id):
		return ""
	return str(Data.egg_pack_definitions[pack_id].get("display_name", pack_id.capitalize()))

func _is_pack_ready(pack_id: String) -> bool:
	if _ensure_player():
		return _player.can_claim_pack(pack_id)
	var ready_ms: int = int(_cooldowns.get(pack_id, 0))
	return int(Time.get_unix_time_from_system() * 1000.0) >= ready_ms

func _on_egg_selected(index: int) -> void:
	Eventbus.egg_hatch_requested.emit(index)
	close()
