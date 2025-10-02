extends Area2D

@export var pickup_type: String = "ammo"
@export var amount: int = 15

func _ready() -> void:
	add_to_group("pickups")
