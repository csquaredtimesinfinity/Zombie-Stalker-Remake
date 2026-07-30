extends Node
class_name TileDatabase

enum TileType {
	# BARRIERS
	GREY_WALL = 0,
	BLUE_WALL = 1,
	BUSH = 2,
	
	# Entities
	TILE_FLOOR = 4,
	GRASS = 5,
	HEALTH_REGENERATOR = 6
}

const DATA := {
	
	# PICKUPS
	TileType.GREY_WALL: {
		&"name": "GreyWall",
		&"category": "barrier",
		&"icon": preload("res://Assets/Sprites/Tiles/GreyWall.png")
	},
	TileType.BLUE_WALL: {
		&"name": "BlueWall",
		&"category": "barrier",
		&"icon": preload("res://Assets/Sprites/Tiles/BlueWall.png")
	},
	
	TileType.BUSH: {
		&"name": "Bush",
		&"category": "barrier",
		&"icon": preload("res://Assets/Sprites/Tiles/Bush.png")
	},
	
	# Non-pickup Entities
	TileType.TILE_FLOOR: {
		&"name": "TileFloor",
		&"category": "ground",
		&"icon": preload("res://Assets/Sprites/Tiles/Floor.png")
	},
	
	TileType.GRASS: {
		&"name": "Grass",
		&"category": "ground",
		&"icon": preload("res://Assets/Sprites/Tiles/Grass.png")
	},
	
	TileType.HEALTH_REGENERATOR: {
		&"name": "HealthRegenerator",
		&"category": "ground",
		&"icon": preload("res://Assets/Sprites/Tiles/HealthRegenerators.png")
	}
}

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
