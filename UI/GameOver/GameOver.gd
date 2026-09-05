extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()

func _on_retry_button_pressed() -> void:
	retry()

func _on_quit_button_pressed() -> void:
	quit()

func retry():
	get_tree().paused = false
	GameManager.change_scene_to_main_game()

func quit():
	get_tree().paused = false
	GameManager.change_scene_to_main_menu()
