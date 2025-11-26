extends Node2D
class_name Buildable

@export var buildable_name : String = ""
@export var buildable_key : String = ""
@export var buildable_cost : int = 0
@export_enum("gold", "gem", "platinum") var build_cost_type : String = "gold"
@export var menu_icon_texture : Texture2D
@export var tile_source_id: int = 1
@export var tile_atlas_coords: Vector2i = Vector2i.ZERO
@export var tile_id: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
