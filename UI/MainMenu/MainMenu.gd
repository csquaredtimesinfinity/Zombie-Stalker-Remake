extends Control

# Menu Buttons
@onready var playgame_button :Button = $CanvasLayer/VBoxContainer/PlayGameButton
@onready var campaign_editor_button :Button = $CanvasLayer/VBoxContainer/CampaignEditorButton
@onready var settings_button :Button = $CanvasLayer/VBoxContainer/SettingsButton
@onready var exit_button :Button = $CanvasLayer/VBoxContainer/ExitButton



func _ready() -> void:
	playgame_button.pressed.connect(_on_menu_button_pressed.bind("playgame"))
	campaign_editor_button.pressed.connect(_on_menu_button_pressed.bind("campaigneditor"))
	settings_button.pressed.connect(_on_menu_button_pressed.bind("settings"))
	exit_button.pressed.connect(_on_menu_button_pressed.bind("exit"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()

func _on_menu_button_pressed(button: String) -> void:
	match button:
		"playgame":
			GameManager.clear_collected_pickups()
			GameManager.clear_doors_unlocked()
			GameManager.change_scene_to_main_game()
		"campaigneditor":
			GameManager.change_scene_to_campaign_editor_menu()
		"settings":
			GameManager.change_scene_to_settings()
		"exit":
			print("exit")
			get_tree().quit()
