# LevelLoader.gd
extends Node

var tile_size := Vector2i(16, 16)

enum EntityType {
	# Pickups
	HEALTH_PICKUP, 
	AMMO_PICKUP, 
	KEY_PICKUP, 
	
	# Entities
	PLAYER_START = 20, 
	END_OF_LEVEL = 21, 
	ENEMY = 22
}

func load_level(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Could not open level file: " + file_path)
		return {}
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("Failed to parse level file: " + str(error))
		return {}
	
	return json.data


func build_tilemap(tilemap: TileMapLayer, screen_key: String, level_data: Dictionary):
	tilemap.clear()
	if not level_data.has("screens"):
		return
	if not level_data["screens"].has(screen_key):
		return
	
	var rows = level_data["screens"][screen_key]
	for y in range(rows.size()):
		for x in range(rows[y].size()):
			var tile_id = rows[y][x]
			if tile_id != null:
				tilemap.set_cell(Vector2i(x, y), tile_id, Vector2i(0,0))


func build_entity_markers(marker_layer: TileMapLayer, screen_key: String, level_data: Dictionary, marker_ids: Dictionary):
	marker_layer.clear()
	if not level_data.has("entities"):
		return
	
	for entity in level_data["entities"]:
		var entity_screen = str(entity["screen"][0]) + "," + str(entity["screen"][1])
		if entity_screen == screen_key:
			var cell = Vector2i(entity["cell"][0], entity["cell"][1])
			var tile_id = marker_ids[entity["type"]]
			marker_layer.set_cell(cell, tile_id, Vector2i(0,0))
