extends Resource
class_name Species

const DIET_MEAT: String = "meat"
const DIET_VEGGIE: String = "veggie"
const DIET_OMNIVORE: String = "omnivore"
const DIET_TYPES: Array[StringName] = [
	StringName(DIET_MEAT),
	StringName(DIET_VEGGIE),
	StringName(DIET_OMNIVORE),
]

@export var species_name: String = ""
@export var spritesheet : Texture2D
@export_enum("meat", "veggie", "omnivore") var diet: String = DIET_OMNIVORE

@export var hunger_decay_multiplier: float = 1.0
@export var energy_decay_multiplier: float = 1.0
@export var sleep_recovery_multiplier: float = 1.0
@export var sleep_hunger_multiplier: float = 1.0

@export var requirements : Dictionary = {
	"happiness" : 0,
	"care_mistakes" : 0,
	"strength": 0,
	"intelligence": 0,
	"is_dead" : false
}

func get_diet() -> StringName:
	return StringName(diet)
