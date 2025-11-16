extends Panel


# Called when the node enters the scene tree for the first time.
func _ready():
	Eventbus.player_wallet_updated.connect(_on_player_wallet_updated)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_player_wallet_updated(wallet: Dictionary):
	%GoldValue.text = "%s" % wallet.gold
	%GemValue.text = "%s" % wallet.gem
	%PlatinumValue.text = "%s" % wallet.platinum
