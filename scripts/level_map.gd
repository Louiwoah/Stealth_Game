extends TileMapLayer
class_name LevelMap

var astar := AStarGrid2D.new()


func _ready() -> void:
	#sets up grid
	astar.region = get_used_rect()
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER  
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()

	
	for x in range(astar.region.position.x, astar.region.end.x):
		for y in range(astar.region.position.y, astar.region.end.y):
			var cell := Vector2i(x, y)
			if not is_walkable(cell):
				astar.set_point_solid(cell)

	print_graph()   #debug


#
func is_walkable(cell: Vector2i) -> bool:
	var data := get_cell_tile_data(cell)
	if data == null:
		return false  
	return data.get_collision_polygons_count(0) == 0



func print_graph() -> void:
	for y in range(astar.region.position.y, astar.region.end.y):
		var row := ""
		for x in range(astar.region.position.x, astar.region.end.x):
			row += "#" if astar.is_point_solid(Vector2i(x, y)) else "."
		print(row)
		
func find_path(from_world: Vector2, to_world: Vector2) -> PackedVector2Array:
	var from_cell := local_to_map(to_local(from_world)) 
	var to_cell := local_to_map(to_local(to_world))
	var route := PackedVector2Array()
	if not astar.is_in_boundsv(from_cell) or not astar.is_in_boundsv(to_cell):
		return route
	for cell in astar.get_id_path(from_cell, to_cell, true):  
		route.append(to_global(map_to_local(cell))) 
	return route
