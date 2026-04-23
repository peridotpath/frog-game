extends MeshInstance3D

@export var subdivides : int = 50
@export var mesh_size: Vector2 = Vector2(100.0, 100.0)

func _ready():
	_generate_terrain()

func _generate_terrain():

	var plane = PlaneMesh.new()
	plane.subdivide_depth = subdivides
	plane.subdivide_width = subdivides

	var plane_mesh = plane

	# Set width (X) based on mesh_size.x, calculate height (Z) based on aspect ratio
	plane_mesh.size = Vector2(mesh_size.x, mesh_size.y)

	# 3. Get mesh data and modify vertices
	generate_terrain_from_heightmap(plane_mesh)

## Step 2 & 3: Generate Geometry from Heightmap Data
func generate_terrain_from_heightmap(plane_mesh: PlaneMesh):
	var mesh_data = plane_mesh.get_mesh_arrays()

	# We are primarily interested in the vertices array
	var vertices: PackedVector3Array = mesh_data[Mesh.ARRAY_VERTEX]

	if vertices.is_empty():
		push_error("The base plane mesh has no vertices to modify.")
		return

	###DEFORMATION GOES HERE

	# 5. Create a new Mesh resource with the modified vertex data
	var new_mesh = ArrayMesh.new()
	# Use the same surface primitive type (TRIANGLES) and the modified data array
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)

	# Calculate smooth normals for the new mesh geometry
	var tool = SurfaceTool.new()
	tool.create_from(new_mesh, 0)
	tool.generate_normals()
	var final_mesh = tool.commit()

	# Assign the newly generated mesh to the MeshInstance3D node
	self.mesh = final_mesh
	
	create_trimesh_collision()
	for n in get_children():
		if(n is StaticBody3D):
			n.set_collision_layer_value(2, true)
