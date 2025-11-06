extends Node

@onready var transition_layer: CanvasLayer = preload(
	"res://Assets/scenes/ui/transition_layer.tscn").instantiate()
@onready var main_game_scene: PackedScene = preload(
	"res://Assets/scenes/gameplay.tscn")
@onready var main_menu_scene: PackedScene = preload("res://Assets/scenes/ui/main_menu.tscn")
@onready var level_editor_scene: PackedScene = preload("res://Assets/scenes/level_editor.tscn")
@onready var settings_scene: PackedScene = preload("res://Assets/scenes/ui/settings.tscn")

func _ready():
	var test_scene = preload(
	"res://Assets/scenes/pickups/health.tscn").instantiate()
	#add_child(test_scene)
	#add_child(transition_layer)
	#get_tree().get_root().add_child(test_scene)
	transition_layer.layer = 100  # ensure it's always on top

func change_scene_to_main_menu() -> void:
	change_scene(main_menu_scene)

func change_scene_to_main_game() -> void:
	change_scene(main_game_scene)
	
func change_scene_to_level_editor() -> void:
	change_scene(level_editor_scene)

func change_scene_to_settings() -> void:
	change_scene(settings_scene)

func change_scene(scene: PackedScene):
	print("Changing scene to: ", scene.resource_path)
	if scene and scene is PackedScene:
		get_tree().change_scene_to_packed(scene)
	else:
		push_error("Invalid PackedScene passed to change_scene")
	# TODO: add transitions
