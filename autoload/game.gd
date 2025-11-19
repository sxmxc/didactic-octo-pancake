extends Node

const LogLevel = Tracer.Level
const AUTOSAVE_DELAY := 1.5
const MAX_IDLE_CATCHUP_SECONDS := 6 * 3600
const DAILY_PACK_ID := "daily_single"

var rng := RandomNumberGenerator.new()

var _world: GameWorld = null
var _autosave_timer: Timer
var _pending_save_reason := ""
var _last_manual_save_message := ""
var _tier_weight_cache: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	var trace_subscriber = (
		TraceSubscriber
		. new()
		. with_colored_output(true)
		. with_level(true)
		. with_nicer_colors(true)
		. with_timestamp(true)
		. with_filter(LogLevel.Info | LogLevel.Warn | LogLevel.Error | LogLevel.Debug)
	)
	trace_subscriber.init()
	
	var logs = FileAccess.open("res://logs/logs.txt", FileAccess.WRITE)
	var file_logger = (
		TraceSubscriber
		. new()
		. barebones()
		. with_writer(
			TraceSubscriber.writer_from_file(logs)
		)
	)
	
	file_logger.init()
	Tracer.info("Tracer Ready")
	
	SoundManager.set_default_music_bus("Music")
	SoundManager.set_default_sound_bus("FX")
	SoundManager.set_default_ui_sound_bus("UI")
	_setup_autosave_timer()
	rng.randomize()
	Tracer.info("Game Ready")

func register_world(world_instance: GameWorld) -> void:
	_world = world_instance
	SaveIO.ensure_save_directory()
	var result: Dictionary = SaveIO.load_slot()
	var loaded: bool = false
	if result.get("ok", false) and result.has("data"):
		var payload: Dictionary = result["data"]
		_apply_rng_state(payload.get("rng_state", {}))
		loaded = _apply_saved_state(payload)
	else:
		var error: String = result.get("error", "")
		if error != "" and error != "missing":
			Eventbus.load_failed.emit("Unable to load save slot (%s)" % error)
	if !loaded:
		_world.start_new_session()
	_world.begin_simulation()
	queue_save("bootstrap")

func queue_save(reason: String, immediate := false) -> void:
	if _world == null:
		return
	if immediate:
		_flush_save(reason, false)
		return
	_pending_save_reason = reason
	_autosave_timer.start(AUTOSAVE_DELAY)

func manual_save_and_sleep() -> Dictionary:
	if _world == null:
		return {"ok": false, "message": "World not initialized yet."}
	var err := _flush_save("manual_sleep", true)
	if err == OK:
		var message := "Progress saved at %s" % Time.get_datetime_string_from_system(false, true)
		_last_manual_save_message = message
		return {"ok": true, "message": message}
	return {"ok": false, "message": "Save failed (%s)" % err}

func random_choice(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[rng.randi_range(0, array.size() - 1)]

func random_range(min_value: int, max_value: int) -> int:
	return rng.randi_range(min_value, max_value)

func _setup_autosave_timer() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.one_shot = true
	_autosave_timer.wait_time = AUTOSAVE_DELAY
	_autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(_autosave_timer)

func _on_autosave_timeout() -> void:
	if _pending_save_reason == "":
		_pending_save_reason = "autosave"
	_flush_save(_pending_save_reason, false)
	_pending_save_reason = ""

func _flush_save(reason: String, manual := false) -> Error:
	if _world == null:
		return ERR_DOES_NOT_EXIST
	if _world.has_method("prepare_for_save"):
		_world.prepare_for_save()
	var payload: Dictionary = _world.serialize_state()
	payload["save_version"] = SaveIO.SAVE_VERSION
	payload["rng_state"] = {
		"seed": rng.seed,
		"state": rng.state,
	}
	payload["saved_at_ms"] = Time.get_ticks_msec()
	payload["save_reason"] = reason
	var err := SaveIO.write_slot(payload)
	if err == OK:
		Eventbus.save_completed.emit({"reason": reason, "manual": manual})
	else:
		Eventbus.save_failed.emit("Save failed (%s)" % err)
	return err

func _apply_rng_state(state: Dictionary) -> void:
	if state.has("seed"):
		rng.seed = state["seed"]
	if state.has("state"):
		rng.state = state["state"]

func _apply_saved_state(payload: Dictionary) -> bool:
	if !_world.has_method("apply_saved_state"):
		return false
	var applied: bool = _world.apply_saved_state(payload)
	if applied:
		_run_idle_catchup(payload)
	return applied

func _run_idle_catchup(payload: Dictionary) -> void:
	if _world == null or !_world.has_method("apply_idle_ticks"):
		return
	var world_data: Dictionary = payload.get("world", {})
	var last_tick: int = int(world_data.get("last_tick_epoch_ms", 0))
	if last_tick == 0:
		return
	var now_ms := Time.get_ticks_msec()
	var elapsed_ms : float = max(now_ms - last_tick, 0)
	var tick_frequency: int = int(world_data.get("tick_frequency", 10))
	var tick_interval_ms: int = tick_frequency * 1000
	if tick_interval_ms <= 0:
		return
	var tick_count: int = int(elapsed_ms / tick_interval_ms)
	if tick_count <= 0:
		return
	var max_ticks: int = int(MAX_IDLE_CATCHUP_SECONDS / max(tick_frequency, 1))
	tick_count = min(tick_count, max_ticks)
	if tick_count > 0:
		_world.apply_idle_ticks(tick_count)

func sync_egg_rewards(player: Player) -> void:
	if player == null:
		return
	_award_daily_pack(player)

func roll_species_for_tier(tier_id: StringName) -> String:
	var safe_tier: StringName = tier_id if tier_id != StringName() else &"meadow"
	var entries: Array = _tier_weight_cache.get(safe_tier, [])
	if entries.is_empty():
		entries = _build_tier_weights(safe_tier)
		_tier_weight_cache[safe_tier] = entries
	if entries.is_empty():
		return ""
	var total_weight := 0
	for entry in entries:
		total_weight += int(entry.get("weight", 0))
	if total_weight <= 0:
		return ""
	var roll := rng.randi_range(1, total_weight)
	for entry in entries:
		roll -= int(entry.get("weight", 0))
		if roll <= 0:
			return String(entry.get("key", ""))
	return String(entries.back().get("key", ""))

func _build_tier_weights(tier_id: StringName) -> Array:
	var entries: Array = []
	for key in Data.species_baby_library.keys():
		var species: BabySpecies = Data.species_baby_library[key]
		var species_tier: StringName = species.egg_tier if species.egg_tier != StringName() else &"meadow"
		if species_tier == tier_id:
			var weight: int = max(species.hatch_weight, 1)
			entries.append({"key": key, "weight": weight})
	return entries

func _award_daily_pack(player: Player) -> void:
	var pack_def: Dictionary = Data.egg_pack_definitions.get(DAILY_PACK_ID, {})
	if pack_def.is_empty():
		return
	var now_ms := Time.get_unix_time_from_system() * 1000
	if !player.can_claim_pack(DAILY_PACK_ID, now_ms):
		return
	var cooldown_hours: float = float(pack_def.get("cooldown_hours", 20.0))
	player.grant_pack(DAILY_PACK_ID, 1, false, false)
	player.mark_pack_claimed(DAILY_PACK_ID, cooldown_hours, now_ms, true)
	var pack_name: String = pack_def.get("display_name", "Daily egg pack")
	Eventbus.notification_requested.emit("%s delivered!" % pack_name)
