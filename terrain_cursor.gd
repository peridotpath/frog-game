@tool

extends DecalCompatibility

enum BRUSH_MODE {Gaus, Flatten, Smooth, Place}
enum PLACEABLE_OBJECT {Tree, Mushroom}

@export var Terrain: MeshInstance3D
@export var Camera: Camera3D
@export var Home: Node3D
@export var UIArea: ColorRect

@export var BrushSize: float
@export var BrushStr: float
@export var BrushSetHeight: float = 10

@export var BrushMode: BRUSH_MODE

@export var SelectedPlaceable: PLACEABLE_OBJECT

@export var ObjectPlacementCursor: Node3D

@export var ObjectToBePlaced: Node3D

var tree = preload("res://tree.tscn")

var mouse_left_held: bool
var mouse_right_held: bool

func _switch_cursors(is_placement: bool):
	if is_placement:
		hide()
		ObjectPlacementCursor.show()
	else:
		show()
		ObjectPlacementCursor.hide()

func _ready():
	var myTree = tree.instantiate()
	ObjectPlacementCursor = myTree
	call_deferred("add_child",ObjectPlacementCursor)

func _process(delta: float):
	if Home.BrushSize != size[0]:
		size = Vector3(Home.BrushSize, Home.BrushSize, Home.BrushSize)
		BrushSize = Home.BrushSize
	if Home.BrushStr != size[0]:
		BrushStr = Home.BrushStr
		
	var mouse_pos = get_viewport().get_mouse_position()

	if (is_mouse_in_UI(mouse_pos)):
		return
		
	_position_cursor(mouse_pos)

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		mouse_left_held = true
		_handle_deform(1)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if (BrushMode == BRUSH_MODE.Flatten):
			BrushSetHeight = _find_nearest_vertex_on_terrain().y
		else:
			_handle_deform(-1)
			mouse_right_held = true
		
func _position_cursor(mouse_pos: Vector2):

	# Project ray from camera to screen
	var ray_start = Camera.project_ray_origin(mouse_pos)
	var ray_end = ray_start + Camera.project_ray_normal(mouse_pos) * 1000
	
	# Create query parameters
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = 2
	var result = space_state.intersect_ray(query)
	if result:
		if (result.get("collider").name == "Terrain_col"):
			global_position = result.position
			ObjectPlacementCursor.global_position = result.position
		
func _find_nearest_vertex_on_terrain():
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(Terrain.mesh, 0)
	var terrain_loc = Terrain.global_transform
	var nearestVertex: Vector3 = Vector3(10000,10000,10000) 
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)
		if ((vertex * terrain_loc).distance_to(global_position) < (nearestVertex * terrain_loc).distance_to(global_position)):
			nearestVertex = vertex
	return nearestVertex
	
func _handle_deform(direction: float):
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(Terrain.mesh, 0)
	var terrain_loc = Terrain.global_transform
	if (!Terrain.mesh):
		return
	var arrays = Terrain.mesh.surface_get_arrays(0)
	var verts = arrays[Mesh.ARRAY_VERTEX]
	
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)

		if (Home.is_point_in_sphere(vertex * terrain_loc,global_position,size[0]/2)):
			var y_change = _gaussian_deform((vertex * terrain_loc).distance_to(global_position), 0, size[0]/2)
			if (BrushMode == BRUSH_MODE.Flatten):
				if (abs(vertex.y - BrushSetHeight) < 0.1):
					verts[i].y = BrushSetHeight
				if (vertex.y < BrushSetHeight):
					verts[i] = vertex + Vector3(0,y_change*1,0)
				if (vertex.y > BrushSetHeight):
					verts[i] = vertex + Vector3(0,-1*y_change*1,0)
			else:
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
	Terrain.mesh = new_mesh

	# 4. Update collision to match the new shape
	for n in Terrain.get_children():
		if(n is StaticBody3D):
			Terrain.remove_child(n)
			n.queue_free()
			
	Terrain.create_trimesh_collision()
	
	for n in Terrain.get_children():
		if(n is StaticBody3D):
			n.set_collision_layer_value(2, true)
			
func _gaussian_deform(x: float, mean: float, std_dev: float) -> float:
	var exponent = -0.5 * pow((x - mean) / std_dev, 2)
	var factor = 1.0 / (std_dev * sqrt(2.0 * PI))
	return factor * exp(exponent)

func is_mouse_in_UI(mouse_pos: Vector2) -> bool:
	return !UIArea.hidden || (mouse_pos.x < UIArea.size.x && mouse_pos.y < UIArea.size.y)

func _on_placement_item_options_item_selected(index: int) -> void:
	SelectedPlaceable = index
	match(SelectedPlaceable):
		PLACEABLE_OBJECT.Tree:
			pass
		#etc
		
