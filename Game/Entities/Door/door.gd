extends Area2D

var id: String

func _on_area_entered(area: Area2D) -> void:
	var player : PlayerController = area.get_owner()
	if player.has_keys() && not WorldState.is_door_unlocked(id):
		WorldState.unlock_door(id)
		player.remove_key()
		queue_free()
