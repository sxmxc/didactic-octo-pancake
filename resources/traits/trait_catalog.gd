extends RefCounted
class_name TraitCatalog

const TraitState = preload("res://resources/traits/trait_state.gd")

const TRAIT_DEFINITIONS: Dictionary = {
	&"metabolic_marvel": {
		"display_name": "Metabolic Marvel",
		"alignment": &"positive",
		"roll_weight": 35,
		"tiers": [
			{
				"label": "Mindful Appetite",
				"description": "Hunger creeps ~10% slower thanks to careful pacing.",
				"modifiers": {"hunger_rate": 0.9},
				"evolves_to": 1,
			},
			{
				"label": "Metabolic Marvel",
				"description": "Metabolism sips calories, slowing hunger growth by ~25%.",
				"modifiers": {"hunger_rate": 0.75},
			},
		],
	},
	&"bottomless_pit": {
		"display_name": "Bottomless Pit",
		"alignment": &"negative",
		"roll_weight": 30,
		"tiers": [
			{
				"label": "Snack Cyclone",
				"description": "Hunger builds ~15% faster and training gains sag slightly.",
				"modifiers": {"hunger_rate": 1.15, "training_gain": 0.95},
				"evolves_to": 1,
			},
			{
				"label": "Ravenous",
				"description": "Always peckish: hunger grows ~35% faster, trimming training gains.",
				"modifiers": {"hunger_rate": 1.35, "training_gain": 0.9},
			},
		],
	},
	&"power_napper": {
		"display_name": "Power Napper",
		"alignment": &"positive",
		"roll_weight": 32,
		"tiers": [
			{
				"label": "Quick Snoozer",
				"description": "Sleep recovers ~15% more energy and daytime drains ease a bit.",
				"modifiers": {"sleep_recovery": 1.15, "energy_drain": 0.9},
				"evolves_to": 1,
			},
			{
				"label": "Dream Sprinter",
				"description": "Loves naps: sleep restores ~35% more while drains fall ~30%.",
				"modifiers": {"sleep_recovery": 1.35, "energy_drain": 0.7},
			},
		],
	},
	&"wired": {
		"display_name": "Wired",
		"alignment": &"negative",
		"roll_weight": 28,
		"tiers": [
			{
				"label": "Restless",
				"description": "Fidgets non-stop, draining ~20% more energy and napping worse.",
				"modifiers": {"energy_drain": 1.2, "sleep_recovery": 0.9},
				"evolves_to": 1,
			},
			{
				"label": "Perma-Buzzed",
				"description": "Energy falls ~40% faster and naps only give ~75% recovery.",
				"modifiers": {"energy_drain": 1.4, "sleep_recovery": 0.75},
			},
		],
	},
	&"focused_student": {
		"display_name": "Focused Student",
		"alignment": &"positive",
		"roll_weight": 30,
		"tiers": [
			{
				"label": "Dialed In",
				"description": "Training XP gains ~20% more progress, fatigue grows slower.",
				"modifiers": {"training_gain": 1.2, "training_fatigue": 0.85},
				"evolves_to": 1,
			},
			{
				"label": "Prodigy Mode",
				"description": "Absorbs drills ~35% faster while fatigue rises ~30% slower.",
				"modifiers": {"training_gain": 1.35, "training_fatigue": 0.7},
			},
		],
	},
	&"daydreamer": {
		"display_name": "Daydreamer",
		"alignment": &"negative",
		"roll_weight": 26,
		"tiers": [
			{
				"label": "Easily Distracted",
				"description": "Training focus slips (~15% less XP) and fatigue builds quicker.",
				"modifiers": {"training_gain": 0.85, "training_fatigue": 1.2},
				"evolves_to": 1,
			},
			{
				"label": "Space Cadet",
				"description": "XP drops ~30% and fatigue piles up ~35% quicker.",
				"modifiers": {"training_gain": 0.7, "training_fatigue": 1.35},
			},
		],
	},
	&"tidy_freak": {
		"display_name": "Tidy Freak",
		"alignment": &"positive",
		"roll_weight": 24,
		"tiers": [
			{
				"label": "Dust Buster",
				"description": "Groom + nest actions clear ~20%/~15% more grime.",
				"modifiers": {"grooming_action": 1.2, "nest_action": 1.15},
				"evolves_to": 1,
			},
			{
				"label": "Sparkle Captain",
				"description": "Self-care pops (~40% relief) and nest tidy-ups hit ~35% harder.",
				"modifiers": {"grooming_action": 1.4, "nest_action": 1.35},
			},
		],
	},
	&"nest_shedder": {
		"display_name": "Nest Shedder",
		"alignment": &"negative",
		"roll_weight": 22,
		"tiers": [
			{
				"label": "Mess Maker",
				"description": "Grooming only helps ~85%; nest tidies reclaim ~80% of normal.",
				"modifiers": {"grooming_action": 0.85, "nest_action": 0.8},
				"evolves_to": 1,
			},
			{
				"label": "Walking Confetti",
				"description": "Self-care relief falls to ~70% and nests stay ~65% tidy.",
				"modifiers": {"grooming_action": 0.7, "nest_action": 0.65},
			},
		],
	},
}

