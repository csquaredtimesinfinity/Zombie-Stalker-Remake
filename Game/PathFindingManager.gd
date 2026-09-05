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
#func find_path(start_cell: Vector2i, end_cell: Vector2i) -> Array[Vector2i]:
	#for y in LevelUtils.SCREEN_TILES.y:
		#for x in LevelUtils.SCREEN_TILES.x:
			#var cell := Vector2i(x, y)
			#var crowd_cost := get_crowd_cost(cell)
			#astar.set_point_weight_scale(cell, 1.0 + crowd_cost)
	#
	#var astar_path := astar.get_id_path(start_cell, end_cell)
	#
	#var path: Array[Vector2i] = []
	#
	#for cell in astar_path:
		#path.append(cell)
	#
	#return path

func get_chase_path(
	start: Vector2,
	target: Vector2,
	requesting_zombie: Zombie
) -> Array[Vector2i]:

	var zombies : Array[Node] = get_tree().get_nodes_in_group("zombies")

	var start_cell := world_to_cell(start)
	var target_cell := world_to_cell(target)

	for y in LevelUtils.SCREEN_TILES.y:
		for x in LevelUtils.SCREEN_TILES.x:
			var cell := Vector2i(x, y)

			var crowd_cost := get_crowd_cost(
				cell,
				zombies,
				requesting_zombie
			)
			astar.set_point_weight_scale(
					cell,
					1.0
				)
			if crowd_cost > 0.0:
				astar.set_point_weight_scale(
					cell,
					1.0 + crowd_cost
				)
				#print("CELL: ", cell, " COST: ", crowd_cost)

	var astar_path := astar.get_id_path(
		start_cell,
		target_cell
	)

	var path: Array[Vector2i] = []

	for cell in astar_path:
		path.append(cell)

	return path
#
#func get_chase_path(
	#start: Vector2,
	#target: Vector2,
	#requesting_zombie: Node2D
#) -> Array[Vector2i]:
#
	#var start_cell := world_to_cell(start)
	#var target_cell := world_to_cell(target)
#
	#for y in LevelUtils.SCREEN_TILES.y:
		#for x in LevelUtils.SCREEN_TILES.x:
			#var cell := Vector2i(x, y)
			#astar.set_point_weight_scale(cell, 1.0)
#
	#var test_cell := Vector2i(5, 5)
	#astar.set_point_weight_scale(test_cell, 2.0)
	#test_cell = Vector2i(6, 5)
	#astar.set_point_weight_scale(test_cell, 2.0)
	#test_cell = Vector2i(7, 5)
	#astar.set_point_weight_scale(test_cell, 2.0)
	#
	#var astar_path := astar.get_id_path(start_cell, target_cell)
#
	#return astar_path

func get_crowd_cost(
	cell: Vector2i,
	zombies: Array[Node],
	requesting_zombie: Node2D
) -> float:

	var cost := 0.0

	for zombie in zombies:
		if zombie == requesting_zombie:
			continue

		var zombie_cell := world_to_cell(zombie.global_position)
		var distance := cell.distance_to(zombie_cell)

		if distance < 1.0:
			cost += 4.0
		elif distance < 2.0:
			cost += 2.0
		elif distance < 3.0:
			cost += 1.0

	return cost
	
func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		float(world_pos.x / LevelUtils.TILE_SIZE),
		float((world_pos.y + 4) / LevelUtils.TILE_SIZE)
		)

func cell_to_world(cell_pos: Vector2i) -> Vector2:
	return Vector2(cell_pos) * LevelUtils.TILE_SIZE \
		+ Vector2.ONE * LevelUtils.TILE_SIZE / 2.0
