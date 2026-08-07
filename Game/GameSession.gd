extends Node2D

@onready var hud = $HUD
@onready var player = $SubViewport/Level/Player
@onready var screen: TextureRect = $Screen

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	await get_tree().process_frame
	var player = $SubViewport.get_node_or_null("Level/Characters/Player")
	if player:
		player.connect("health_changed", hud.update_health)
		player.connect("ammo_changed", hud.update_ammo)
		player.connect("keys_changed", hud.update_keys)
		
		# Initialize HUD with starting values
		hud.update_health(player.health)
		hud.update_ammo(player.ammo)
		hud.update_keys(player.keys)
		
	else:
		push_warning("Player not found when trying to connect HUD signals")
	
