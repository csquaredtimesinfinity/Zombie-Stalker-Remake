extends Area2D

@export var pickup_id: String
@export var pickup_type: String = "ammo"
@export var amount: int = 15

func _ready() -> void:
	add_to_group("pickups")
	
	if GameManager.is_pickup_collected(pickup_id):
		queue_free()

func apply_pickup(player: PlayerController) -> bool:
	var should_pickup = false
	
	match pickup_type:
		"health":
			should_pickup = player.health < player.max_health
			if should_pickup:
				player.add_health(amount)
				SoundFX.play_coke_pickup_sound()
			
		"ammo":
			should_pickup = player.ammo < player.max_ammo
			if should_pickup:
				player.add_ammo(amount)
				SoundFX.play_ammo_pickup_sound()
			
		"key":
			player.add_key()
			should_pickup = true
			SoundFX.play_key_pickup_sound()
			
	if should_pickup:
		GameManager.mark_pickup_collected(pickup_id)
		
	return should_pickup
