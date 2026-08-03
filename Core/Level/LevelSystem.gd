extends Node

var current_level_data: Dictionary

func load_level(path: String) -> Dictionary:
	current_level_data = LevelSerializer.load_level(path)
	return current_level_data

func get_tile(screen_key: String, x: int, y: int) -> int:
	return current_level_data["screens"][screen_key][y][x]

func set_tile(screen_key: String, x: int, y: int, tile_id: int) -> void:
	current_level_data["screens"][screen_key][y][x] = tile_id

func get_entities(screen_key: String) -> Array:
	return current_level_data["screens"][screen_key].get("entities", [])
	
func get_barriers(screen_key: String) -> Array[Vector2i]:
	var barriers : Array[Vector2i] = []
	print(TileDatabase.get_entities("barrier"))
	print(current_level_data["screens"][screen_key]["tiles"])
	for y in range(10):
		for x in range(20):
			var tile = int(current_level_data["screens"][screen_key]["tiles"][y][x])
			print(tile)
			if (tile == TileDatabase.TileType.GREY_WALL || 
					tile == TileDatabase.TileType.BLUE_WALL || 
					tile == TileDatabase.TileType.BUSH):
				barriers.append(Vector2i(x, y))
			#if (int(current_level_data["screens"][screen_key]["tiles"][y][x]) in 
					#TileDatabase.get_entities("barrier")):
				#barriers.append(Vector2i(x, y))
	print("Number of barriers: %d" % barriers.size())
	return barriers

func apply_screen(
	screen_key: String, tile_layer, marker_layer, 
	entities_parent, root_node, characters_parent) -> void:
	LevelBuilder.apply_screen_to_layers(
		current_level_data,
		screen_key,
		tile_layer,
		marker_layer,
		entities_parent,
		root_node,
		characters_parent
	)

func get_player_start() -> Dictionary:
	return current_level_data["player_start"]
