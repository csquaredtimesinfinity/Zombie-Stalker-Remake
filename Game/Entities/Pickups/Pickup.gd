extends Area2D

class_name Pickup

var id: String
var pickup_type: String = "ammo"
var amount: int = 15

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
		
		WorldState.mark_pickup_collected(id)
		return true
		
	return false
