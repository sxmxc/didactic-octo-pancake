extends Node

signal current_energy_updated
signal current_hunger_updated
signal health_updated

signal world_view_requested
signal build_view_requested
signal focus_view_requested(creature: Creature)
signal popup_requested(message: String)

signal new_creature_requested

signal feed_request(food: Food)

signal notification_requested(notification: String)

signal player_wallet_updated(wallet: Dictionary)
signal player_currency_earned(type: String, amount : int)

signal buildable_drag_started()
signal buildable_drag_ended()

func _ready():
	print("EventBus Ready")
