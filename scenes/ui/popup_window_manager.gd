extends Node
class_name PopupWindowManager

const NOTIFICATION_WINDOW_SCENE := preload("res://scenes/ui/notification_window.tscn")
const ITEM_DETAILS_WINDOW_SCENE := preload("res://scenes/ui/drawers/item_details_window.tscn")
const HATCH_ODDS_WINDOW_SCENE := preload("res://scenes/ui/drawers/hatch_odds_window.tscn")

var _notification_window: NotificationWindow
var _item_details_window: ItemDetailsWindow
var _hatch_odds_window: HatchOddsWindow

func _ready() -> void:
	add_to_group("popup_manager")
	_notification_window = NOTIFICATION_WINDOW_SCENE.instantiate() as NotificationWindow
	if _notification_window:
		add_child(_notification_window)
	_item_details_window = ITEM_DETAILS_WINDOW_SCENE.instantiate() as ItemDetailsWindow
	if _item_details_window:
		add_child(_item_details_window)
	_hatch_odds_window = HATCH_ODDS_WINDOW_SCENE.instantiate() as HatchOddsWindow
	if _hatch_odds_window:
		add_child(_hatch_odds_window)

func show_message(message: String, title: String = "Notice") -> void:
	if _notification_window == null:
		return
	_notification_window.open_message(message, title)

func show_item_details(payload: Dictionary) -> void:
	if _item_details_window == null:
		return
	_item_details_window.open_with_payload(payload)

func close_item_details() -> void:
	if _item_details_window == null:
		return
	_item_details_window.hide()

func show_hatch_odds(entries: Array[Dictionary], description: String = "") -> void:
	if _hatch_odds_window == null:
		return
	_hatch_odds_window.open_with_entries(entries, description)

func close_hatch_odds() -> void:
	if _hatch_odds_window == null:
		return
	_hatch_odds_window.hide()
