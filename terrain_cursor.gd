@tool

extends DecalCompatibility

@export var strength : int = 50
@export var terrain: MeshInstance3D
@export var cubes: Node3D
var last_tick: int

func _process(delta) -> void:
	last_tick += 1
	if (last_tick > 5):
		last_tick = 0
		_process_vertex_cubes()

func _process_vertex_cubes():
	for n in cubes.get_children():
		cubes.remove_child(n)
		n.queue_free()
		
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(terrain.mesh, 0)
	var terrain_loc = terrain.global_transform
	
	var arrays = terrain.mesh.surface_get_arrays(0)
	var verts = arrays[Mesh.ARRAY_VERTEX]
	
	for v in range(mdt.get_vertex_count()):
		if (is_point_in_sphere(verts[v] * terrain_loc, global_position,size[0])):
			var vertex = mdt.get_vertex(v)
			# 1. Create the MeshInstance3D node
			var mesh_instance = MeshInstance3D.new()
			# 2. Create the specific mesh shape (e.g., BoxMesh)
			var box_mesh = BoxMesh.new()
			box_mesh.size = Vector3(0.1, 0.1, 0.1) # Size 1x1x1
			# 3. Assign the mesh to the instance
			mesh_instance.mesh = box_mesh
			# 4. Position the mesh in the world
			mesh_instance.global_position = Vector3(vertex)
			# 5. Add to the active scene tree (e.g., to the root or current node)
			cubes.add_child(mesh_instance)
		
func is_point_in_sphere(point: Vector3, sphere_center: Vector3, radius: float) -> bool:
	return sphere_center.distance_to(point) < radius
