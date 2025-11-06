extends Control

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		GameManager.change_scene_to_main_menu()
