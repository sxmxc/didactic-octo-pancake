extends NinePatchRect
@export var meat_scene: PackedScene = preload("res://scenes/food/meat.tscn")
@onready var creature_button = %CreatureButton
@onready var build_button = %BuildButton
@onready var pull_out_drawer = %PullOutDrawer

# Called when the node enters the scene tree for the first time.
func _ready():
	creature_button.pressed.connect(pull_out_drawer._on_creature_button_pressed)
	build_button.pressed.connect(pull_out_drawer._on_build_button_pressed)
	Eventbus.player_wallet_updated.connect(_on_player_wallet_updated)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_new_creature_button_pressed():
	SoundManager.play_ui_sound(Data.sfx_library["click"])
	Eventbus.new_creature_requested.emit()
	Tracer.info("Requesting new creature")
	pass # Replace with function body.


func _on_feed_button_pressed():
	var food = meat_scene.instantiate()
	SoundManager.play_ui_sound(Data.sfx_library["click"])
	Eventbus.feed_request.emit(food)
	Tracer.info("Requesting food")
	pass # Replace with function body.
	
func _on_player_wallet_updated(wallet: Dictionary):
	%GoldValue.text = "%s" % wallet.gold
	#%GemValue.text = "%s" % wallet.gem
	#%PlatinumValue.text = "%s" % wallet.platinum
