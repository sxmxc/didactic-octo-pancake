extends Control

@export var show_continue_button: bool = true
@export var use_sub_threads: bool = true
@export var indicator_interval: float = 0.6
@export var quick_fact_interval: float = 4.5
@export var quick_facts: PackedStringArray = PackedStringArray([
	"Feed hungry creatures quickly—drag food from the world drawer before their hunger meter flashes red.",
	"Sleeping pods pause stat decay. Drop one near multiple nests to stabilize night cycles.",
	"Clean up waste often. The longer it lingers, the more sickness stacks build across the entire pen.",
	"Stacking two toys boosts the fun meter faster but also drains energy twice as fast.",
	"Tap a creature to pin its stats and watch how care mistakes stack toward evolution outcomes."
])
@export var indicator_steps: PackedStringArray = PackedStringArray([
	"Syncing creature vitals 🩺",
	"Priming incubators 🔧",
	"Infusing snack queue 🍉",
	"Calming clock spirits ⏱️",
	"Pinging data crystals 💾"
])
@export var emoji_progress_track: PackedStringArray = PackedStringArray([
	"🥚",
	"💧",
	"🌱",
	"🌿",
	"🌸",
	"✨"
])

@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _status_label: Label = %StatusLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _quick_fact_label: Label = %QuickFactLabel
@onready var _continue_button: Button = %ContinueButton
@onready var _indicator_timer: Timer = %IndicatorTimer
@onready var _quick_fact_timer: Timer = %QuickFactTimer

var _indicator_index: int = 0
var _facts_pool: Array[String] = []
var _load_complete: bool = false

func _ready() -> void:
	randomize()
	_prepare_timers()
	_continue_button.visible = show_continue_button
	_continue_button.disabled = true
	_continue_button.pressed.connect(_on_continue_pressed)
	_status_label.text = indicator_steps[0] if indicator_steps.size() > 0 else "Booting habitat..."
	_progress_bar.value = 0.0
	_progress_label.text = _build_progress_meter(0.0)
	_update_quick_fact()
	SceneManager.progress_changed.connect(_on_progress_changed)
	SceneManager.load_done.connect(_on_load_done)
	SceneManager.change_scene_immediately = not show_continue_button
	SceneManager.use_sub_threads = use_sub_threads
	SceneManager.start_load()

func _prepare_timers() -> void:
	_indicator_timer.wait_time = max(indicator_interval, 0.15)
	_indicator_timer.timeout.connect(_on_indicator_tick)
	_indicator_timer.start()
	_quick_fact_timer.wait_time = max(quick_fact_interval, 2.0)
	_quick_fact_timer.timeout.connect(_on_quick_fact_tick)
	_quick_fact_timer.start()

func _on_progress_changed(progress: float) -> void:
	var clamped := clampf(progress, 0.0, 1.0)
	var percent := int(round(clamped * 100.0))
	_progress_bar.value = percent
	_progress_label.text = "%02d%%  %s" % [percent, _build_progress_meter(clamped)]

func _on_load_done() -> void:
	_load_complete = true
	_status_label.text = "Habitat ready — tap to enter ✨"
	if !show_continue_button:
		return
	await get_tree().create_timer(0.8).timeout
	_continue_button.disabled = false
	_continue_button.grab_focus()

func _on_continue_pressed() -> void:
	if !_load_complete:
		return
	SceneManager.change_scene()

func _on_indicator_tick() -> void:
	if indicator_steps.is_empty():
		return
	_indicator_index = (_indicator_index + 1) % indicator_steps.size()
	_status_label.text = indicator_steps[_indicator_index]

func _on_quick_fact_tick() -> void:
	_update_quick_fact()

func _update_quick_fact() -> void:
	if quick_facts.is_empty():
		_quick_fact_label.text = "Explore, experiment, and keep your creatures thriving."
		return
	if _facts_pool.is_empty():
		for fact in quick_facts:
			_facts_pool.push_back(fact)
		_facts_pool.shuffle()
	_quick_fact_label.text = _facts_pool.pop_back()

func _build_progress_meter(progress: float) -> String:
	if emoji_progress_track.is_empty():
		return ""
	var steps := emoji_progress_track.size()
	var filled := clampi(int(round(progress * steps)), 0, steps)
	var pieces: Array[String] = []
	for i in range(steps):
		if i < filled:
			pieces.push_back(emoji_progress_track[i])
		else:
			pieces.push_back("▫️")
	return " ".join(pieces)
