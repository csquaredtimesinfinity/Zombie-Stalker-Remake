extends Node
class_name EntityDatabase

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

const DATA := {
	
	# PICKUPS
	EntityType.HEALTH_PICKUP: {
		&"name": "Health",
		&"category": "pickup",
		&"icon": preload("res://Game/Entities/Pickups/Health/HealthPickup.png"),
		&"scene": preload("res://Game/Entities/Pickups/Health/Health.tscn")
	},
	EntityType.AMMO_PICKUP: {
		&"name": "Ammo",
		&"category": "pickup",
		&"icon": preload("res://Game/Entities/Pickups/Ammo/AmmoPickup.png"),
		&"scene": preload("res://Game/Entities/Pickups/Ammo/Ammo.tscn")
	},
	
	EntityType.KEY_PICKUP: {
		&"name": "Key",
		&"category": "pickup",
		&"icon": preload("res://Game/Entities/Pickups/Key/KeyPickup.png"),
		&"scene": preload("res://Game/Entities/Pickups/Key/Key.tscn")
	},
	
	# Non-pickup Entities
	EntityType.DOOR: {
		&"name": "Door",
		&"category": "prop",
		&"icon": preload("res://Game/Entities/Door/Door.png"),
		&"scene": preload("res://Game/Entities/Door/Door.tscn")
	},
	
	EntityType.PLAYER_START: {
		&"name": "PlayerStart",
		&"category": "marker",
		&"icon": preload("res://Game/LevelMarkers/PlayerStart/start_tile.png"),
		&"scene": preload("res://Game/LevelMarkers/PlayerStart/player_start.tscn")
	},
	
	EntityType.END_OF_LEVEL: {
		&"name": "EndOfLevel",
		&"category": "marker",
		&"icon": preload("res://Game/LevelMarkers/EndOfLevel/EndOfLevel.png"),
		&"scene": preload("res://Game/LevelMarkers/EndOfLevel/EndOfLevel.tscn")
	},
	
	EntityType.ENEMY: {
		&"name": "ZombieSpawn",
		&"category": "marker",
		&"icon": preload("res://Game/LevelMarkers/EnemySpawn/ZombieSpawn.png")
	}
}

static func is_entity_in_category(entity_type, category: String) -> bool:
	return entity_type in get_entities(category)

static func get_entities(category := ""):
	if category == "":
		return DATA
		
	var filtered = {}
	
	for e in DATA:
		var entity = DATA[e]
		
		if entity.get("category", "") == category:
			filtered[e] = entity
			
	return filtered

static func get_icon(type) -> Texture2D:
	return DATA[type].icon

static func get_scene(type) -> PackedScene:
	if not DATA.has(type):
		push_error("Unknown EntityType: " + str(type))
		return null

	var entry = DATA[type]

	if entry.has("scene") and entry.scene != null:
		return entry.scene
	
	push_error("Type: " + EntityType.find_key(type) + " does not have a scene defined")
	return null
	
