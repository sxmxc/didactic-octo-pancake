extends Node
class_name WorldSimulation

func setup_timer(world: GameWorld, tick_frequency: int) -> Timer:
	var timer := Timer.new()
	timer.wait_time = tick_frequency
	timer.one_shot = false
	timer.autostart = false
	timer.timeout.connect(world._on_timer_timeout)
	world.add_child(timer)
	return timer

func begin_simulation(world: GameWorld) -> void:
	if world.world_clock == null or world._is_simulation_running:
		return
	world.world_clock.wait_time = world.tick_frequency
	world.world_clock.start()
	world._is_simulation_running = true
	world._last_tick_epoch_ms = Time.get_ticks_msec()
	Tracer.info("World simulation started (tick_frequency=%d)" % world.tick_frequency)

func stop_simulation(world: GameWorld) -> void:
	if world.world_clock:
		world.world_clock.stop()
	world._is_simulation_running = false
	Tracer.info("World simulation stopped")

func register_creature_for_ticks(world: GameWorld, creature: Creature) -> void:
	if world.world_clock == null or creature == null:
		return
	if world.world_clock.timeout.is_connected(creature._on_world_tick):
		return
	world.world_clock.timeout.connect(creature._on_world_tick)

func apply_idle_ticks(world: GameWorld, tick_count: int) -> void:
	if tick_count <= 0:
		return
	Tracer.info("Applying %d idle ticks" % tick_count)
	for _i in range(tick_count):
		for creature in world._get_active_creatures():
			creature._on_world_tick()
	world._last_tick_epoch_ms = Time.get_ticks_msec()
