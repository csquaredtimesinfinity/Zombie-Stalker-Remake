extends Node2D


func _init() -> void:
	pass
	
func _ready() -> void:
	pass # LevelLoader.load_level("res://testlevel.json", $TileMapLayer, self)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()
	#f event.is_action_pressed("move_down"):
		#evelLoader.load_level("res://testlevel.json"
