extends Node

const LogLevel = Tracer.Level

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
	
	Tracer.info("Game Ready")
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
