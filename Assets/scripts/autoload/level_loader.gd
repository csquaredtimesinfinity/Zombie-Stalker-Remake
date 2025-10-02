extends Node

const TILE_SIZE = 16

enum EntityType {
	EMPTY = -1,
	# Pickups
	AMMO_PICKUP = 0,
	HEALTH_PICKUP = 1,
	KEY_PICKUP = 2,
	# Entities
	PLAYER_START = 20,
	END_OF_LEVEL = 21,
	ENEMY = 22
}

var entity_scenes := {
	EntityType.HEALTH_PICKUP: preload("res://Assets/scenes/pickups/health.tscn"),
	EntityType.AMMO_PICKUP: preload("res://Assets/scenes/pickups/ammo.tscn"),
	EntityType.KEY_PICKUP: preload("res://Assets/scenes/pickups/key.tscn"),
	EntityType.PLAYER_START: preload("res://Assets/scenes/player.tscn"),
	EntityType.END_OF_LEVEL: preload("res://Assets/scenes/level_end_portal.tscn"),
	EntityType.ENEMY: preload("res://Assets/scenes/enemies/zombie.tscn")
}

# -----------------------
# Utility helpers
# -----------------------
static func vec2i_to_str(v: Vector2i) -> String:
	return "%d,%d" % [v.x, v.y]

static func str_to_vec2i(s: String) -> Vector2i:
	var parts = s.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))
	
static func cell_to_world(cell: String):
	var vec: Vector2i = str_to_vec2i(cell)
	return Vector2(vec.x * TILE_SIZE, vec.y * TILE_SIZE)

static func apply_screen_to_layers(
	level_data :Dictionary, screen_key :String, 
	tile_layer :TileMapLayer, _marker_layer :TileMapLayer = null) -> void:
		if not level_data.has("screens"):
			push_error("apply_screen_to_layers: No 'screens' key in level_data")
			return
		if not level_data["screens"].has(screen_key):
			push_error("apply_screen_to_layers: Screen %s not found" % screen_key)
			return
			
		var screen_data = level_data["screens"][screen_key]
		
		# Clear old tiles
		tile_layer.clear()
		if _marker_layer:
			_marker_layer.clear()
		
		# Apply tiles
		if screen_data.has("tiles"):
			var tiles: Array = screen_data["tiles"]
			for y in range(tiles.size()):
				for x in range(tiles[y].size()):
					var tile_id :int = int(tiles[y][x])
					if tile_id >= 0:
						tile_layer.set_cell(Vector2i(x,y), tile_id, Vector2i.ZERO)
		
		if screen_data.has("entities"):
			var entities = screen_data["entities"]
			if _marker_layer:
				for entity in entities:
					var cell: Vector2i = str_to_vec2i(entity["cell"])
					var type: int = int(entity["type"])
					# use entity type enum mapping here if needed
					_marker_layer.set_cell(cell, type, Vector2i.ZERO)
			else:
				for entity in entities:
					var world_pos: Vector2i = cell_to_world(entity["cell"])
					var type: int = int(entity["type"])
					
					match type:
						LevelLoader.EntityType.PLAYER_START:
							pass # spawn player?
						LevelLoader.EntityType.HEALTH_PICKUP:
							pass 
						LevelLoader.EntityType.AMMO_PICKUP:
							pass
						LevelLoader.EntityType.KEY_PICKUP:
							pass
						LevelLoader.EntityType.END_OF_LEVEL:
							pass
		# Marker layer is only for editor visualization (optional in runtime)
		if _marker_layer && screen_data.has("entities"):
			for entity in screen_data["entities"]:
				var cell: Vector2i = str_to_vec2i(entity["cell"])
				var type: int = int(entity["type"])
				# use entity type enum mapping here if needed
				_marker_layer.set_cell(cell, type, Vector2i.ZERO)

# -----------------------
# Saving (used by editor)
# -----------------------
# LevelLoader.gd (autoload)

var current_level_data: Dictionary = {}

func save_level(path: String, level_data: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(level_data, "\t")) # with tabs
		file.close()

func _load_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Could not open level file: %s" % file_path)
		return

	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(text) != OK:
		push_error("Failed to parse JSON")
		return

	return json.get_data()

# -----------------------
# Loading (used by editor)
# -----------------------
func load_level_for_editor(file_path: String, tilemap: TileMapLayer, markers_layer: TileMapLayer) -> void:
	var data = _load_file(file_path)
	
	# Clear old
	tilemap.clear()
	markers_layer.clear()
	
	for tile_entry in data.get("tiles", []):
		var pos = str_to_vec2i(tile_entry["pos"])
		var id = tile_entry["id"]
		tilemap.set_cell(pos, id, Vector2i(0, 0))
		
	for marker in data.get("entities", []):
		var pos = str_to_vec2i(marker["pos"])
		var id = marker["id"]
		markers_layer.set_cell(pos, id, Vector2i(0, 0))
	

# -----------------------
# Loading (used by game)
# -----------------------
func load_level(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Level file not found: %s" % path)
		return {}
		
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var result = JSON. parse_string(content)
	if typeof(result) == TYPE_DICTIONARY:
		return result
	else:
		push_error("Failed to parse JSON: %s" % path)
		return {}
