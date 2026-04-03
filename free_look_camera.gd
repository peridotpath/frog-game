#Copyright © 2022 Marc Nahr: https://github.com/MarcPhi/godot-free-look-camera
extends Camera3D

@export_range(0, 10, 0.01) var sensitivity : float = 3
@export_range(0, 1000, 0.1) var default_velocity : float = 5
@export_range(0, 10, 0.01) var speed_scale : float = 1.17
@export_range(1, 100, 0.1) var boost_speed_multiplier : float = 3.0
@export var max_speed : float = 1000
@export var min_speed : float = 0.2

@onready var _velocity = default_velocity

@export var TerrainCursor : DecalCompatibility

@export var brush_strength : int = 50
@export var terrain: MeshInstance3D
@export var vertex_cubes: Node3D
var last_tick: int

func _input(event):
	if not current:
		return
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotation.y -= event.relative.x / 1000 * sensitivity
			rotation.x -= event.relative.y / 1000 * sensitivity
			rotation.x = clamp(rotation.x, PI/-2, PI/2)
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_MIDDLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
			MOUSE_BUTTON_WHEEL_UP: # increase fly velocity
				_velocity = clamp(_velocity * speed_scale, min_speed, max_speed)
			MOUSE_BUTTON_WHEEL_DOWN: # decrease fly velocity
				_velocity = clamp(_velocity / speed_scale, min_speed, max_speed)
			MOUSE_BUTTON_WHEEL_LEFT: # decrease fly velocity
				_velocity = clamp(_velocity / speed_scale, min_speed, max_speed)
			MOUSE_BUTTON_LEFT:
				_handle_gaussian_deform(1)
			MOUSE_BUTTON_RIGHT:
				_handle_gaussian_deform(-1)

func _handle_gaussian_deform(direction: float):
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(terrain.mesh, 0)
	var terrain_loc = terrain.global_transform

	var arrays = terrain.mesh.surface_get_arrays(0)
	
	var verts = arrays[Mesh.ARRAY_VERTEX]
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)

		if (is_point_in_sphere(vertex * terrain_loc,TerrainCursor.global_position,TerrainCursor.size[0]/2)):
			var y_change = gaussian_deform((vertex * terrain_loc).distance_to(TerrainCursor.global_position), 0, TerrainCursor.size[0]/2)
			verts[i] = vertex + Vector3(0,direction*y_change*1,0)
			
	# 1. Update the vertex array as you already are
	arrays[Mesh.ARRAY_VERTEX] = verts

	# 2. Use SurfaceTool to regenerate the normals
	var st = SurfaceTool.new()
	st.index()
	st.create_from_arrays(arrays) # Load your modified vertex data
	st.generate_normals()         # This actually calculates the new slope
	st.generate_tangents()        # Recommended for consistent lighting

	# 3. Commit the result back to the terrain
	var new_mesh = st.commit()
	terrain.mesh = new_mesh

	# 4. Update collision to match the new shape
	terrain.create_trimesh_collision()
	
func gaussian_deform(x: float, mean: float, std_dev: float) -> float:
	var exponent = -0.5 * pow((x - mean) / std_dev, 2)
	var factor = 1.0 / (std_dev * sqrt(2.0 * PI))
	return factor * exp(exponent)
	
func _process(delta):
	if not current:
		return
		
	var direction = Vector3(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q)), 
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	).normalized()
	
	if Input.is_physical_key_pressed(KEY_SHIFT): # boost
		translate(direction * _velocity * delta * boost_speed_multiplier)
	else:
		translate(direction * _velocity * delta)
		
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Project ray from camera to screen
	var ray_start = project_ray_origin(mouse_pos)
	var ray_end = ray_start + project_ray_normal(mouse_pos) * 1000
	
	# Create query parameters
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	var result = space_state.intersect_ray(query)
	if result:
		TerrainCursor.global_position = result.position
	
	last_tick += 1
	if (last_tick > 5):
		last_tick = 0
		_process_vertex_cubes()

func _process_vertex_cubes():
	for n in vertex_cubes.get_children():
		vertex_cubes.remove_child(n)
		n.queue_free()
		
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(terrain.mesh, 0)
	var terrain_loc = terrain.global_transform
	
	var arrays = terrain.mesh.surface_get_arrays(0)
	var verts = arrays[Mesh.ARRAY_VERTEX]
	for v in range(mdt.get_vertex_count()):
		var vertex:  = mdt.get_vertex(v)
		if (is_point_in_sphere(vertex * terrain_loc, TerrainCursor.global_position, TerrainCursor.size[0]/2)):
			# 1. Create the MeshInstance3D node
			var mesh_instance = MeshInstance3D.new()
			# 2. Create the specific mesh shape (e.g., BoxMesh)
			var box_mesh = BoxMesh.new()
			box_mesh.size = Vector3(0.2, 0.2, 0.2) # Size 1x1x1
			# 3. Assign the mesh to the instance
			mesh_instance.mesh = box_mesh
			# 4. Position the mesh in the world
			vertex_cubes.add_child(mesh_instance)
			mesh_instance.global_position = Vector3(vertex)
		
func is_point_in_sphere(point: Vector3, sphere_center: Vector3, radius: float) -> bool:
	return sphere_center.distance_to(point) < radius
