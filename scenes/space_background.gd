extends ParallaxBackground

@export var scroll_speed := 50
var scroll_x = 0

func _process(delta):	
	# Scroll background
	scroll_x -= scroll_speed * delta
	scroll_offset.x = scroll_x
