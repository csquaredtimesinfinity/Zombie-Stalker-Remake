extends Node

@onready var transition_layer: CanvasLayer = preload(
	"res://Assets/scenes/ui/transition_layer.tscn").instantiate()
@onready var main_game_scene: PackedScene = preload(
	"res://Assets/scenes/game.tscn")

func _ready():
	var test_scene = preload(
	"res://Assets/scenes/pickups/health.tscn").instantiate()
	#add_child(test_scene)
	#add_child(transition_layer)
	#get_tree().get_root().add_child(test_scene)
	transition_layer.layer = 100  # ensure it's always on top

func change_scene(scene: PackedScene):
	#await transition_layer.fade_out() # fade to black
	get_tree().change_scene_to_packed(scene)
	#await get_tree().create_timer(0.2).timeout
	#await transition_layer.fade_in()  # fade back in
