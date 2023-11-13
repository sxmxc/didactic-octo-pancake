extends Node

signal energy_updated
signal hunger_updated
signal health_updated

signal world_view_requested
signal build_view_requested
signal focus_view_requested(creature: Creature)
signal popup_requested(message: String)

signal new_creature_requested

signal feed_request(food: Food)

signal notification_requested(notification: String)

func _ready():
	print("EventBus Ready")
