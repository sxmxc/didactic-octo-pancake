extends MenuDrawer

@export var default_food_scene: PackedScene = preload("res://scenes/food/meat.tscn")
@onready var feed_button: Button = %FeedButton

func _ready() -> void:
	super._ready()
	feed_button.pressed.connect(_on_feed_pressed)

func _on_feed_pressed() -> void:
	if default_food_scene == null:
		return
	var food = default_food_scene.instantiate()
	SoundManager.play_ui_sound(Data.sfx_library["click"])
	Eventbus.feed_request.emit(food)
