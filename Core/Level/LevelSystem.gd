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

func apply_screen(screen_key: String, tile_layer, marker_layer, entities_parent, root_node) -> void:
	LevelBuilder.apply_screen_to_layers(
		current_level_data,
		screen_key,
		tile_layer,
		marker_layer,
		entities_parent,
		root_node
	)

func get_player_start() -> Dictionary:
	return current_level_data["player_start"]
