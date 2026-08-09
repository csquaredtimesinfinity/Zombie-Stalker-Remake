extends Node

var astar := AStarGrid2D.new()

func setup(wall_cells: Array[Vector2i]) -> void:
	astar.clear()
	astar.region = Rect2i(
		Vector2i.ZERO,
		LevelUtils.SCREEN_TILES
	)

	astar.cell_size = Vector2(
		LevelUtils.TILE_SIZE,
		LevelUtils.TILE_SIZE
	)

	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	
	astar.update()

	for cell in wall_cells:
		if astar.is_in_boundsv(cell):
			print(cell)
			astar.set_point_solid(cell, true)
		else:
			print("Barrier outside grid: ", cell)
	
	print(astar.get_point_data_in_region(astar.region))
	return


#func find_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
#	return astar.get_id_path(start, end, true)
func find_path(start_cell: Vector2i, end_cell: Vector2i) -> Array[Vector2i]:

	var astar_path := astar.get_id_path(start_cell, end_cell)

	var path: Array[Vector2i] = []

	for cell in astar_path:
		path.append(cell)

	return path
	
func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		float(world_pos.x / LevelUtils.TILE_SIZE),
		float((world_pos.y + 4) / LevelUtils.TILE_SIZE)
		)

func cell_to_world(cell_pos: Vector2i) -> Vector2:
	return Vector2(cell_pos) * LevelUtils.TILE_SIZE \
		+ Vector2.ONE * LevelUtils.TILE_SIZE / 2.0
