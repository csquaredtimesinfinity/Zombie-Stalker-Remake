class_name LevelBuilder

static func _setup_entity(
	scene: PackedScene,
	data: Dictionary,
	position: Vector2,
	parent: Node
):
	var instance = scene.instantiate()
	instance.position = position
	
	if data.has("id"):
		if "id" in instance:
			instance.id = data["id"]
		#elif "pickup_id" in instance:
			#instance.pickup_id = data["id"]
	
	parent.add_child(instance)

static func apply_screen_to_layers(
	level_data: Dictionary,
	screen_key: String,
	tile_layer: TileMapLayer,
	marker_layer: TileMapLayer = null,
	entities_parent: Node = null,
	root_node: Node2D = null,
	characters_parent: Node2D = null) -> void:
	
	if not level_data.has("screens"):
		push_error("No screens in level_data")
		return
	
	if not level_data["screens"].has(screen_key):
		push_error("Screen not found: %s" % screen_key)
		return
		
	var screen: Dictionary = level_data["screens"][screen_key]
	
	# clear
	tile_layer.clear()
	if marker_layer:
		marker_layer.clear()
		
	# tiles
	if screen.has("tiles"):
		var tiles: Array = screen["tiles"]
		for y in range(tiles.size()):
			for x in range(tiles[y].size()):
				var id := int(tiles[y][x])
				if id >= 0:
					tile_layer.set_cell(Vector2i(x, y), id, Vector2i.ZERO)
					
	# entities
	if screen.has("entities"):
		var entities = screen["entities"]
		
		if marker_layer:
			for entity in entities:
				var cell: Vector2i = LevelUtils.str_to_vec2i(entity["cell"])
				var type: int = int(entity["type"])
				# use entity type enum mapping here if needed
				marker_layer.set_cell(cell, type, Vector2i.ZERO)
		else:
		
			for entity in entities:
				var world_pos: Vector2i = LevelUtils.cell_to_world(entity["cell"])
				var half_tile = tile_layer.tile_set.tile_size / 2
				world_pos += half_tile
				var cell: Vector2i = LevelUtils.str_to_vec2i(entity["cell"])
				var type := int(entity["type"])
				
				var scene := EntityDatabase.get_scene(type)
				if scene == null:
					continue
					
				# PLAYER
				if type in [
					EntityDatabase.EntityType.PLAYER_START,
					EntityDatabase.EntityType.END_OF_LEVEL
					]:
					var inst := scene.instantiate()
					inst.position = world_pos
					entities_parent.add_child(inst)
					continue
				
				var entity_id = LevelUtils.id_for_entity(screen_key, LevelUtils.vec2i_to_str(cell), str(type))
				
				if type == EntityDatabase.EntityType.ENEMY && not WorldState.is_zombie_killed(entity_id):
					_setup_entity(scene, entity, world_pos, characters_parent)
					continue
					
				# Entities
				var is_interactive_entity = (
					EntityDatabase.is_entity_in_category(type, "pickup") || \
						EntityDatabase.is_entity_in_category(type, "prop"))
						
				if is_interactive_entity:
					
					if type == EntityDatabase.EntityType.DOOR:
						# Add door only if it's not unlocked
						if not WorldState.is_door_unlocked(entity_id):
							_setup_entity(scene, entity, world_pos, entities_parent)
							continue
					
							
					elif not WorldState.is_pickup_collected(entity_id):
						_setup_entity(scene, entity, world_pos, entities_parent
						)
						continue
