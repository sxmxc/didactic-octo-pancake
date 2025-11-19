extends Species
class_name BabySpecies

@export var teen_posibilities : Array[TeenSpecies] = []
@export var egg_texture: Texture2D
@export var egg_tier: StringName = &"meadow"
@export_range(1, 100) var hatch_weight: int = 1
