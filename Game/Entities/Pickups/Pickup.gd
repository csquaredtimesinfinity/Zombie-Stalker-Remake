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
