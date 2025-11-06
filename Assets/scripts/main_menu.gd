extends Control

# Menu Buttons
@onready var playgame_button :Button = $CanvasLayer/VBoxContainer/PlayGameButton
@onready var level_edit_button :Button = $CanvasLayer/VBoxContainer/LevelEditButton
@onready var settings_button :Button = $CanvasLayer/VBoxContainer/SettingsButton
@onready var exit_button :Button = $CanvasLayer/VBoxContainer/ExitButton

# Packed Scenes
@onready var main_game_scene = preload("res://Assets/scenes/level.tscn")
@onready var level_editor = preload("res://Assets/scenes/level_editor.tscn")
@onready var settings_scene = preload("res://Assets/scenes/ui/settings.tscn")

func _ready() -> void:
	playgame_button.pressed.connect(_on_menu_button_pressed.bind("playgame"))
	level_edit_button.pressed.connect(_on_menu_button_pressed.bind("leveledit"))
	settings_button.pressed.connect(_on_menu_button_pressed.bind("settings"))
	exit_button.pressed.connect(_on_menu_button_pressed.bind("exit"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()

func _on_menu_button_pressed(button: String) -> void:
	match button:
		"playgame":
			GameManager.change_scene_to_main_game()
		"leveledit":
			GameManager.change_scene_to_level_editor()
		"settings":
			GameManager.change_scene_to_settings()
		"exit":
			print("exit")
			get_tree().quit()
