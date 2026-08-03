extends Control

class_name LevelEditor

@onready var tilemap: TileMapLayer = $TileMapLayer
@onready var markers_layer: TileMapLayer = $MarkersLayer
@onready var ui: CanvasLayer = $LevelEditorUI
 # 6 across, 4 down

var current_screen := Vector2i(0, 0)

var level_data_file :String = "res://Assets/levels/Level1.json"

# Level data dictionary
var level_data = {
	"screens": {
		"(0,0)": {
				"entities": []
		}
	}
}

var current_tile_id: int = 0
var current_entity_type: EntityDatabase.EntityType = EntityDatabase.EntityType.EMPTY

# Used to hold down mouse buttons to paint tiles or entities
var is_painting_tiles := false
var is_painting_entity := false

"""
1. Initialize level editor dropdowns for selecting tiles and entities.
2. Loads level data and updates the TileMapLayers for tiles and entities.
"""
func _ready():
	ui.tile_selected.connect(_on_tile_selected)
	ui.entity_selected.connect(_on_entity_selected)
	ui.move_screen.connect(_on_move_screen)
	ui.save_level.connect(_on_save_level)
	ui.fill_screen.connect(_on_fill_screen)
	
#	%CurrentScreenCoords.text = _get_current_screen_coords()
	_update_screen_buttons()
	
	# Connect dropdown changes
	level_data = LevelSystem.load_level(level_data_file)
	LevelBuilder.apply_screen_to_layers(
		level_data, _get_current_screen_coords(), tilemap, markers_layer)
		
	queue_redraw()

func _input(event: InputEvent):
	if event.is_action_pressed("quit"):
		GameManager.change_scene_to_main_menu()
		
	if event is InputEventMouseButton:
		# Restrict painting to the tile area (exclude HUD)
		if (event.position.y < LevelUtils.SCREEN_SIZE.y * LevelUtils.TILE_SIZE * 4  
			&& event.position.x < LevelUtils.SCREEN_SIZE.x * LevelUtils.TILE_SIZE * 4):
			if event.button_index == MOUSE_BUTTON_LEFT:
				is_painting_tiles = event.pressed
				_place_tile(event.position)
				print(event.position)
				
			if event.button_index == MOUSE_BUTTON_RIGHT:
				is_painting_entity = event.pressed
				if event.pressed:
					_place_entity(event.position)
				
	# Keep painting while moving mouse
	if event is InputEventMouseMotion and is_painting_tiles:
		_place_tile(event.position)
	if event is InputEventMouseMotion and is_painting_entity:
		_place_entity(event.position)

func _init_screen(screen :String) -> void:
	# Initialize with empty tiles (fill with -1 meaning "no tile")
	level_data["screens"][screen] = {
		"tiles": [],
		"entities": []
	}
	for y in range(LevelUtils.SCREEN_SIZE.y): # e.g. 1L0
		var row = []
		for x in range(LevelUtils.SCREEN_SIZE.x): # e.g. 20
			row.append(-1)
		level_data["screens"][screen]["tiles"].append(row)

func _get_current_screen_tiles() -> Array:
	return level_data["screens"][_get_current_screen_coords()]["tiles"]

func _place_tile(mouse_pos: Vector2):
	var local_pos = tilemap.to_local(mouse_pos)
	var cell: Vector2i = tilemap.local_to_map(local_pos)
	
	if cell.y >= LevelUtils.SCREEN_TILES.y || cell.x >= LevelUtils.SCREEN_TILES.x:
		return

	if current_tile_id >= 0:
		# Paint visually
		tilemap.set_cell(cell, current_tile_id, Vector2i(0, 0))

		# Initialize screen in level_data if it does not exist yet
		var screen_coords = _get_current_screen_coords() 
		if not level_data["screens"].has(screen_coords):
			_init_screen(screen_coords)

		# Store tile directly in array
		_set_tile(cell, current_tile_id)

func _place_entity(mouse_pos: Vector2i) -> void:
	var local_pos: Vector2i = markers_layer.to_local(mouse_pos)
	var cell: Vector2i = markers_layer.local_to_map(local_pos)
	
	if cell.y >= LevelUtils.SCREEN_TILES.y || cell.x >= LevelUtils.SCREEN_TILES.x:
		return

	var screen_coords = _get_current_screen_coords()
	if not level_data["screens"].has(screen_coords):
		_init_screen(screen_coords)
	
	if !_can_place_entity(cell):
		return

	# Remove old entity in this cell (if any)
	var entities = level_data["screens"][screen_coords].get("entities", [])
	for i in range(entities.size()):
		var entity = entities[i]
		if LevelUtils.str_to_vec2i(entity["cell"]) == cell:
			entities.remove_at(i)
			break

	# Clear visual marker
	markers_layer.set_cell(cell)

	if current_entity_type != EntityDatabase.EntityType.EMPTY:
		var new_entity = {
			"cell": str(cell),
			"type": str(current_entity_type),
			"id": LevelUtils.id_for_entity(
				screen_coords, LevelUtils.vec2i_to_str(cell), str(current_entity_type))
		}

		match current_entity_type:
			EntityDatabase.EntityType.PLAYER_START:
				set_player_start(screen_coords, cell)
				
			_: # Default: normal entity
				entities.append(new_entity)

		# Draw marker in layer
		markers_layer.set_cell(cell, current_entity_type, Vector2i(0, 0))
		print("Placed entity: ", new_entity)

