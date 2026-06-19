extends Node

# TODO:
# GameManager currently handles:
# - Scene navigation
# - World state (doors, pickups)
# - Application settings (fullscreen)
#
# Consider splitting into dedicated autoloads if responsibilities grow:
# - SceneRouter
# - GameState
# - SaveManager
# - AudioManager

@onready var transition_layer: CanvasLayer = preload(
	"res://Assets/scenes/ui/transition_layer.tscn").instantiate()
	
# PRELOAD SCENES
const MAIN_GAME_SCENE: PackedScene = preload("res://Game/GameSession.tscn")
const MAIN_MENU_SCENE: PackedScene = preload("res://UI/MainMenu/MainMenu.tscn")
const LEVEL_EDITOR_SCENE: PackedScene = preload("res://Editor/LevelEditor.tscn")
const SETTINGS_SCENE: PackedScene = preload("res://UI/Settings/Settings.tscn")

const CAMPAIGN_EDITOR_ROOT_SCENE: PackedScene = preload("res://Editor/CampaignEditor/CampaignEditorRoot.tscn")


# Track pickups and doors unlocked
var collected_pickups: Dictionary = {}
var doors_unlocked: Dictionary = {}

func _ready() -> void:
	transition_layer.layer = 100  # ensure it's always on top
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var current_mode = DisplayServer.window_get_mode()
		if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func change_scene_to_main_menu() -> void:
	change_scene(MAIN_MENU_SCENE)

func change_scene_to_main_game() -> void:
	change_scene(MAIN_GAME_SCENE)
	
func change_scene_to_level_editor() -> void:
	change_scene(LEVEL_EDITOR_SCENE)

func change_scene_to_settings() -> void:
	change_scene(SETTINGS_SCENE)

func change_scene_to_campaign_editor() -> void:
	change_scene(CAMPAIGN_EDITOR_ROOT_SCENE)

func change_scene(scene: PackedScene) -> void:
	print("Changing scene to: ", scene.resource_path)
	if scene and scene is PackedScene:
		get_tree().change_scene_to_packed(scene)
	else:
		push_error("Invalid PackedScene passed to change_scene")
	# TODO: add transitions

func is_pickup_collected(id: String) -> bool:
	return collected_pickups.has(id)
	
func mark_pickup_collected(id: String) -> void:
	print("pickup collected: %s" % id)
	collected_pickups[id] = true
	
func clear_collected_pickups() -> void:
	collected_pickups.clear()
	
func is_door_unlocked(id: String) -> bool:
	return doors_unlocked.has(id)

func unlock_door(id: String) -> void:
	doors_unlocked[id] = true

func clear_doors_unlocked() -> void:
	doors_unlocked.clear()