static func get_definition(trait_id: StringName) -> Dictionary:
	if trait_id == StringName():
		return {}
	return TRAIT_DEFINITIONS.get(trait_id, {})

static func get_tier_data(trait_id: StringName, tier: int) -> Dictionary:
	var def: Dictionary = get_definition(trait_id)
	if def.is_empty():
		return {}
	var tiers: Array = def.get("tiers", [])
	if tier < 0 or tier >= tiers.size():
		return {}
	return tiers[tier]

static func create_state(trait_id: StringName, tier: int = 0, source: String = "", timestamp_ms: int = 0) -> TraitState:
	var def: Dictionary = get_definition(trait_id)
	if def.is_empty():
		return null
	var tiers: Array = def.get("tiers", [])
	var clamped_tier: int = clampi(tier, 0, max(tiers.size() - 1, 0))
	var state := TraitState.new()
	state.trait_id = trait_id
	state.tier = clamped_tier
	state.alignment = def.get("alignment", &"neutral")
	state.source = source
	state.acquired_at_ms = timestamp_ms if timestamp_ms > 0 else Time.get_ticks_msec()
	return state

static func roll_random_state(alignment_filter: StringName = StringName(), rng: RandomNumberGenerator = null, exclude_ids: Array[StringName] = []) -> TraitState:
	var entries: Array = []
	for trait_id in TRAIT_DEFINITIONS.keys():
		if exclude_ids.has(trait_id):
			continue
		var def: Dictionary = TRAIT_DEFINITIONS[trait_id]
		var alignment: StringName = def.get("alignment", &"neutral")
		if alignment_filter != StringName() and alignment != alignment_filter:
			continue
		var weight: int = int(def.get("roll_weight", 1))
		if weight <= 0:
			continue
		entries.append({"id": trait_id, "weight": weight})
	if entries.is_empty():
		return null
	var roller := rng
	if roller == null:
		roller = RandomNumberGenerator.new()
		roller.randomize()
	var total_weight := 0
	for entry in entries:
		total_weight += int(entry["weight"])
	if total_weight <= 0:
		return null
	var roll := roller.randi_range(1, total_weight)
	for entry in entries:
		roll -= int(entry["weight"])
		if roll <= 0:
			return create_state(entry["id"], 0, "birth", Time.get_ticks_msec())
	return create_state(entries.back()["id"], 0, "birth", Time.get_ticks_msec())

static func get_alignment(trait_id: StringName) -> StringName:
	var def: Dictionary = get_definition(trait_id)
	return def.get("alignment", &"neutral")

static func get_tier_label(trait_id: StringName, tier: int) -> String:
	var tier_data: Dictionary = get_tier_data(trait_id, tier)
	if tier_data.is_empty():
		return "Tier %d" % (tier + 1)
	return String(tier_data.get("label", "Tier %d" % (tier + 1)))

static func describe_state(state: TraitState) -> String:
	if state == null or !state.is_valid():
		return "--"
	var def: Dictionary = get_definition(state.trait_id)
	var display_name: String = def.get("display_name", String(state.trait_id))
	var tier_label: String = get_tier_label(state.trait_id, state.tier)
	return "%s (%s)" % [display_name, tier_label]

static func get_modifiers(state: TraitState) -> Dictionary:
	if state == null or !state.is_valid():
		return {}
	var tier_data: Dictionary = get_tier_data(state.trait_id, state.tier)
	if tier_data.is_empty():
		return {}
	return tier_data.get("modifiers", {})

static func get_evolution_target(state: TraitState) -> int:
	if state == null:
		return -1
	var tier_data: Dictionary = get_tier_data(state.trait_id, state.tier)
	if tier_data.is_empty():
		return -1
	return int(tier_data.get("evolves_to", -1))

static func can_evolve(state: TraitState) -> bool:
	return get_evolution_target(state) >= 0

static func get_tier_count(trait_id: StringName) -> int:
	var def: Dictionary = get_definition(trait_id)
	if def.is_empty():
		return 0
	var tiers: Array = def.get("tiers", [])
	return tiers.size()
