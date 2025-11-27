extends Resource
class_name CreatureConfig

@export var action_metadata: Dictionary = {
	"idle": {
		"label": "Daydreaming",
		"thoughts": [
			"Blink... blink... oh hi.",
			"I swear that cloud winked at me.",
			"Is it nap time again already?"
		],
		"emotion": "idle",
	},
	"wander": {
		"label": "Exploring",
		"thoughts": [
			"Perimeter looks secure. Probably.",
			"New pebble acquired! Treasure?",
			"If I walk in circles I'll make crop art."
		],
		"emotion": "happy",
	},
	"seek_food": {
		"label": "Hunting snacks",
		"thoughts": [
			"If it's crunchy I'm in.",
			"My nose says the buffet is *that* way.",
			"Please let this be pizza."
		],
		"emotion": "hungry",
	},
	"eat": {
		"label": "Eating",
		"thoughts": [
			"Chomp city, population: me.",
			"Compliments to the chef (it's me).",
			"Culinary excellence unlocked."
		],
		"emotion": "love",
	},
	"heading_home": {
		"label": "Heading to bed",
		"thoughts": [
			"Calling dibs on the cozy corner.",
			"Bedtime pilgrimage commencing.",
			"Hope the sheets are still toasty."
		],
		"emotion": "idle",
	},
	"sleep": {
		"label": "Sleeping",
		"thoughts": [
			"Dreaming of endless buffets.",
			"Whale songs + white noise = perfection.",
			"zzz... (do not disturb)."
		],
		"emotion": "sleepy",
	},
	"groom": {
		"label": "Self-care",
		"thoughts": [
			"Can't go on stage with messy spikes.",
			"Polish, rinse, repeat.",
			"Glow-up loading..."
		],
		"emotion": "love",
	},
	"tidy_nest": {
		"label": "Tidying nest",
		"thoughts": [
			"Crumbs begone!",
			"Interior design montage music intensifies.",
			"This place is going to sparkle."
		],
		"emotion": "happy",
	}
}

@export var default_stage_care_profile: Dictionary = {
	"hunger": 1.0,
	"energy": 1.0,
	"sleep_energy": 1.0,
	"sleep_hunger_fraction": 0.5,
}

@export var life_stage_care_profile: Dictionary = {
	"egg": {
		"hunger": 0.0,
		"energy": 0.0,
		"sleep_energy": 0.0,
		"sleep_hunger_fraction": 0.0,
	},
	"baby": {
		"hunger": 1.2,
		"energy": 1.1,
		"sleep_energy": 0.9,
		"sleep_hunger_fraction": 0.35,
	},
	"teen": {
		"hunger": 1.0,
		"energy": 1.0,
		"sleep_energy": 1.0,
		"sleep_hunger_fraction": 0.45,
	},
	"adult": {
		"hunger": 0.8,
		"energy": 0.9,
		"sleep_energy": 1.1,
		"sleep_hunger_fraction": 0.6,
	},
}

@export var training_gain_per_minute: Dictionary = {
	"strength": 4.0,
	"intelligence": 3.5,
	"happiness": 2.5,
}

@export var training_xp_per_point: Dictionary = {
	"strength": 6.0,
	"intelligence": 5.0,
	"happiness": 4.0,
}

@export var training_decay_per_hour: Dictionary = {
	"strength": 1.25,
	"intelligence": 1.0,
	"happiness": 0.75,
}

@export var training_hunger_cost_per_minute: Dictionary = {
	"strength": 3.0,
	"intelligence": 2.0,
	"happiness": 1.5,
}

@export var training_energy_cost_per_minute: Dictionary = {
	"strength": 6.0,
	"intelligence": 4.0,
	"happiness": 3.0,
}
