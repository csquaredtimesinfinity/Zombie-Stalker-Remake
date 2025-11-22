extends Node

const TILE_SIZE = 16

enum EntityType {
	EMPTY = 99,
	# Pickups
	AMMO_PICKUP = 0,
	HEALTH_PICKUP = 1,
	KEY_PICKUP = 2,
	
	# Door
	DOOR = 10,
	
	# Entities
	PLAYER_START = 20,
	END_OF_LEVEL = 21,
	ENEMY = 22
}

static var entity_scenes := {
	EntityType.HEALTH_PICKUP: preload("res://Assets/scenes/pickups/health.tscn"),
	EntityType.AMMO_PICKUP: preload("res://Assets/scenes/pickups/ammo.tscn"),
	EntityType.KEY_PICKUP: preload("res://Assets/scenes/pickups/key.tscn"),
	EntityType.DOOR: preload("res://Assets/scenes/door.tscn"),
	EntityType.PLAYER_START: preload("res://Assets/scenes/player.tscn"),
	EntityType.END_OF_LEVEL: preload("res://Assets/scenes/level_end_portal.tscn"),
	EntityType.ENEMY: preload("res://Assets/scenes/enemies/zombie.tscn")
}

var current_level_data: Dictionary = {}

############################################################
# Utility helpers
############################################################
static func vec2i_to_str(v: Vector2i) -> String:
	return "%d,%d" % [v.x, v.y]

static func str_to_vec2i(s: String) -> Vector2i:
	var parts = s.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))
	
static func cell_to_world(cell: String):
	var vec: Vector2i = str_to_vec2i(cell)
	return Vector2(vec.x * TILE_SIZE, vec.y * TILE_SIZE)
############################################################

static func apply_screen_to_layers(
	level_data :Dictionary, screen_key :String, 
	tile_layer :TileMapLayer, 
	_marker_layer :TileMapLayer = null, 
	entities_parent :Node = null, root_node :Node2D = null) -> void:
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
					# center in the cell
					var half_tile = tile_layer.tile_set.tile_size / 2
					world_pos += half_tile
					match type:
						############################################################
						# PICKUPS
						############################################################
						# HEALTH PICKUP 
						############################################################
						EntityType.HEALTH_PICKUP:
							var health = entity_scenes[type].instantiate() #preload("res://Assets/scenes/pickups/health.tscn").instantiate()
							health.pickup_id = entity["id"]
							health.position = world_pos
							entities_parent.add_child(health)
						# ---------------------------------------
						
						############################################################
						# AMMO PICKUP
						############################################################
						EntityType.AMMO_PICKUP:
							var ammo = entity_scenes[type].instantiate() #preload("res://Assets/scenes/pickups/ammo.tscn").instantiate()
							ammo.pickup_id = entity["id"]
							ammo.position = world_pos
							entities_parent.add_child(ammo)
						
						############################################################
						# KEY PICKUP
						############################################################
						EntityType.KEY_PICKUP:
							var key = entity_scenes[type].instantiate() # preload("res://Assets/scenes/pickups/key.tscn").instantiate()
							key.pickup_id = entity["id"]
							key.position = world_pos
							entities_parent.add_child(key)
						
						############################################################
						# DOOR
						############################################################
						EntityType.DOOR:
							var door = entity_scenes[type].instantiate()
							door.position = world_pos
							entities_parent.add_child(door)
							
						############################################################
						# ENEMY
						############################################################
						EntityType.ENEMY:
							var zombie = entity_scenes[type].instantiate() #preload("res://Assets/scenes/enemies/zombie.tscn").instantiate()
							zombie.position = world_pos
							root_node.add_child(zombie)
						
						############################################################
						# END OF LEVEL PORTAL
						############################################################
						EntityType.END_OF_LEVEL:
							var end_of_level = entity_scenes[type].instantiate() #preload("res://Assets/scenes/level_end_portal.tscn").instantiate()
							end_of_level.position = world_pos
							entities_parent.add_child(end_of_level)
							

#############################################################
# Saving (used by editor)
############################################################
func save_level(path: String, level_data: Dictionary) -> void:
	# Inject unique IDs into entities before saving
	for screen_key in level_data.get("screens", {}).keys():
		var screen = level_data["screens"][screen_key]
		if not screen.has("entities"):
			continue
		
		for entity in screen["entities"]:
			entity["id"] = UUID4.uuid4()
				
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(level_data, "\t")) # with tabs
		file.close()

func _generate_entity_id(screen_key: String, entity: Dictionary) -> String:
	var cell_str = entity.get("cell", "unknown")
	var type_str = str(entity.get("type", "unknown"))
	var timestamp = str(Time.get_ticks_msec()) # ensures uniqueness
	return "%s_%s_%s_%s" % [screen_key, type_str, cell_str, timestamp]

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

############################################################
# Loading (used by editor)
############################################################
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
	

############################################################
# Loading (used by game)
############################################################
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
