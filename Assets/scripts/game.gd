extends Node2D

@onready var tilemap :TileMapLayer = $TileMapLayer
@onready var entities :Node2D = $Entities
@onready var game_scene_root :Node2D = $"."
@onready var hud :CanvasLayer = %HUD

var current_screen: Vector2 = Vector2.ZERO

const TILE_SIZE = 16
const SCREEN_TILES = Vector2i(20, 10)
const SCREEN_SIZE = SCREEN_TILES * TILE_SIZE

var level_data
var player


func _ready() -> void:
	level_data = LevelLoader.load_level("res://Assets/levels/Level1.json")
	var player_start = level_data["player_start"]
	LevelLoader.apply_screen_to_layers(
		level_data, player_start["screen"], tilemap, null, $Entities, game_scene_root)
	
	# Spawn player controlled character
	var player_position = LevelLoader.cell_to_world(player_start["cell"])
	player = preload("res://Assets/scenes/player.tscn").instantiate()
	player.position = player_position
	add_child(player)
	level_data = LevelLoader.load_level("res://Assets/levels/Level1.json")

	# Connect player signal
	player.screen_transition.connect(_on_player_screen_transition)
	
	

func _process(delta: float) -> void:
	if Input.is_action_pressed("quit"):
		GameManager.change_scene_to_main_menu()

func _on_player_screen_transition(direction: Vector2):
	var new_screen = current_screen + direction
	var screen_key = "%d,%d" % [new_screen.x, new_screen.y]

	if not level_data["screens"].has(screen_key):
		return # hit boundary with no screen, ignore

	current_screen = new_screen
	
	var entities_to_remove = entities.get_children()
	for entity in entities_to_remove:
		entity.queue_free()
	
	LevelLoader.apply_screen_to_layers(
		level_data, screen_key, tilemap, null, entities, game_scene_root)

	# Warp player to opposite edge
	match direction:
		Vector2.LEFT:
			player.position.x = SCREEN_SIZE.x - (TILE_SIZE / 2)
		Vector2.RIGHT:
			player.position.x = (TILE_SIZE / 2)
		Vector2.UP:
			player.position.y = SCREEN_SIZE.y - (TILE_SIZE / 2)
		Vector2.DOWN:
			player.position.y = (TILE_SIZE / 2)
