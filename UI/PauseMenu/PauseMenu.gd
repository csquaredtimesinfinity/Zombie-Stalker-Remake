extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()

func resume():
	get_tree().paused = false
	hide()

func _on_resume_button_pressed() -> void:
	resume()

func _on_quit_button_pressed() -> void:
	resume()
	GameManager.change_scene_to_main_menu()
