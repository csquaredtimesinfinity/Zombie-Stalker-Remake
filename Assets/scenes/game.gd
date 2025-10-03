extends Node2D

@onready var tilemap :TileMapLayer = $TileMapLayer

var level_data

func _ready() -> void:
	level_data = LevelLoader.load_level("res://Assets/levels/Level1.json")
	var player_start = level_data["player_start"]
	LevelLoader.apply_screen_to_layers(
		level_data, player_start["screen"], tilemap, null, $Entities)
	
	var player_position = LevelLoader.cell_to_world(player_start["cell"])
	var player = preload("res://Assets/scenes/player.tscn").instantiate()
	player.position = player_position
	add_child(player)
