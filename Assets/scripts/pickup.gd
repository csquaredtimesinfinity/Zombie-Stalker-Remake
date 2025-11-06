extends Area2D

@export var pickup_type: String = "ammo"
@export var amount: int = 15

func _ready() -> void:
	add_to_group("pickups")

func apply_pickup(player: PlayerController) -> void:
		match pickup_type:
			"health":
				player.add_health(amount)
			"ammo":
				player.add_ammo(amount)
			"key":
				player.add_key()
