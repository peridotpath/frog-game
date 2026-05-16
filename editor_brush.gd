extends Decal

@export var Camera: Camera3D

func _process(_delta: float):
	var mouse_pos = get_viewport().get_mouse_position()
	_position_cursor(mouse_pos)

func _position_cursor(mouse_pos: Vector2):
	# Project ray from camera to screen
	var ray_start = Camera.project_ray_origin(mouse_pos)
	var ray_end = ray_start + Camera.project_ray_normal(mouse_pos) * 1000
	
	# Create query parameters
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	var result = space_state.intersect_ray(query)
	if result:
		global_position = result.position
			
