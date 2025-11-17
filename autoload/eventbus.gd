extends Node

@warning_ignore("unused_signal")
signal current_energy_updated
@warning_ignore("unused_signal")
signal current_hunger_updated
@warning_ignore("unused_signal")
signal health_updated
@warning_ignore("unused_signal")
signal world_view_requested
@warning_ignore("unused_signal")
signal build_view_requested
@warning_ignore("unused_signal")
signal focus_view_requested(creature: Creature)
@warning_ignore("unused_signal")
signal popup_requested(message: String)
@warning_ignore("unused_signal")
signal new_creature_requested
@warning_ignore("unused_signal")
signal feed_request(food: Food)
@warning_ignore("unused_signal")
signal notification_requested(notification: String)
@warning_ignore("unused_signal")
signal player_wallet_updated(wallet: Dictionary)
@warning_ignore("unused_signal")
signal player_currency_earned(type: String, amount : int)
@warning_ignore("unused_signal")
signal player_egg_inventory_updated(inventory: Array)
@warning_ignore("unused_signal")
signal buildable_drag_started()
@warning_ignore("unused_signal")
signal buildable_drag_ended()
@warning_ignore("unused_signal")
signal save_completed(result: Dictionary)
@warning_ignore("unused_signal")
signal save_failed(message: String)
@warning_ignore("unused_signal")
signal load_failed(message: String)
@warning_ignore("unused_signal")
signal egg_hatch_requested(egg_index: int)

func _ready():
	print("EventBus Ready")
