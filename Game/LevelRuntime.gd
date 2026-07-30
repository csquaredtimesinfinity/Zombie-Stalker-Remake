extends Node2D

@onready var tilemap :TileMapLayer = $TileMapLayer
@onready var entities :Node2D = $Entities
@onready var game_scene_root :Node2D = $"."
@onready var hud :CanvasLayer = %HUD
@onready var effects_layer: Node2D = $EffectsLayer
@onready var characters: Node2D = $Characters

const TILE_SIZE = 16
const SCREEN_TILES = Vector2i(20, 10)
const SCREEN_SIZE = SCREEN_TILES * TILE_SIZE

var current_screen: Vector2 = Vector2.ZERO
var level_data
var player

func _ready() -> void:
	WorldState.reset_world()
	EffectsManager.effects_layer = effects_layer
	
	level_data = LevelSystem.load_level("res://Assets/levels/Level1.json")
	var player_start = level_data["player_start"]
	LevelSystem.apply_screen(
		player_start["screen"], tilemap, null, entities, game_scene_root, characters)
	
	# Spawn player controlled character
	var player_position = LevelUtils.cell_to_world(player_start["cell"])
	player = preload("res://Game/Entities/Player/Player.tscn").instantiate()
	player.position = Vector2(player_position.x + TILE_SIZE/2, player_position.y + TILE_SIZE/2)
	characters.add_child(player)
	
	# Initialize starting screen
	current_screen = LevelUtils.str_to_vec2i(player_start["screen"])

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
	
	# Remove Enemies from previous screen
	_remove_all_entities()
	
	LevelSystem.apply_screen(
		screen_key, tilemap, null, entities, game_scene_root, characters)

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

func _remove_all_entities() -> void:
	# Remove each group of entity
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("projectiles", "queue_free")
	get_tree().call_group("prop", "queue_free")
	
	# Remove any other entities remaining
	var entities_to_remove = entities.get_children()
	for entity in entities_to_remove:
		entity.queue_free()
	
	# remove all effects from effects layer
	var effects_to_remove = effects_layer.get_children()
	for effect in effects_to_remove:
		effect.queue_free()
