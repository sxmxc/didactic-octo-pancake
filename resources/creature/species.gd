extends Resource
class_name Species

@export var species_name: String = ""
@export var spritesheet : Texture2D

@export var requirements : Dictionary = {
	"happiness" : 0,
	"care_mistakes" : 0,
	"strength": 0,
	"intelligence": 0,
	"is_dead" : false
}
