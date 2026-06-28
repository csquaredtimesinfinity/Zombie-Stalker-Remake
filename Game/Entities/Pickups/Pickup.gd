extends Area2D

class_name Pickup

@export var pickup_id: String
@export var pickup_type: String = "ammo"
@export var amount: int = 15

func _ready() -> void:
	add_to_group("pickups")
	
	print("Pickup.gd ready")
	
	

func _can_pickup(player: PlayerController) -> bool:
	return true

func _do_pickup(player: PlayerController) -> bool:
	return true

func apply_pickup(player: PlayerController) -> bool:
	if _can_pickup(player):
		_do_pickup(player)
		
		WorldState.mark_pickup_collected(pickup_id)
		return true
		
	return false

#func apply_pickup(player: PlayerController) -> bool:
	#print("Applying pickup:", pickup_id, " type=", pickup_type)
	#var should_pickup = false
	#
	#match pickup_type:
		#"health":
			#should_pickup = player.health < player.max_health
			#if should_pickup:
				#player.add_health(amount)
				#SoundLibrary.play_coke_pickup_sound()
			#
		#"ammo":
			#should_pickup = player.ammo < player.max_ammo
			#if should_pickup:
				#player.add_ammo(amount)
				#SoundLibrary.play_ammo_pickup_sound()
			#
		#"key":
			#player.add_key()
			#should_pickup = true
			#SoundLibrary.play_key_pickup_sound()
			#
	#if should_pickup:
		#GameManager.mark_pickup_collected(pickup_id)
		#
	#return should_pickup
