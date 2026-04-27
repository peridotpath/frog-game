extends Node3D

var last_tick: int = 0

@export var Terrain: MeshInstance3D
@export var Cursor: DecalCompatibility
@export var Main: Node3D

func _process(delta: float):
	last_tick += 1
	if (last_tick > 10):
		last_tick = 0
		_process_vertex_cubes()
		
func _process_vertex_cubes():
	for n in get_children():
		remove_child(n)
		n.queue_free()
	if (Cursor.BrushMode == Cursor.BRUSH_MODE.Place):
		return
		
	#var mdt = MeshDataTool.new()
	#mdt.create_from_surface(Terrain.mesh, 0)
	#var terrain_loc = Terrain.global_transform
	#
	#var arrays = Terrain.mesh.surface_get_arrays(0)
	#for v in range(mdt.get_vertex_count()):
		#var vertex:  = mdt.get_vertex(v)
		#if (Main.is_point_in_sphere(vertex * terrain_loc, Cursor.global_position, Cursor.size[0]/2)):
	# 1. Create the MeshInstance3D node
	var mesh_instance = MeshInstance3D.new()
	# 2. Create the specific mesh shape (e.g., BoxMesh)
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1, 1, 1) # Size 1x1x1
	# 3. Assign the mesh to the instance
	mesh_instance.mesh = box_mesh
	# 4. Position the mesh in the world
	add_child(mesh_instance)

	var terrain_loc = Terrain.global_transform
	#
	var arrays = Terrain.mesh.surface_get_arrays(0)
	
	var vertices = arrays[Mesh.ARRAY_VERTEX]
	print("cursor!")
	print(Cursor.global_position)
	var locale = Terrain._find_vertices_in_circle(Vector2(Cursor.global_position.x, Cursor.global_position.z), 5)
	print(len(vertices))
	print("locale...")
	print (locale)
	var cube_pos = vertices[locale]
	print("out")

	print(cube_pos)
	
	mesh_instance.global_position = cube_pos
	
	
