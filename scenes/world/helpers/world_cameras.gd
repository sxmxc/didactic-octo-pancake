extends Node
class_name WorldCameras

var camera_service: CameraPriorityService
var world_camera: PhantomCamera2D
var build_camera: PhantomCamera2D
var ui: WorldUI

func on_focus_view_requested(creature: Creature) -> void:
	if creature == null:
		return
	Tracer.info("Focus view request recieved for " + creature.name)
	if camera_service:
		camera_service.promote(creature.camera)
	creature.camera.follow_target = creature
	creature.camera.follow_mode = PhantomCamera2D.FollowMode.SIMPLE
	if ui:
		ui.set_focus(creature)
		ui.current_creature_stats.visible = true
	Eventbus.current_energy_updated.emit()
	Eventbus.current_hunger_updated.emit()

func on_world_view_requested() -> void:
	Tracer.info("World view request received")
	if world_camera == null:
		return
	if !world_camera.priority >= CameraPriorityService.DEFAULT_ACTIVE_PRIORITY:
		if ui:
			ui.current_creature_stats.visible = false
		if camera_service:
			camera_service.promote(world_camera)

func on_build_view_requested() -> void:
	Tracer.info("Build view request recieved")
	if build_camera == null:
		return
	if !build_camera.priority >= CameraPriorityService.DEFAULT_ACTIVE_PRIORITY:
		if camera_service:
			camera_service.promote(build_camera)
