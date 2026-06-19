extends Pickup

func _ready() -> void:
	pickup_type = "ammo"
	amount = 15
	
	

func _can_pickup(player: PlayerController) -> bool:
	var can_pickup = player.ammo < player.max_ammo
	return can_pickup
	
func _do_pickup(player: PlayerController) -> bool:
	if player.ammo >= player.max_ammo:
		return false
		
	player.add_ammo(amount)
	SoundLibrary.play_ammo_pickup_sound()
	
	return true
