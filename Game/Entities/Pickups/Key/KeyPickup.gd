extends Pickup

func _ready() -> void:
	pickup_type = "key"
	amount = 1

func _can_pickup(player: PlayerController) -> bool:
	return true

func _do_pickup(player: PlayerController) -> bool:
	player.add_key()
	SoundLibrary.play_key_pickup_sfx()
	return true