func set_player_start(screen_key: String, cell: Vector2i) -> void:
	# Remove previous player start from its screen entities
	if level_data.has("player_start"):
		var old_screen = level_data["player_start"]["screen"]
		var old_cell = LevelUtils.str_to_vec2i(level_data["player_start"]["cell"])
		
		# 1. Clear marker if same screenn
		if level_data["player_start"]["screen"] == screen_key:
			markers_layer.set_cell(old_cell)
		
		# 2. Remove old entity from its screen
		if level_data["screens"].has(old_screen):
			var entities: Array = level_data["screens"][old_screen].get("entities", [])
			
			# remove any old player_start entity
			for i in range(entities.size() - 1, -1, -1):
				if int(entities[i]["type"]) == EntityDatabase.EntityType.PLAYER_START:
					entities.remove_at(i)

	# Write new player_start to the dictionary
	level_data["player_start"] = {
		"screen": screen_key,
		"cell": "%s,%s" % [cell.x, cell.y]   # keep format consistent with your JSON
	}

	# Add back into the new screen entity list
	var new_entity = {
		"type": EntityDatabase.EntityType.PLAYER_START,
		"cell": "%s,%s" % [cell.x, cell.y]
	}

	level_data["screens"][screen_key]["entities"].append(new_entity)


func pickup_type_to_name(t: EntityDatabase.EntityType) -> String:
	match t:
		EntityDatabase.EntityType.HEALTH_PICKUP: return "health"
		EntityDatabase.EntityType.AMMO_PICKUP: return "ammo"
		EntityDatabase.EntityType.KEY_PICKUP: return "key"
		_: return "unknown"

func _update_screen_buttons() -> void:
	ui.set_screen_button_states(current_screen, LevelUtils.MAP_SCREENS)	

func _get_current_screen_coords() -> String:
	return str(current_screen.x) + "," + str(current_screen.y)

func _load_current_screen() -> void:
	var screen_coords = _get_current_screen_coords()
	LevelBuilder.apply_screen_to_layers(level_data, screen_coords, tilemap, markers_layer)
	
func _on_tile_selected(id: int) -> void:
	# store which tile the user picked
	current_tile_id = id
	is_painting_tiles = false
	
func _on_entity_selected(id: int) -> void:
	current_entity_type = id
	is_painting_tiles = false
			
func _on_move_screen(dir: Vector2i) -> void:
	var new_screen = current_screen + dir

	if new_screen.x < 0 or new_screen.x >= LevelUtils.SCREEN_SIZE.x:
		return
	if new_screen.y < 0 or new_screen.y >= LevelUtils.SCREEN_SIZE.y:
		return

	current_screen = new_screen

	_load_current_screen()
	_update_screen_buttons()
	
func _on_fill_screen() -> void:
	if current_tile_id == -1:
		return

	# Initialize screen in level_data if it does not exist yet
	var screen_coords = _get_current_screen_coords()
	if not level_data["screens"].has(screen_coords):
		_init_screen(screen_coords)
		
	# Update level_data Dictionary
	for y in range(LevelUtils.SCREEN_SIZE.y): # e.g. 10
		for x in range(LevelUtils.SCREEN_SIZE.x): # e.g. 20
			_set_tile(Vector2i(x, y), current_tile_id)
		
	# Update TileMapLayer
	for y in range(LevelUtils.SCREEN_SIZE.y):
		for x in range(LevelUtils.SCREEN_SIZE.x):
			tilemap.set_cell(Vector2i(x,y), current_tile_id, Vector2i(0,0))
				
func _on_save_level() -> void:
	LevelSerializer.save_level("res://Assets/levels/Level1.json", level_data)
	
func _get_tile(cell: Vector2i) -> int:
	var screen_coords = _get_current_screen_coords()
	if not level_data["screens"].has(screen_coords):
		_init_screen(screen_coords)
	return int(level_data["screens"][screen_coords]["tiles"][cell.y][cell.x])

func _set_tile(cell: Vector2i, tile_id: int) -> void:
	var screen_coords = _get_current_screen_coords()
	if not level_data["screens"].has(screen_coords):
		_init_screen(screen_coords)
	level_data["screens"][screen_coords]["tiles"][cell.y][cell.x] = tile_id
	
	
func _can_place_entity(cell: Vector2i) -> bool:
	return _get_tile(cell) not in TileDatabase.get_entities("barrier")
