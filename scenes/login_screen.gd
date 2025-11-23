extends Control

const DEVICE_CONFIG_PATH := "user://device_identity.cfg"
const DEVICE_SECTION := "identity"
const DEVICE_ID_KEY := "identifier"
const DEVICE_SERVICE := "device"

@onready var status_label: Label = %StatusLabel
@onready var continue_button: Button = %ContinueButton

var _navigating := false
var _identifying := false
var _can_continue := false
var _device_identifier := ""
var _talo_ready := false
var _waiting_for_talo := false

func _ready() -> void:
	continue_button.visible = true
	continue_button.disabled = true
	continue_button.text = "Retry"
	status_label.text = "Booting online services..."
	_device_identifier = _load_or_create_device_identifier()
	Talo.players.identified.connect(_on_talo_player_identified)
	Talo.players.identification_failed.connect(_on_talo_identify_failed)
	_talo_ready = Talo.is_node_ready()
	if !_talo_ready and !_waiting_for_talo:
		_waiting_for_talo = true
		Talo.init_completed.connect(_on_talo_ready, CONNECT_ONE_SHOT)
	_start_identification()

func _load_or_create_device_identifier() -> String:
	var config := ConfigFile.new()
	var saved: String = ""
	var err := config.load(DEVICE_CONFIG_PATH)
	if err == OK:
		saved = str(config.get_value(DEVICE_SECTION, DEVICE_ID_KEY, ""))
	if saved != "":
		return saved
	var identifier := OS.get_unique_id()
	if identifier == "":
		identifier = "device_%s" % Talo.players.generate_identifier()
	config.set_value(DEVICE_SECTION, DEVICE_ID_KEY, identifier)
	config.save(DEVICE_CONFIG_PATH)
	return identifier

func _start_identification() -> void:
	if _identifying:
		return
	_identifying = true
	_can_continue = false
	continue_button.disabled = true
	continue_button.text = "Retry"
	status_label.text = "Identifying device..."
	if _talo_ready:
		_identify_async()

func _identify_async() -> void:
	if !_identifying:
		return
	var player := await Talo.players.identify(DEVICE_SERVICE, _device_identifier)
	if player == null:
		_identifying = false

func _on_talo_ready() -> void:
	_talo_ready = true
	_waiting_for_talo = false
	if _identifying:
		_identify_async()

func _on_talo_player_identified(_player: TaloPlayer) -> void:
	_identifying = false
	_can_continue = true
	continue_button.text = "Continue"
	continue_button.disabled = false
	status_label.text = "Welcome back!"
	#_continue_to_menu()

func _on_talo_identify_failed() -> void:
	_identifying = false
	_can_continue = false
	continue_button.disabled = false
	continue_button.text = "Retry"
	status_label.text = "Unable to reach Talo. Check your connection and retry."

func _on_continue_button_pressed() -> void:
	if _can_continue and !_navigating:
		_go_to_main_menu()
	elif !_identifying:
		_start_identification()

func _continue_to_menu() -> void:
	if !_navigating and _can_continue:
		_go_to_main_menu()

func _go_to_main_menu() -> void:
	if _navigating:
		return
	_navigating = true
	status_label.text = "Loading main menu..."
	continue_button.disabled = true
	SceneManager.load_scene("res://scenes/main_menu.tscn", "", false)
