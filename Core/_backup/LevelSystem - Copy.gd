extends Node


# PURPOSE:
# Handles level serialization, loading, saving, and screen construction.
#
# RESPONSIBILITIES:
# - Load/save level JSON files
# - Convert JSON data into TileMap and entity instances
# - Provide utility functions for coordinate conversion
# - Generate stable IDs for persistent world entities
#
# TODO:
# Consider splitting into:
# - LevelSerializer (JSON load/save)
# - LevelBuilder (TileMap/entity construction)
# - LevelUtils (coordinate helpers)
# if complexity continues to grow.

const TILE_SIZE = 16



#static var entity_scenes := {
	#EntityType.HEALTH_PICKUP: preload("res://Assets/Pickups/Health/health.tscn"),
	#EntityType.AMMO_PICKUP: preload("res://Assets/Pickups/Ammo/ammo.tscn"),
	#EntityType.KEY_PICKUP: preload("res://Assets/Pickups/Key/key.tscn"),
	#EntityType.DOOR: preload("res://Assets/scenes/door.tscn"),
	#EntityType.PLAYER_START: preload("res://Assets/scenes/player_start.tscn"),
	#EntityType.END_OF_LEVEL: preload("res://Assets/scenes/level_end_portal.tscn"),
	#EntityType.ENEMY: preload("res://Assets/scenes/enemies/zombie.tscn")
#}

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

func apply_screen_to_layers(
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
					var entity_scene = EntityDatabase.get_scene(type)
				
					match type:
						EntityDatabase.EntityType.PLAYER_START:
							_setup_entity(entity_scene, entity, world_pos, entities_parent)
							pass
						
						EntityDatabase.EntityType.AMMO_PICKUP, \
						EntityDatabase.EntityType.HEALTH_PICKUP, \
						EntityDatabase.EntityType.KEY_PICKUP:
							if not GameManager.is_pickup_collected(entity["id"]):
								_setup_entity(entity_scene, entity, world_pos, entities_parent)
						
						EntityDatabase.EntityType.DOOR:
							# Skip spawning doors that have already been unlocked.
							if not GameManager.is_door_unlocked(entity["id"]):
								_setup_entity(entity_scene, entity, world_pos, entities_parent)
						
						############################################################
						# ENEMY
						############################################################
						EntityDatabase.EntityType.ENEMY:
							var zombie = entity_scene.instantiate()
							zombie.position = world_pos
							root_node.add_child(zombie)
								
						_:
							_setup_entity(entity_scene, entity, world_pos, entities_parent)	
						
							
func _setup_entity(scene: PackedScene, data: Dictionary, position: Vector2, parent) -> void:
	var instance = scene.instantiate()
	instance.position = position
	
	if data.has("id"):
		if "id" in instance:
			instance.id = data["id"]
		elif "pickup_id" in instance:
			instance.pickup_id = data["id"]
			
	parent.add_child(instance)

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
			entity["id"] = id_for_entity(screen_key, entity["cell"], str(entity["type"])) 
				
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(level_data, "\t")) # with tabs
		file.close()

static func id_for_entity(screen, cell, type) -> String:
	return "{screen}{cell}{type}".format(
		{
			"screen": screen, "cell": cell, "type": type
		}
	)

static func _clean_and_pad_2(s: String) -> String:
	var regex := RegEx.new()
	regex.compile("[^0-9]")
	var numbers := regex.sub(s, "", true)  # remove non-digits
	var value := int(numbers) if numbers != "" else 0
	return "%02d" % value

static func _generate_entity_id(screen_key: String, entity: Dictionary) -> String:
	var cell_str = entity.get("cell", "unknown")
	var type_str = str(entity.get("type", "unknown"))
	var timestamp = str(Time.get_ticks_msec()) # ensures uniqueness
	return "%s_%s_%s_%s" % [screen_key, type_str, cell_str, timestamp]

static func _load_file(file_path: String):
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
static func load_level(path: String) -> Dictionary:
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

func serialize_grid_to_rows(grid: Array) -> Array[String]:
	var rows: Array[String] = []
	for row in grid:
		var parts: Array[String] = []
		for n in row:
			parts.append("%02d" % int(n))
		rows.append(",".join(parts))# as PackedStringArray))
	return rows
