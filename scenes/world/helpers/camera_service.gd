extends Node
class_name CameraPriorityService

const DEFAULT_ACTIVE_PRIORITY: int = 20
const DEFAULT_INACTIVE_PRIORITY: int = 0

func promote(camera: PhantomCamera2D, active_priority: int = DEFAULT_ACTIVE_PRIORITY, inactive_priority: int = DEFAULT_INACTIVE_PRIORITY) -> void:
	if camera == null:
		return
	for cam in PhantomCameraManager.get_phantom_camera_2ds():
		cam.set_priority(inactive_priority)
	camera.set_priority(active_priority)
