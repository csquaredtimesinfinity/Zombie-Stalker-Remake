extends Control

@onready var playgame_button :Button = $CanvasLayer/VBoxContainer/PlayGameButton
@onready var level_edit_button :Button = $CanvasLayer/VBoxContainer/LevelEditButton
@onready var settings_button :Button = $CanvasLayer/VBoxContainer/SettingsButton
@onready var exit_button :Button = $CanvasLayer/VBoxContainer/ExitButton

func _ready() -> void:
	playgame_button.pressed.connect(_on_menu_button_pressed.bind("playgame"))
	level_edit_button.pressed.connect(_on_menu_button_pressed.bind("leveledit"))
	settings_button.pressed.connect(_on_menu_button_pressed.bind("settings"))
	exit_button.pressed.connect(_on_menu_button_pressed.bind("exit"))

func _on_menu_button_pressed(button: String) -> void:
	match button:
		"playgame":
			get_tree().change_scene_to_file("res://Assets/scenes/level.tscn")
		"leveledit":
			get_tree().change_scene_to_file("res://Assets/scenes/level_editor.tscn")
		"settings":
			pass
		"Exit":
			print("exit")
			get_tree().quit()
