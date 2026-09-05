extends Node2D

@onready var hud = $HUD
@onready var player: PlayerController = $SubViewport/Level/Characters/Player
@onready var screen: TextureRect = $Screen
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var game_over: CanvasLayer = $GameOver

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	pause_menu.hide()
	game_over.hide()
	await get_tree().process_frame
	#var player = $SubViewport.get_node_or_null("Level/Characters/Player")
	if player:
		player.health_changed.connect(hud.update_health)
		player.ammo_changed.connect(hud.update_ammo)
		player.keys_changed.connect(hud.update_keys)
		player.player_died.connect(_on_player_died)
		
		# Initialize HUD with starting values
		hud.update_health(player.health)
		hud.update_ammo(player.ammo)
		hud.update_keys(player.keys)
		
	else:
		push_warning("Player not found when trying to connect HUD signals")
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		pause_game()
		
func pause_game():
	get_tree().paused = true
	$PauseMenu.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_player_died():
	game_over.show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
