extends Pickup

func _ready() -> void:
	pickup_type ="health"
	amount = 20

func _can_pickup(player: PlayerController) -> bool:
	var can_pickup = player.health < player.max_health
	return can_pickup

func _do_pickup(player: PlayerController) -> bool:
	if player.health >= player.max_health:
		return false
		
	player.add_health(amount)
	SoundLibrary.play_coke_pickup_sfx()
	return true
